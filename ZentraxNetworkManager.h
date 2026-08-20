//
//  ZentraxNetworkManager.h
//  Zentrax VIP - Premium Execution Node
//
//  Created by Zentrax Team.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Structured error codes from the backend
typedef NS_ENUM(NSInteger, ZXNetworkErrorType) {
    ZXNetworkErrorNone = 0,
    ZXNetworkErrorInvalidKey = 1,
    ZXNetworkErrorExpiredKey = 2,
    ZXNetworkErrorConnection = 3,
    ZXNetworkErrorServer = 4
};

@interface ZentraxNetworkManager : NSObject

/// Singleton Instance
+ (instancetype)sharedManager;

/// 1. Node Authentication (Login)
/// Sends the Key and Hardware ID to the server for validation.
- (void)authenticateWithKey:(NSString *)key completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg))completion;

/// 2. Module Toggle & Payload Fetch
/// Requests the specific module payload (ON/OFF file) from the server.
/// FIX: Changed NSData to NSDictionary to match the parsed JSON payload expected by Tweak.m
- (void)toggleModule:(NSString *)moduleName state:(BOOL)isOn completion:(void(^)(BOOL success, NSDictionary * _Nullable modulePayload, NSString * _Nullable errorMsg))completion;

/// 3. Hardware Keychain Helper
/// Validates if a stored token exists on disk
- (BOOL)hasActiveSession;

/// 4. Heartbeat / Session Validator
/// Validates the existing session and fetches the dashboard payload to restore the UI.
- (void)verifySessionWithCompletion:(void(^)(BOOL isValid, NSDictionary * _Nullable responseData))completion;

/// 5. Logout
/// Clears local token
- (void)logout;

@end

NS_ASSUME_NONNULL_END
