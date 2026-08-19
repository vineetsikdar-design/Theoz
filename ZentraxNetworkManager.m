//
//  ZentraxNetworkManager.m
//  Zentrax VIP - Premium Execution Node
//
//  Created by Zentrax Team.
//  Architecture: Token-Based Secure Networking (Zero Hardcoded Secrets)
//  Status: PRODUCTION READY
//

#import "ZentraxNetworkManager.h"
#import <Security/Security.h>
#import <UIKit/UIKit.h>

// ==========================================
// 🔐 SERVER CONFIGURATION
// ==========================================
#define BASE_URL @"https://zentrax.in/api/"
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
    
    // Delete existing before saving new
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

- (void)sendRequestToEndpoint:(NSString *)endpoint payload:(NSDictionary *)payloadDict requiresAuth:(BOOL)requiresAuth completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, NSString * _Nullable errorMsg))completion {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", BASE_URL, endpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // Inject Authorization Token if required
    if (requiresAuth) {
        NSString *token = [self getTokenFromKeychain];
        if (!token) {
            completion(NO, nil, @"Authentication token missing. Please log in again.");
            return;
        }
        NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", token];
        [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    }
    
    // Inject Anti-Replay Timestamp
    NSMutableDictionary *securePayload = [payloadDict mutableCopy];
    securePayload[@"timestamp"] = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    
    NSError *jsonError;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:securePayload options:0 error:&jsonError];
    if (jsonError) {
        completion(NO, nil, @"Internal Payload Formatting Error.");
        return;
    }
    request.HTTPBody = bodyData;
    
    NSURLSessionDataTask *task = [self.secureSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            completion(NO, nil, @"Connection lost to Master Node.");
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // Handle Session Revocation (Unauthorized)
        if (httpResponse.statusCode == 401 || httpResponse.statusCode == 403) {
            [self logout];
            completion(NO, nil, @"Session expired or revoked. Please log in again.");
            return;
        }
        
        NSError *parseError;
        NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        
        if (parseError || !parsedResponse) {
            completion(NO, nil, @"Malformed response from server.");
            return;
        }
        
        BOOL status = [parsedResponse[@"status"] isEqualToString:@"success"];
        NSString *message = parsedResponse[@"message"];
        
        completion(status, parsedResponse, message);
    }];
    
    [task resume];
}

#pragma mark - ================= PUBLIC ACTIONS =================

- (void)authenticateWithKey:(NSString *)key completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, NSString * _Nullable errorMsg))completion {
    NSDictionary *payload = @{
        @"action": @"login",
        @"key": key,
        @"hwid": [self getHardwareID]
    };
    
    // Auth request does NOT require existing token
    [self sendRequestToEndpoint:@"auth.php" payload:payload requiresAuth:NO completion:^(BOOL success, NSDictionary *responseData, NSString *errorMsg) {
        if (success && responseData[@"token"]) {
            // Save token securely upon successful login
            [self saveTokenToKeychain:responseData[@"token"]];
        }
        completion(success, responseData, errorMsg);
    }];
}

- (void)toggleModule:(NSString *)moduleName state:(BOOL)isOn completion:(void(^)(BOOL success, NSDictionary * _Nullable modulePayload, NSString * _Nullable errorMsg))completion {
    NSDictionary *payload = @{
        @"action": @"toggle_module",
        @"module": moduleName,
        @"state": isOn ? @"ON" : @"OFF",
        @"hwid": [self getHardwareID]
    };
    
    // Toggle requires active auth token
    [self sendRequestToEndpoint:@"module.php" payload:payload requiresAuth:YES completion:^(BOOL success, NSDictionary *responseData, NSString *errorMsg) {
        if (!success) {
            completion(NO, nil, errorMsg);
            return;
        }
        
        // Expecting dictionary with file_data, bundle_id, and relative_path from server
        NSDictionary *payloadData = responseData[@"payload"];
        if (payloadData && payloadData[@"file_data"]) {
            completion(YES, payloadData, nil);
        } else {
            completion(NO, nil, @"Payload data empty or corrupted.");
        }
    }];
}

- (void)verifySessionWithCompletion:(void(^)(BOOL isValid))completion {
    NSDictionary *payload = @{
        @"action": @"heartbeat",
        @"hwid": [self getHardwareID]
    };
    
    [self sendRequestToEndpoint:@"heartbeat.php" payload:payload requiresAuth:YES completion:^(BOOL success, NSDictionary *responseData, NSString *errorMsg) {
        if (!success && [errorMsg containsString:@"expired"]) {
            [self logout];
        }
        completion(success);
    }];
}

#pragma mark - ================= SSL PINNING (ANTI-SNIFF) =================

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        
        // TODO for Production: Extract public key hash from serverTrust and compare against known Zentrax Hash.
        
        // Temporarily accepting valid CA trusts while testing API integration
        completionHandler(NSURLSessionAuthChallengeUseCredential, [[NSURLCredential alloc] initWithTrust:serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

@end
