//
//  ZentraxNetworkManager.m
//  Zentrax VIP - Premium Execution Node
//
//  Created by Zentrax Team.
//  Status: PRODUCTION READY
//

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
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        // Delegate queue nil isolates transport operations to a background thread
        self.secureSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return self;
}

#pragma mark - ================= DEVICE FINGERPRINTING =================

- (NSString *)getHardwareID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *hwid = [defaults stringForKey:@"Zentrax_HWID"];
    if (!hwid || hwid.length == 0) {
        hwid = [[UIDevice currentDevice] identifierForVendor].UUIDString;
        if (!hwid) {
            hwid = [[NSUUID UUID] UUIDString];
        }
        [defaults setObject:hwid forKey:@"Zentrax_HWID"];
        [defaults synchronize];
    }
    return hwid;
}

#pragma mark - ================= HARDWARE KEYCHAIN (SECURE STORAGE) =================

- (void)saveTokenToKeychain:(NSString *)token {
    if (!token || token.length == 0) return;
    
    NSData *tokenData = [token dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: KEYCHAIN_SERVICE,
        (__bridge id)kSecAttrAccount: KEYCHAIN_ACCOUNT
    };
    
    // Purge existing token before writing to prevent OSStatus duplicate errors
    SecItemDelete((__bridge CFDictionaryRef)query);
    
    NSMutableDictionary *addQuery = [query mutableCopy];
    addQuery[(__bridge id)kSecValueData] = tokenData;
    addQuery[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    
    SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
}

- (NSString * _Nullable)getTokenFromKeychain {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: KEYCHAIN_SERVICE,
        (__bridge id)kSecAttrAccount: KEYCHAIN_ACCOUNT,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    
    CFTypeRef dataTypeRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataTypeRef);
    
    if (status == errSecSuccess && dataTypeRef != NULL) {
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

/// Core transport method. Maps JSON structures and guarantees main-thread completion.
- (void)sendRequestToEndpoint:(NSString *)endpoint 
                      payload:(NSDictionary *)payloadDict 
                 requiresAuth:(BOOL)requiresAuth 
                   completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg))completion {
    
    if (!completion) return;
    
    void (^mainThreadCompletion)(BOOL, NSDictionary *, ZXNetworkErrorType, NSString *) = ^(BOOL s, NSDictionary *d, ZXNetworkErrorType t, NSString *m) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(s, d, t, m);
        });
    };
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", BASE_URL, endpoint]];
    if (!url) {
        mainThreadCompletion(NO, nil, ZXNetworkErrorServer, @"Internal Error: Malformed Endpoint URL.");
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    if (requiresAuth) {
        NSString *token = [self getTokenFromKeychain];
        if (!token) {
            mainThreadCompletion(NO, nil, ZXNetworkErrorInvalidSession, @"Authentication token missing. Please log in again.");
            return;
        }
        NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", token];
        [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    }
    
    NSMutableDictionary *securePayload = payloadDict ? [payloadDict mutableCopy] : [NSMutableDictionary dictionary];
    securePayload[@"timestamp"] = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    
    NSError *jsonError = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:securePayload options:0 error:&jsonError];
    if (jsonError || !bodyData) {
        mainThreadCompletion(NO, nil, ZXNetworkErrorServer, @"Internal Error: Payload Serialization Failed.");
        return;
    }
    
    request.HTTPBody = bodyData;
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.secureSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (error || !data) {
            mainThreadCompletion(NO, nil, ZXNetworkErrorConnection, @"Secure connection could not be established.");
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            mainThreadCompletion(NO, nil, ZXNetworkErrorServer, @"Invalid server response format.");
            return;
        }
        
        NSError *parseError = nil;
        id parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        
        if (parseError || ![parsedObject isKindOfClass:[NSDictionary class]]) {
            mainThreadCompletion(NO, nil, ZXNetworkErrorServer, @"Server responded with malformed data.");
            return;
        }
        
        NSDictionary *parsedResponse = (NSDictionary *)parsedObject;
        
        BOOL status = NO;
        if ([parsedResponse[@"status"] isKindOfClass:[NSString class]]) {
            status = [parsedResponse[@"status"] isEqualToString:@"success"];
        }
        
        NSString *message = @"An unknown error occurred.";
        if ([parsedResponse[@"message"] isKindOfClass:[NSString class]]) {
            message = parsedResponse[@"message"];
        }
        
        ZXNetworkErrorType errType = ZXNetworkErrorNone;
        
        if (!status) {
            NSString *errCode = @"UNKNOWN";
            if ([parsedResponse[@"error_code"] isKindOfClass:[NSString class]]) {
                errCode = parsedResponse[@"error_code"];
            }
            
            if ([errCode isEqualToString:@"EXPIRED_KEY"]) errType = ZXNetworkErrorExpiredKey;
            else if ([errCode isEqualToString:@"REVOKED_KEY"]) errType = ZXNetworkErrorRevokedKey;
            else if ([errCode isEqualToString:@"INVALID_KEY"]) errType = ZXNetworkErrorInvalidKey;
            else if ([errCode isEqualToString:@"DEVICE_LIMIT"]) errType = ZXNetworkErrorDeviceLimit;
            else if ([errCode isEqualToString:@"INVALID_SESSION"]) errType = ZXNetworkErrorInvalidSession;
            else errType = ZXNetworkErrorServer;
            
            // Centralized strict session invalidation
            if (requiresAuth && strongSelf && (errType == ZXNetworkErrorInvalidSession || errType == ZXNetworkErrorRevokedKey || errType == ZXNetworkErrorExpiredKey || errType == ZXNetworkErrorInvalidKey)) {
                [strongSelf logout];
            }
        }
        
        mainThreadCompletion(status, parsedResponse, errType, message);
    }];
    
    [task resume];
}

#pragma mark - ================= PUBLIC ACTIONS =================

- (void)authenticateWithKey:(NSString *)key completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg))completion {
    if (!key || key.length == 0) {
        if (completion) completion(NO, nil, ZXNetworkErrorInvalidKey, @"License key cannot be empty.");
        return;
    }
    
    NSDictionary *payload = @{
        @"action": @"login",
        @"key": key,
        @"hwid": [self getHardwareID]
    };
    
    [self sendRequestToEndpoint:@"auth.php" payload:payload requiresAuth:NO completion:^(BOOL success, NSDictionary *responseData, ZXNetworkErrorType errorType, NSString *errorMsg) {
        if (success && [responseData[@"token"] isKindOfClass:[NSString class]]) {
            [self saveTokenToKeychain:responseData[@"token"]];
        } else if (success) {
            success = NO;
            errorType = ZXNetworkErrorServer;
            errorMsg = @"Authentication succeeded, but invalid token structure was returned.";
        }
        if (completion) completion(success, responseData, errorType, errorMsg);
    }];
}

- (void)toggleModule:(NSString *)moduleName state:(BOOL)isOn completion:(void(^)(BOOL success, NSDictionary * _Nullable modulePayload, NSString * _Nullable errorMsg))completion {
    if (!moduleName || moduleName.length == 0) {
        if (completion) completion(NO, nil, @"Invalid module identifier.");
        return;
    }
    
    NSDictionary *payload = @{
        @"action": @"get_payload",
        @"module": moduleName,
        @"state": isOn ? @"ON" : @"OFF",
        @"hwid": [self getHardwareID]
    };
    
    [self sendRequestToEndpoint:@"module.php" payload:payload requiresAuth:YES completion:^(BOOL success, NSDictionary *responseData, ZXNetworkErrorType errorType, NSString *errorMsg) {
        if (!success) {
            if (completion) completion(NO, nil, errorMsg);
            return;
        }
        
        id payloadData = responseData[@"payload"];
        id operationId = responseData[@"operation_id"];
        
        // Assemble payload and operation_id matching Tweak.m expectations
        if ([payloadData isKindOfClass:[NSDictionary class]] && [operationId isKindOfClass:[NSString class]]) {
            NSDictionary *payloadDict = (NSDictionary *)payloadData;
            
            if ([payloadDict[@"file_data"] isKindOfClass:[NSString class]] &&
                [payloadDict[@"bundle_id"] isKindOfClass:[NSString class]] &&
                [payloadDict[@"relative_path"] isKindOfClass:[NSString class]] &&
                [payloadDict[@"target_filename"] isKindOfClass:[NSString class]]) {
                
                NSMutableDictionary *combined = [payloadDict mutableCopy];
                combined[@"operation_id"] = operationId;
                if (completion) completion(YES, combined, nil);
                return;
            }
        }
        
        if (completion) completion(NO, nil, @"Server returned a malformed payload or missing operation identifier.");
    }];
}

- (void)syncModuleState:(NSString *)moduleName state:(BOOL)isOn operationId:(NSString *)operationId completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion {
    if (!operationId || operationId.length == 0 || !moduleName || moduleName.length == 0) {
        if (completion) completion(NO, @"Missing required identifiers for synchronization.");
        return;
    }
    
    NSDictionary *payload = @{
        @"action": @"sync_state",
        @"module": moduleName,
        @"state": isOn ? @"ON" : @"OFF",
        @"operation_id": operationId,
        @"hwid": [self getHardwareID]
    };
    
    [self sendRequestToEndpoint:@"module.php" payload:payload requiresAuth:YES completion:^(BOOL success, NSDictionary *responseData, ZXNetworkErrorType errorType, NSString *errorMsg) {
        if (completion) completion(success, errorMsg);
    }];
}

- (void)verifySessionWithCompletion:(void(^)(BOOL isValid, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg))completion {
    NSDictionary *payload = @{
        @"action": @"heartbeat",
        @"hwid": [self getHardwareID]
    };
    
    [self sendRequestToEndpoint:@"heartbeat.php" payload:payload requiresAuth:YES completion:^(BOOL success, NSDictionary *responseData, ZXNetworkErrorType errorType, NSString *errorMsg) {
        if (completion) completion(success, responseData, errorType, errorMsg);
    }];
}

#pragma mark - ================= SSL TRANSPORT SECURITY =================

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    // Fallback standard TLS validation. 
    // Honest Security Declaration: We are using OS-provided trust evaluation because a hardcoded 
    // certificate public key hash is not provided in the environment configuration.
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

@end
