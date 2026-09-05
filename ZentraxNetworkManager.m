//
//  ZentraxNetworkManager.m
//  Zentrax VIP - Premium Execution Node
//
//  Production network/session/configuration layer.
//  This file intentionally stays at the application/network layer and does
//  not modify the project's low-level filesystem or sandbox components.
//

#import "ZentraxNetworkManager.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>
#include <sys/utsname.h>

#define BASE_URL                    @"https://zentraxmod.in/api/"
#define KEYCHAIN_SERVICE            @"in.zentrax.proxy"
#define KEYCHAIN_SESSION_ACCOUNT    @"session_token"
#define KEYCHAIN_LICENSE_ACCOUNT    @"license_key"
#define KEYCHAIN_HWID_ACCOUNT       @"device_hwid"
#define COMPATIBILITY_CACHE_KEY     @"Zentrax_Compatibility_Cache"
#define CONFIGURATION_CACHE_KEY     @"Zentrax_Configuration_Cache"
#define SERVER_OFFSET_KEY           @"Zentrax_Server_Time_Offset"
#define SERVER_OFFSET_VALID_KEY     @"Zentrax_Server_Time_Offset_Valid"
#define DEFAULT_TIMEOUT             15.0

@interface ZentraxNetworkManager () <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *secureSession;
@property (nonatomic, strong) NSMutableSet<NSURLSessionDataTask *> *activeTasks;
@property (nonatomic, strong) dispatch_queue_t stateQueue;
@property (nonatomic, assign) NSUInteger requestCount;
@property (nonatomic, copy, readwrite, nullable) NSString *lastErrorMessage;
@end

@implementation ZentraxNetworkManager

#pragma mark - Singleton / Initialization

+ (instancetype)sharedManager {
    static ZentraxNetworkManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _activeTasks = [NSMutableSet set];
        _stateQueue = dispatch_queue_create("in.zentrax.network.state", DISPATCH_QUEUE_SERIAL);

        NSURLSessionConfiguration *configuration =
            [NSURLSessionConfiguration ephemeralSessionConfiguration];
        configuration.timeoutIntervalForRequest = DEFAULT_TIMEOUT;
        configuration.timeoutIntervalForResource = DEFAULT_TIMEOUT + 10.0;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        configuration.URLCache = nil;
        configuration.HTTPShouldSetCookies = NO;
        configuration.HTTPShouldUsePipelining = NO;
        configuration.waitsForConnectivity = NO;

        _secureSession = [NSURLSession sessionWithConfiguration:configuration
                                                       delegate:self
                                                  delegateQueue:nil];
    }
    return self;
}

#pragma mark - Public State

- (BOOL)isRequestInFlight {
    __block BOOL result = NO;
    dispatch_sync(self.stateQueue, ^{
        result = (self.requestCount > 0);
    });
    return result;
}

- (void)beginRequest {
    dispatch_async(self.stateQueue, ^{
        self.requestCount += 1;
    });
}

- (void)endRequest {
    dispatch_async(self.stateQueue, ^{
        if (self.requestCount > 0) {
            self.requestCount -= 1;
        }
    });
}

#pragma mark - Keychain

- (NSDictionary *)keychainQueryForAccount:(NSString *)account {
    return @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: KEYCHAIN_SERVICE,
        (__bridge id)kSecAttrAccount: account
    };
}

- (BOOL)saveSecureString:(NSString *)value account:(NSString *)account {
    if (value.length == 0 || account.length == 0) {
        return NO;
    }

    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return NO;
    }

    NSDictionary *query = [self keychainQueryForAccount:account];
    SecItemDelete((__bridge CFDictionaryRef)query);

    NSMutableDictionary *item = [query mutableCopy];
    item[(__bridge id)kSecValueData] = data;
    item[(__bridge id)kSecAttrAccessible] =
        (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;

    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)item, NULL);
    return status == errSecSuccess;
}

- (NSString * _Nullable)secureStringForAccount:(NSString *)account {
    if (account.length == 0) {
        return nil;
    }

    NSMutableDictionary *query = [[self keychainQueryForAccount:account] mutableCopy];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess || result == NULL) {
        return nil;
    }

    NSData *data = (__bridge_transfer NSData *)result;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)deleteSecureAccount:(NSString *)account {
    if (account.length == 0) {
        return;
    }
    NSDictionary *query = [self keychainQueryForAccount:account];
    SecItemDelete((__bridge CFDictionaryRef)query);
}

- (void)saveTokenToKeychain:(NSString *)token {
    [self saveSecureString:token account:KEYCHAIN_SESSION_ACCOUNT];
}

- (NSString * _Nullable)getTokenFromKeychain {
    return [self secureStringForAccount:KEYCHAIN_SESSION_ACCOUNT];
}

#pragma mark - Device Identity

- (NSString *)getHardwareID {
    NSString *stored = [self secureStringForAccount:KEYCHAIN_HWID_ACCOUNT];
    if (stored.length > 0) {
        return stored;
    }

    NSString *vendorID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    NSString *generated = vendorID.length > 0 ? vendorID : [NSUUID UUID].UUIDString;

    if (generated.length == 0) {
        generated = @"unknown-device";
    }

    [self saveSecureString:generated account:KEYCHAIN_HWID_ACCOUNT];
    return generated;
}

- (NSString *)applicationVersion {
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (version.length == 0) {
        version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    }
    return version.length > 0 ? version : @"0.0.0";
}

- (NSString *)deviceArchitecture {
#if defined(__arm64e__)
    return @"arm64e";
#elif defined(__arm64__)
    return @"arm64";
#else
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithUTF8String:systemInfo.machine] ?: @"unknown";
#endif
}

- (NSString *)deviceModelIdentifier {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *machine = [NSString stringWithUTF8String:systemInfo.machine];
    return machine.length > 0 ? machine : @"unknown";
}

- (NSDictionary *)deviceInformation {
    UIDevice *device = UIDevice.currentDevice;
    NSString *systemVersion = device.systemVersion ?: @"unknown";
    NSString *model = device.model ?: @"iPhone";

    return @{
        @"model": model,
        @"model_identifier": [self deviceModelIdentifier],
        @"ios_version": systemVersion,
        @"architecture": [self deviceArchitecture],
        @"app_version": [self applicationVersion],
        @"device_class": UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone"
    };
}

#pragma mark - Server Time

- (NSTimeInterval)serverTimeOffset {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (![defaults boolForKey:SERVER_OFFSET_VALID_KEY]) {
        return 0.0;
    }
    return [defaults doubleForKey:SERVER_OFFSET_KEY];
}

- (NSDate * _Nullable)estimatedServerDate {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (![defaults boolForKey:SERVER_OFFSET_VALID_KEY]) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSinceNow:[self serverTimeOffset]];
}

- (void)resetServerTimeState {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:SERVER_OFFSET_KEY];
    [defaults removeObjectForKey:SERVER_OFFSET_VALID_KEY];
}

- (void)updateServerTimeFromResponse:(NSDictionary *)response {
    NSNumber *serverTime = nil;
    id raw = response[@"server_time"];
    if ([raw isKindOfClass:NSNumber.class]) {
        serverTime = raw;
    } else if ([raw isKindOfClass:NSString.class]) {
        serverTime = @([(NSString *)raw doubleValue]);
    }

    if (!serverTime) {
        NSDictionary *server = response[@"server"];
        if ([server isKindOfClass:NSDictionary.class]) {
            id nested = server[@"time"];
            if ([nested isKindOfClass:NSNumber.class]) {
                serverTime = nested;
            } else if ([nested isKindOfClass:NSString.class]) {
                serverTime = @([(NSString *)nested doubleValue]);
            }
        }
    }

    if (!serverTime || serverTime.doubleValue <= 0.0) {
        return;
    }

    NSTimeInterval offset = serverTime.doubleValue - [NSDate date].timeIntervalSince1970;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setDouble:offset forKey:SERVER_OFFSET_KEY];
    [defaults setBool:YES forKey:SERVER_OFFSET_VALID_KEY];
}

#pragma mark - Request Helpers

- (NSString *)requestTimestamp {
    NSTimeInterval timestamp = [NSDate date].timeIntervalSince1970 + [self serverTimeOffset];
    return [NSString stringWithFormat:@"%.3f", timestamp];
}

- (NSString *)requestId {
    return [NSUUID UUID].UUIDString.lowercaseString;
}

- (NSString *)appVersionForHeader {
    return [self applicationVersion];
}

- (void)completeOnMain:(void (^)(void))block {
    if (!block) return;
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (ZXNetworkErrorType)errorTypeForCode:(NSString *)code {
    NSString *normalized = code.uppercaseString ?: @"";

    if ([normalized isEqualToString:@"INVALID_KEY"]) return ZXNetworkErrorInvalidKey;
    if ([normalized isEqualToString:@"EXPIRED_KEY"]) return ZXNetworkErrorExpiredKey;
    if ([normalized isEqualToString:@"REVOKED_KEY"]) return ZXNetworkErrorRevokedKey;
    if ([normalized isEqualToString:@"DISABLED_KEY"]) return ZXNetworkErrorServer;
    if ([normalized isEqualToString:@"DEVICE_LIMIT"]) return ZXNetworkErrorDeviceLimit;
    if ([normalized isEqualToString:@"INVALID_SESSION"]) return ZXNetworkErrorInvalidSession;
    if ([normalized isEqualToString:@"MAINTENANCE"]) return ZXNetworkErrorMaintenance;
    if ([normalized isEqualToString:@"VERSION_MISMATCH"] ||
        [normalized isEqualToString:@"INVALID_APP_VERSION"] ||
        [normalized isEqualToString:@"APP_VERSION_REQUIRED"]) return ZXNetworkErrorVersionMismatch;
    if ([normalized isEqualToString:@"INCOMPATIBLE_DEVICE"] ||
        [normalized isEqualToString:@"DEVICE_NOT_SUPPORTED"] ||
        [normalized isEqualToString:@"UNSUPPORTED_DEVICE"]) return ZXNetworkErrorCompatibility;
    if ([normalized isEqualToString:@"RATE_LIMITED"] ||
        [normalized isEqualToString:@"RATE_LIMIT"]) return ZXNetworkErrorRateLimited;

    return ZXNetworkErrorServer;
}

- (void)updateLastError:(NSString * _Nullable)message {
    NSString *copy = [message copy];
    dispatch_async(self.stateQueue, ^{
        self.lastErrorMessage = copy;
    });
}

- (void)invalidateSessionIfNeededForError:(ZXNetworkErrorType)errorType {
    BOOL shouldInvalidate =
        errorType == ZXNetworkErrorInvalidSession ||
        errorType == ZXNetworkErrorRevokedKey ||
        errorType == ZXNetworkErrorExpiredKey ||
        errorType == ZXNetworkErrorInvalidKey;

    if (shouldInvalidate) {
        [self deleteSecureAccount:KEYCHAIN_SESSION_ACCOUNT];
    }
}

#pragma mark - Core Transport

- (void)sendRequestToEndpoint:(NSString *)endpoint
                      payload:(NSDictionary * _Nullable)payloadDict
                 requiresAuth:(BOOL)requiresAuth
                   completion:(void (^)(BOOL success,
                                        NSDictionary * _Nullable responseData,
                                        ZXNetworkErrorType errorType,
                                        NSString * _Nullable errorMsg))completion {
    if (!completion) return;

    NSString *safeEndpoint = endpoint.length > 0 ? endpoint : @"";
    NSURL *url = [NSURL URLWithString:[BASE_URL stringByAppendingString:safeEndpoint]];
    if (!url) {
        [self completeOnMain:^{
            completion(NO, nil, ZXNetworkErrorServer, @"Internal error: malformed endpoint URL.");
        }];
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.timeoutInterval = DEFAULT_TIMEOUT;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[self appVersionForHeader] forHTTPHeaderField:@"X-ZENTRAX-App-Version"];
    [request setValue:[self requestId] forHTTPHeaderField:@"X-Request-ID"];

    if (requiresAuth) {
        NSString *token = [self getTokenFromKeychain];
        if (token.length == 0) {
            [self completeOnMain:^{
                completion(NO, nil, ZXNetworkErrorInvalidSession, @"Authentication token missing. Please log in again.");
            }];
            return;
        }
        [request setValue:[NSString stringWithFormat:@"Bearer %@", token]
       forHTTPHeaderField:@"Authorization"];
    }

    NSMutableDictionary *body = payloadDict.mutableCopy ?: [NSMutableDictionary dictionary];
    body[@"timestamp"] = [self requestTimestamp];
    body[@"app_version"] = [self applicationVersion];
    body[@"client_version"] = [self applicationVersion];

    NSError *serializationError = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&serializationError];
    if (!bodyData || serializationError) {
        [self completeOnMain:^{
            completion(NO, nil, ZXNetworkErrorServer, @"Internal error: request serialization failed.");
        }];
        return;
    }
    request.HTTPBody = bodyData;

    [self beginRequest];

    __weak typeof(self) weakSelf = self;
    __block NSURLSessionDataTask *task = nil;
    task = [self.secureSession dataTaskWithRequest:request
                                 completionHandler:^(NSData * _Nullable data,
                                                     NSURLResponse * _Nullable response,
                                                     NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf endRequest];
            dispatch_async(strongSelf.stateQueue, ^{
                if (task) [strongSelf.activeTasks removeObject:task];
            });
        }

        if (error) {
            ZXNetworkErrorType type = ZXNetworkErrorConnection;
            NSString *message = @"Secure connection could not be established.";

            if (error.code == NSURLErrorCancelled) {
                message = @"Request was cancelled.";
            } else if (error.localizedDescription.length > 0) {
                message = error.localizedDescription;
            }

            if (strongSelf) [strongSelf updateLastError:message];
            [self completeOnMain:^{
                completion(NO, nil, type, message);
            }];
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (![httpResponse isKindOfClass:NSHTTPURLResponse.class]) {
            NSString *message = @"Invalid server response format.";
            if (strongSelf) [strongSelf updateLastError:message];
            [self completeOnMain:^{
                completion(NO, nil, ZXNetworkErrorInvalidResponse, message);
            }];
            return;
        }

        if (data.length == 0) {
            NSString *message = [NSString stringWithFormat:@"Server returned an empty response (HTTP %ld).", (long)httpResponse.statusCode];
            if (strongSelf) [strongSelf updateLastError:message];
            [self completeOnMain:^{
                completion(NO, nil, ZXNetworkErrorServer, message);
            }];
            return;
        }

        NSError *parseError = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (parseError || ![object isKindOfClass:NSDictionary.class]) {
            NSString *message = @"Server responded with malformed data.";
            if (strongSelf) [strongSelf updateLastError:message];
            [self completeOnMain:^{
                completion(NO, nil, ZXNetworkErrorInvalidResponse, message);
            }];
            return;
        }

        NSDictionary *json = (NSDictionary *)object;
        if (strongSelf) [strongSelf updateServerTimeFromResponse:json];

        NSString *status = [json[@"status"] isKindOfClass:NSString.class] ? json[@"status"] : @"";
        BOOL success = [status.lowercaseString isEqualToString:@"success"];

        NSString *message = [json[@"message"] isKindOfClass:NSString.class]
            ? json[@"message"]
            : (success ? @"Request completed successfully." : @"The server rejected the request.");

        if (success) {
            if (strongSelf) [strongSelf updateLastError:nil];
            [self completeOnMain:^{
                completion(YES, json, ZXNetworkErrorNone, nil);
            }];
            return;
        }

        NSString *errorCode = [json[@"error_code"] isKindOfClass:NSString.class]
            ? json[@"error_code"] : @"SERVER_ERROR";
        ZXNetworkErrorType errorType = strongSelf
            ? [strongSelf errorTypeForCode:errorCode]
            : ZXNetworkErrorServer;

        if (strongSelf) {
            [strongSelf invalidateSessionIfNeededForError:errorType];
            [strongSelf updateLastError:message];
        }

        [self completeOnMain:^{
            completion(NO, json, errorType, message);
        }];
    }];

    dispatch_async(self.stateQueue, ^{
        [self.activeTasks addObject:task];
    });
    [task resume];
}

#pragma mark - Bootstrap

- (void)bootstrapWithCompletion:(ZXBootstrapCompletion)completion {
    [self bootstrapWithPhaseHandler:nil completion:completion];
}

- (void)bootstrapWithPhaseHandler:(ZXAuthenticationPhaseHandler _Nullable)phaseHandler
                        completion:(ZXBootstrapCompletion)completion {
    if (!completion) return;

    if (phaseHandler) {
        [self completeOnMain:^{
            phaseHandler(ZXAuthenticationPhaseConnecting, @"Connecting to ZENTRAX server…");
        }];
    }

    NSDictionary *payload = @{
        @"action": @"bootstrap",
        @"hwid": [self getHardwareID],
        @"device": [self deviceInformation]
    };

    [self sendRequestToEndpoint:@"auth.php"
                         payload:payload
                    requiresAuth:NO
                      completion:^(BOOL success,
                                   NSDictionary *responseData,
                                   ZXNetworkErrorType errorType,
                                   NSString *errorMsg) {
        ZXBootstrapState state = ZXBootstrapStateUnknown;

        if (success) {
            state = ZXBootstrapStateReady;
            if (phaseHandler) {
                phaseHandler(ZXAuthenticationPhaseLoadingConfiguration, @"Loading server configuration…");
            }
            [self cacheConfigurationFromResponse:responseData];
            [self cacheCompatibilityFromResponse:responseData];
            [self completeOnMain:^{
                completion(YES, responseData, state, ZXNetworkErrorNone, nil);
            }];
            return;
        }

        switch (errorType) {
            case ZXNetworkErrorMaintenance:
                state = ZXBootstrapStateMaintenance;
                break;
            case ZXNetworkErrorVersionMismatch:
                state = ZXBootstrapStateVersionMismatch;
                break;
            case ZXNetworkErrorCompatibility:
                state = ZXBootstrapStateIncompatible;
                break;
            case ZXNetworkErrorConnection:
                state = ZXBootstrapStateConnectionError;
                break;
            default:
                state = ZXBootstrapStateUnknown;
                break;
        }

        [self completeOnMain:^{
            completion(NO, responseData, state, errorType, errorMsg);
        }];
    }];
}

#pragma mark - Authentication

- (void)authenticateWithKey:(NSString *)key
                 completion:(ZXNetworkCompletion)completion {
    [self authenticateWithKey:key phaseHandler:nil completion:completion];
}

- (void)authenticateWithKey:(NSString *)key
               phaseHandler:(ZXAuthenticationPhaseHandler _Nullable)phaseHandler
                 completion:(ZXNetworkCompletion)completion {
    if (!completion) return;

    NSString *cleanKey = [key stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (cleanKey.length == 0) {
        [self completeOnMain:^{
            completion(NO, nil, ZXNetworkErrorInvalidKey, @"License key cannot be empty.");
        }];
        return;
    }

    if (phaseHandler) {
        phaseHandler(ZXAuthenticationPhaseConnecting, @"Connecting to ZENTRAX server…");
    }

    NSDictionary *payload = @{
        @"action": @"login",
        @"key": cleanKey,
        @"hwid": [self getHardwareID],
        @"device": [self deviceInformation]
    };

    [self sendRequestToEndpoint:@"auth.php"
                         payload:payload
                    requiresAuth:NO
                      completion:^(BOOL success,
                                   NSDictionary *responseData,
                                   ZXNetworkErrorType errorType,
                                   NSString *errorMsg) {
        if (!success) {
            if (phaseHandler) {
                phaseHandler(ZXAuthenticationPhaseIdle, errorMsg ?: @"Authentication failed.");
            }
            completion(NO, responseData, errorType, errorMsg);
            return;
        }

        if (phaseHandler) {
            phaseHandler(ZXAuthenticationPhaseAuthenticating, @"Authenticating license…");
            phaseHandler(ZXAuthenticationPhaseVerifyingLicense, @"Verifying license and device…");
        }

        NSString *token = [responseData[@"token"] isKindOfClass:NSString.class]
            ? responseData[@"token"] : nil;
        if (token.length == 0) {
            NSString *message = @"Authentication succeeded, but no secure session token was returned.";
            if (phaseHandler) phaseHandler(ZXAuthenticationPhaseIdle, message);
            completion(NO, responseData, ZXNetworkErrorServer, message);
            return;
        }

        if (phaseHandler) {
            phaseHandler(ZXAuthenticationPhaseSecuringSession, @"Securing session…");
        }

        if (![self saveSecureString:token account:KEYCHAIN_SESSION_ACCOUNT]) {
            NSString *message = @"Unable to securely store the session token.";
            [self deleteSecureAccount:KEYCHAIN_SESSION_ACCOUNT];
            if (phaseHandler) phaseHandler(ZXAuthenticationPhaseIdle, message);
            completion(NO, responseData, ZXNetworkErrorServer, message);
            return;
        }

        [self saveSecureString:cleanKey account:KEYCHAIN_LICENSE_ACCOUNT];
        [self cacheConfigurationFromResponse:responseData];
        [self cacheCompatibilityFromResponse:responseData];

        if (phaseHandler) {
            phaseHandler(ZXAuthenticationPhaseLoadingConfiguration, @"Loading configuration and features…");
            phaseHandler(ZXAuthenticationPhaseAccessGranted, @"Access granted.");
        }

        completion(YES, responseData, ZXNetworkErrorNone, nil);
    }];
}

- (NSString * _Nullable)rememberedLicenseKey {
    return [self secureStringForAccount:KEYCHAIN_LICENSE_ACCOUNT];
}

#pragma mark - Configuration Cache

- (void)cacheConfigurationFromResponse:(NSDictionary *)response {
    if (![response isKindOfClass:NSDictionary.class]) return;

    BOOL containsConfiguration = response[@"categories"] != nil ||
                                  response[@"functions"] != nil ||
                                  response[@"dashboard"] != nil;
    if (!containsConfiguration) return;

    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:0 error:&error];
    if (!error && data) {
        [NSUserDefaults.standardUserDefaults setObject:data forKey:CONFIGURATION_CACHE_KEY];
    }
}

- (NSDictionary * _Nullable)cachedConfiguration {
    NSData *data = [NSUserDefaults.standardUserDefaults dataForKey:CONFIGURATION_CACHE_KEY];
    if (!data) return nil;

    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return (!error && [object isKindOfClass:NSDictionary.class]) ? object : nil;
}

- (void)loadConfigurationWithCompletion:(ZXNetworkCompletion)completion {
    NSDictionary *payload = @{
        @"action": @"heartbeat",
        @"hwid": [self getHardwareID]
    };

    [self sendRequestToEndpoint:@"heartbeat.php"
                         payload:payload
                    requiresAuth:YES
                      completion:^(BOOL success,
                                   NSDictionary *responseData,
                                   ZXNetworkErrorType errorType,
                                   NSString *errorMsg) {
        if (success) {
            [self cacheConfigurationFromResponse:responseData];
        }
        if (completion) completion(success, responseData, errorType, errorMsg);
    }];
}

#pragma mark - Module Operations

- (void)toggleModule:(NSString *)moduleName
               state:(BOOL)isOn
          completion:(ZXModuleCompletion)completion {
    if (moduleName.length == 0) {
        if (completion) completion(NO, nil, @"Invalid function identifier.");
        return;
    }

    NSDictionary *payload = @{
        @"action": @"get_payload",
        @"module": moduleName,
        @"state": isOn ? @"ON" : @"OFF",
        @"hwid": [self getHardwareID]
    };

    [self sendRequestToEndpoint:@"module.php"
                         payload:payload
                    requiresAuth:YES
                      completion:^(BOOL success,
                                   NSDictionary *responseData,
                                   ZXNetworkErrorType errorType,
                                   NSString *errorMsg) {
        if (!success) {
            if (completion) completion(NO, nil, errorMsg);
            return;
        }

        NSDictionary *operationPayload = nil;
        id rawPayload = responseData[@"payload"];
        if ([rawPayload isKindOfClass:NSDictionary.class]) {
            operationPayload = rawPayload;
        }

        NSString *operationID = [responseData[@"operation_id"] isKindOfClass:NSString.class]
            ? responseData[@"operation_id"] : nil;

        if (operationID.length == 0) {
            if (completion) completion(NO, nil, @"Server response is missing the operation identifier.");
            return;
        }

        NSMutableDictionary *combined = [NSMutableDictionary dictionary];
        if (operationPayload) [combined addEntriesFromDictionary:operationPayload];
        combined[@"operation_id"] = operationID;

        if ([responseData[@"target"] isKindOfClass:NSDictionary.class]) {
            combined[@"target"] = responseData[@"target"];
        }
        if ([responseData[@"restore_contract"] isKindOfClass:NSDictionary.class]) {
            combined[@"restore_contract"] = responseData[@"restore_contract"];
        }
        if ([responseData[@"switch_mode"] isKindOfClass:NSString.class]) {
            combined[@"switch_mode"] = responseData[@"switch_mode"];
        }
        if ([responseData[@"server_time"] isKindOfClass:NSNumber.class] ||
            [responseData[@"server_time"] isKindOfClass:NSString.class]) {
            combined[@"server_time"] = responseData[@"server_time"];
        }

        if (isOn) {
            BOOL validPayload = [combined[@"file_data"] isKindOfClass:NSString.class] &&
                                [combined[@"sha256"] isKindOfClass:NSString.class] &&
                                [combined[@"size"] isKindOfClass:NSNumber.class];
            if (!validPayload) {
                if (completion) completion(NO, nil, @"Server returned an incomplete verified ON payload.");
                return;
            }
        } else {
            BOOL validContract = [combined[@"restore_contract"] isKindOfClass:NSDictionary.class];
            if (!validContract) {
                if (completion) completion(NO, nil, @"Server returned an incomplete OFF restore contract.");
                return;
            }
        }

        if (completion) completion(YES, combined, nil);
    }];
}

- (void)performModuleOperationWithFunctionId:(NSString *)functionId
                                       action:(ZXModuleOperationAction)action
                                  completion:(ZXModuleCompletion)completion {
    if (functionId.length == 0 || action == ZXModuleOperationActionUnknown) {
        if (completion) completion(NO, nil, @"Invalid function operation.");
        return;
    }

    NSString *state = action == ZXModuleOperationActionON ? @"ON" : @"OFF";
    NSDictionary *payload = @{
        @"action": @"get_payload",
        @"function_id": functionId,
        @"state": state,
        @"hwid": [self getHardwareID]
    };

    [self sendRequestToEndpoint:@"module.php"
                         payload:payload
                    requiresAuth:YES
                      completion:^(BOOL success,
                                   NSDictionary *responseData,
                                   ZXNetworkErrorType errorType,
                                   NSString *errorMsg) {
        if (!success) {
            if (completion) completion(NO, nil, errorMsg);
            return;
        }

        NSString *operationID = [responseData[@"operation_id"] isKindOfClass:NSString.class]
            ? responseData[@"operation_id"] : nil;
        if (operationID.length == 0) {
            if (completion) completion(NO, nil, @"Server response is missing the operation identifier.");
            return;
        }

        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:responseData];
        result[@"operation_id"] = operationID;

        if (action == ZXModuleOperationActionON) {
            NSDictionary *payloadData = [responseData[@"payload"] isKindOfClass:NSDictionary.class]
                ? responseData[@"payload"] : nil;
            BOOL valid = [payloadData[@"file_data"] isKindOfClass:NSString.class] &&
                         [payloadData[@"sha256"] isKindOfClass:NSString.class] &&
                         [payloadData[@"size"] isKindOfClass:NSNumber.class];
            if (!valid) {
                if (completion) completion(NO, nil, @"Server returned an incomplete verified ON payload.");
                return;
            }
        } else {
            NSDictionary *contract = [responseData[@"restore_contract"] isKindOfClass:NSDictionary.class]
                ? responseData[@"restore_contract"] : nil;
            if (!contract) {
                if (completion) completion(NO, nil, @"Server returned an incomplete OFF restore contract.");
                return;
            }
        }

        if (completion) completion(YES, result, nil);
    }];
}

#pragma mark - Module Synchronization

- (NSString *)fallbackTransactionHashForOperation:(NSString *)operationID state:(BOOL)isOn {
    NSString *material = [NSString stringWithFormat:@"%@|%@|%@|%@",
                           operationID ?: @"",
                           isOn ? @"ON" : @"OFF",
                           [self getHardwareID],
                           [self applicationVersion]];
    NSData *data = [material dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);

    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", digest[i]];
    }
    return hash;
}

- (void)syncModuleState:(NSString *)moduleName
                  state:(BOOL)isOn
            operationId:(NSString *)operationId
             completion:(ZXModuleSyncCompletion)completion {
    if (moduleName.length == 0 || operationId.length == 0) {
        if (completion) completion(NO, @"Missing required identifiers for synchronization.");
        return;
    }

    NSDictionary *payload = @{
        @"action": @"sync_state",
        @"module": moduleName,
        @"state": isOn ? @"ON" : @"OFF",
        @"operation_id": operationId,
        @"transaction_hash": [self fallbackTransactionHashForOperation:operationId state:isOn],
        @"hwid": [self getHardwareID]
    };

    [self sendRequestToEndpoint:@"module.php"
                         payload:payload
                    requiresAuth:YES
                      completion:^(BOOL success,
                                   NSDictionary *responseData,
                                   ZXNetworkErrorType errorType,
                                   NSString *errorMsg) {
        if (completion) completion(success, errorMsg);
    }];
}

- (void)syncModuleStateForFunctionId:(NSString *)functionId
                               state:(BOOL)isOn
                         operationId:(NSString *)operationId
                          completion:(ZXModuleSyncCompletion)completion {
    if (functionId.length == 0 || operationId.length == 0) {
        if (completion) completion(NO, @"Missing required identifiers for synchronization.");
        return;
    }

    NSDictionary *payload = @{
        @"action": @"sync_state",
        @"function_id": functionId,
        @"state": isOn ? @"ON" : @"OFF",
        @"operation_id": operationId,
        @"transaction_hash": [self fallbackTransactionHashForOperation:operationId state:isOn],
        @"hwid": [self getHardwareID]
    };

    [self sendRequestToEndpoint:@"module.php"
                         payload:payload
                    requiresAuth:YES
                      completion:^(BOOL success,
                                   NSDictionary *responseData,
                                   ZXNetworkErrorType errorType,
                                   NSString *errorMsg) {
        if (completion) completion(success, errorMsg);
    }];
}

#pragma mark - Function Status / Dashboard

- (void)getFunctionStatus:(NSString *)functionId
               completion:(ZXNetworkCompletion)completion {
    if (functionId.length == 0) {
        if (completion) completion(NO, nil, ZXNetworkErrorServer, @"Invalid function identifier.");
        return;
    }

    [self loadConfigurationWithCompletion:^(BOOL success,
                                            NSDictionary *responseData,
                                            ZXNetworkErrorType errorType,
                                            NSString *errorMsg) {
        if (!success) {
            if (completion) completion(NO, responseData, errorType, errorMsg);
            return;
        }

        NSDictionary *match = [self findFunction:functionId inConfiguration:responseData];
        if (!match) {
            if (completion) completion(NO, nil, ZXNetworkErrorServer, @"Function was not found in the current server configuration.");
            return;
        }

        if (completion) completion(YES, match, ZXNetworkErrorNone, nil);
    }];
}

- (void)getFunctionStatusesWithCompletion:(ZXNetworkCompletion)completion {
    [self loadConfigurationWithCompletion:completion];
}

- (NSDictionary * _Nullable)findFunction:(NSString *)functionId
                         inConfiguration:(NSDictionary *)configuration {
    if (![configuration isKindOfClass:NSDictionary.class]) return nil;

    NSArray *categories = [configuration[@"categories"] isKindOfClass:NSArray.class]
        ? configuration[@"categories"] : nil;

    for (NSDictionary *category in categories) {
        if (![category isKindOfClass:NSDictionary.class]) continue;
        NSArray *functions = [category[@"functions"] isKindOfClass:NSArray.class]
            ? category[@"functions"] : nil;

        for (NSDictionary *function in functions) {
            if (![function isKindOfClass:NSDictionary.class]) continue;
            NSString *candidate = [NSString stringWithFormat:@"%@", function[@"id"] ?: @""];
            if ([candidate isEqualToString:functionId]) return function;
        }
    }

    NSArray *flatFunctions = [configuration[@"functions"] isKindOfClass:NSArray.class]
        ? configuration[@"functions"] : nil;
    for (NSDictionary *function in flatFunctions) {
        if (![function isKindOfClass:NSDictionary.class]) continue;
        NSString *candidate = [NSString stringWithFormat:@"%@", function[@"id"] ?: @""];
        if ([candidate isEqualToString:functionId]) return function;
    }

    return nil;
}

#pragma mark - Heartbeat / Session

- (void)verifySessionWithCompletion:(ZXSessionCompletion)completion {
    [self sendHeartbeatWithCompletion:completion];
}

- (void)sendHeartbeatWithCompletion:(ZXSessionCompletion)completion {
    if (!completion) return;

    if (![self hasActiveSession]) {
        [self completeOnMain:^{
            completion(NO, nil, ZXNetworkErrorInvalidSession, @"No active session.");
        }];
        return;
    }

    NSDictionary *payload = @{
        @"action": @"heartbeat",
        @"hwid": [self getHardwareID]
    };

    [self sendRequestToEndpoint:@"heartbeat.php"
                         payload:payload
                    requiresAuth:YES
                      completion:^(BOOL success,
                                   NSDictionary *responseData,
                                   ZXNetworkErrorType errorType,
                                   NSString *errorMsg) {
        if (success) {
            [self cacheConfigurationFromResponse:responseData];
            [self cacheCompatibilityFromResponse:responseData];
        }
        completion(success, responseData, errorType, errorMsg);
    }];
}

#pragma mark - Session State

- (BOOL)hasActiveSession {
    return [self getTokenFromKeychain].length > 0;
}

- (BOOL)isSessionLocallyUsable {
    return [self hasActiveSession];
}

- (void)logout {
    /*
     * Server-side session invalidation, when provided by the API, should be
     * performed by the caller before this local purge. This method always
     * removes the local bearer token and transient authentication state.
     */
    [self deleteSecureAccount:KEYCHAIN_SESSION_ACCOUNT];
    [self deleteSecureAccount:KEYCHAIN_LICENSE_ACCOUNT];
    [self resetServerTimeState];
    [self resetCompatibilityState];
}

#pragma mark - Compatibility

- (void)cacheCompatibilityFromResponse:(NSDictionary *)response {
    if (![response isKindOfClass:NSDictionary.class]) return;

    NSDictionary *compatibility = nil;
    if ([response[@"compatibility"] isKindOfClass:NSDictionary.class]) {
        compatibility = response[@"compatibility"];
    } else if ([response[@"device_compatibility"] isKindOfClass:NSDictionary.class]) {
        compatibility = response[@"device_compatibility"];
    }

    if (!compatibility) return;

    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:compatibility options:0 error:&error];
    if (!error && data) {
        [NSUserDefaults.standardUserDefaults setObject:data forKey:COMPATIBILITY_CACHE_KEY];
    }
}

- (NSDictionary * _Nullable)cachedCompatibilityData {
    NSData *data = [NSUserDefaults.standardUserDefaults dataForKey:COMPATIBILITY_CACHE_KEY];
    if (!data) return nil;

    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return (!error && [object isKindOfClass:NSDictionary.class]) ? object : nil;
}

- (void)resetCompatibilityState {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:COMPATIBILITY_CACHE_KEY];
}

- (void)checkDeviceCompatibilityWithCompletion:(ZXCompatibilityCompletion)completion {
    if (!completion) return;

    NSDictionary *device = [self deviceInformation];
    NSDictionary *payload = @{
        @"action": @"bootstrap",
        @"hwid": [self getHardwareID],
        @"device": device
    };

    [self sendRequestToEndpoint:@"auth.php"
                         payload:payload
                    requiresAuth:NO
                      completion:^(BOOL success,
                                   NSDictionary *responseData,
                                   ZXNetworkErrorType errorType,
                                   NSString *errorMsg) {
        NSDictionary *compatibility = nil;
        if ([responseData[@"compatibility"] isKindOfClass:NSDictionary.class]) {
            compatibility = responseData[@"compatibility"];
        } else if ([responseData[@"device_compatibility"] isKindOfClass:NSDictionary.class]) {
            compatibility = responseData[@"device_compatibility"];
        } else if ([self cachedCompatibilityData]) {
            compatibility = [self cachedCompatibilityData];
        }

        BOOL supported = YES;
        if (compatibility) {
            id value = compatibility[@"supported"];
            if ([value isKindOfClass:NSNumber.class]) supported = [value boolValue];
            else if ([value isKindOfClass:NSString.class]) supported = [value boolValue];
        }

        if (!success && errorType != ZXNetworkErrorCompatibility) {
            completion(NO, compatibility ?: responseData, ZXDeviceCompatibilityStatusUnknown, errorMsg);
            return;
        }

        if (!success && errorType == ZXNetworkErrorCompatibility) {
            completion(YES, compatibility ?: responseData, ZXDeviceCompatibilityStatusUnsupported,
                       errorMsg ?: @"This device is not supported.");
            return;
        }

        [self cacheCompatibilityFromResponse:responseData];
        completion(YES, compatibility ?: @{},
                   supported ? ZXDeviceCompatibilityStatusSupported : ZXDeviceCompatibilityStatusUnsupported,
                   supported ? nil : ([compatibility[@"reason"] isKindOfClass:NSString.class] ? compatibility[@"reason"] : @"This device is not supported."));
    }];
}

#pragma mark - Shortcut / Automation

- (void)performShortcutFunctionOperation:(NSString *)functionId
                                  action:(ZXModuleOperationAction)action
                             completion:(ZXModuleCompletion)completion {
    /*
     * Shortcuts intentionally use the same authenticated module endpoint as
     * the main application. There is no unrestricted filesystem operation or
     * authentication bypass here.
     */
    [self performModuleOperationWithFunctionId:functionId action:action completion:completion];
}

- (void)getShortcutFunctionStatus:(NSString *)functionId
                      completion:(ZXNetworkCompletion)completion {
    [self getFunctionStatus:functionId completion:completion];
}

#pragma mark - Request Cancellation

- (void)cancelAllRequests {
    dispatch_async(self.stateQueue, ^{
        NSArray<NSURLSessionDataTask *> *tasks = self.activeTasks.allObjects;
        for (NSURLSessionDataTask *task in tasks) {
            [task cancel];
        }
        [self.activeTasks removeAllObjects];
    });
}

#pragma mark - TLS Trust

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential * _Nullable credential))completionHandler {
    /*
     * Use Apple's system trust evaluation. No certificate pin/hash is
     * hardcoded because the deployment does not provide a maintained pin set.
     */
    if ([challenge.protectionSpace.authenticationMethod
         isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }

    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

@end
