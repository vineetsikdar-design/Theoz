#import "ZentraxNetworkManager.h"
#import <Security/Security.h>
#import <UIKit/UIKit.h>

#define BASE_URL @"https://zentraxmod.in/api/"
#define KEYCHAIN_SERVICE @"in.zentrax.proxy"
#define KEYCHAIN_ACCOUNT @"session_token"

@interface ZentraxNetworkManager () <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *secureSession;
@end

@implementation ZentraxNetworkManager

+ (instancetype)sharedManager {
    static ZentraxNetworkManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest = 15.0; 
        self.secureSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return self;
}

#pragma mark - ================= DEVICE FINGERPRINTING =================

- (NSString *)getHardwareID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *hwid = [defaults stringForKey:@"Zentrax_HWID"];
    if (!hwid) {
        hwid = [[UIDevice currentDevice] identifierForVendor].UUIDString;
        [defaults setObject:hwid forKey:@"Zentrax_HWID"];
        [defaults synchronize];
    }
    return hwid;
}

#pragma mark - ================= HARDWARE KEYCHAIN (SECURE STORAGE) =================

- (void)saveTokenToKeychain:(NSString *)token {
    NSData *tokenData = [token dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: KEYCHAIN_SERVICE,
        (__bridge id)kSecAttrAccount: KEYCHAIN_ACCOUNT
    };
    
    SecItemDelete((__bridge CFDictionaryRef)query);
    
    NSMutableDictionary *addQuery = [query mutableCopy];
    addQuery[(__bridge id)kSecValueData] = tokenData;
    addQuery[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    
    SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
}

- (NSString *)getTokenFromKeychain {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: KEYCHAIN_SERVICE,
        (__bridge id)kSecAttrAccount: KEYCHAIN_ACCOUNT,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    
    CFTypeRef dataTypeRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataTypeRef);
    
    if (status == errSecSuccess) {
        NSData *resultData = (__bridge_transfer NSData *)dataTypeRef;
        return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (void)logout {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: KEYCHAIN_SERVICE,
        (__bridge id)kSecAttrAccount: KEYCHAIN_ACCOUNT
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
}

- (BOOL)hasActiveSession {
    return ([self getTokenFromKeychain] != nil);
}

#pragma mark - ================= SECURE API EXECUTOR =================

- (void)sendRequestToEndpoint:(NSString *)endpoint payload:(NSDictionary *)payloadDict requiresAuth:(BOOL)requiresAuth completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg))completion {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", BASE_URL, endpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    if (requiresAuth) {
        NSString *token = [self getTokenFromKeychain];
        if (!token) {
            completion(NO, nil, ZXNetworkErrorInvalidKey, @"Authentication token missing. Please log in again.");
            return;
        }
        NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", token];
        [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    }
    
    NSMutableDictionary *securePayload = [payloadDict mutableCopy];
    securePayload[@"timestamp"] = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    
    NSError *jsonError;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:securePayload options:0 error:&jsonError];
    if (jsonError) {
        completion(NO, nil, ZXNetworkErrorServer, @"Internal Payload Formatting Error.");
        return;
    }
    request.HTTPBody = bodyData;
    
    NSURLSessionDataTask *task = [self.secureSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            completion(NO, nil, ZXNetworkErrorConnection, @"Connection lost to Master Node.");
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode == 401 || httpResponse.statusCode == 403) {
            [self logout];
            completion(NO, nil, ZXNetworkErrorExpiredKey, @"Session expired or revoked. Please log in again.");
            return;
        }
        
        NSError *parseError;
        NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        
        if (parseError || !parsedResponse) {
            completion(NO, nil, ZXNetworkErrorServer, @"Malformed response from server.");
            return;
        }
        
        BOOL status = [parsedResponse[@"status"] isEqualToString:@"success"];
        NSString *message = parsedResponse[@"message"];
        ZXNetworkErrorType errType = ZXNetworkErrorNone;
        
        if (!status) {
            NSString *errCode = parsedResponse[@"error_code"];
            if ([errCode isKindOfClass:[NSString class]]) {
                if ([errCode isEqualToString:@"EXPIRED_KEY"]) {
                    errType = ZXNetworkErrorExpiredKey;
                } else if ([errCode isEqualToString:@"INVALID_KEY"]) {
                    errType = ZXNetworkErrorInvalidKey;
                } else {
                    errType = ZXNetworkErrorInvalidKey;
                }
            } else {
                errType = ZXNetworkErrorInvalidKey;
            }
        }
        
        completion(status, parsedResponse, errType, message);
    }];
    
    [task resume];
}

#pragma mark - ================= PUBLIC ACTIONS =================

- (void)authenticateWithKey:(NSString *)key completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg))completion {
    NSDictionary *payload = @{
        @"action": @"login",
        @"key": key,
        @"hwid": [self getHardwareID]
    };
    
    [self sendRequestToEndpoint:@"auth.php" payload:payload requiresAuth:NO completion:^(BOOL success, NSDictionary *responseData, ZXNetworkErrorType errorType, NSString *errorMsg) {
        if (success && responseData[@"token"]) {
            [self saveTokenToKeychain:responseData[@"token"]];
        }
        completion(success, responseData, errorType, errorMsg);
    }];
}

- (void)toggleModule:(NSString *)moduleName state:(BOOL)isOn completion:(void(^)(BOOL success, NSDictionary * _Nullable modulePayload, NSString * _Nullable errorMsg))completion {
    NSDictionary *payload = @{
        @"action": @"toggle_module",
        @"module": moduleName,
        @"state": isOn ? @"ON" : @"OFF",
        @"hwid": [self getHardwareID]
    };
    
    [self sendRequestToEndpoint:@"module.php" payload:payload requiresAuth:YES completion:^(BOOL success, NSDictionary *responseData, ZXNetworkErrorType errorType, NSString *errorMsg) {
        if (!success) {
            completion(NO, nil, errorMsg);
            return;
        }
        
        NSDictionary *payloadData = responseData[@"payload"];
        if (payloadData && payloadData[@"file_data"]) {
            completion(YES, payloadData, nil);
        } else {
            completion(NO, nil, @"Payload data empty or corrupted.");
        }
    }];
}

- (void)verifySessionWithCompletion:(void(^)(BOOL isValid, NSDictionary * _Nullable responseData))completion {
    NSDictionary *payload = @{
        @"action": @"heartbeat",
        @"hwid": [self getHardwareID]
    };
    
    [self sendRequestToEndpoint:@"heartbeat.php" payload:payload requiresAuth:YES completion:^(BOOL success, NSDictionary *responseData, ZXNetworkErrorType errorType, NSString *errorMsg) {
        if (!success) {
            [self logout];
        }
        completion(success, responseData);
    }];
}

#pragma mark - ================= SSL PINNING =================

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        completionHandler(NSURLSessionAuthChallengeUseCredential, [[NSURLCredential alloc] initWithTrust:serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

@end
