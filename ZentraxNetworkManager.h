//
//  ZentraxNetworkManager.h
//  Zentrax VIP - Premium Execution Node
//
//  Created by Zentrax Team.
//  Status: PRODUCTION READY
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Strict Network Error Mapping
 * Matches exact server-side responses for unified UI and Tweak handling.
 */
typedef NS_ENUM(NSInteger, ZXNetworkErrorType) {
    ZXNetworkErrorNone,
    ZXNetworkErrorInvalidKey,
    ZXNetworkErrorExpiredKey,
    ZXNetworkErrorRevokedKey,
    ZXNetworkErrorDeviceLimit,
    ZXNetworkErrorInvalidSession,
    ZXNetworkErrorConnection,
    ZXNetworkErrorServer
};

@interface ZentraxNetworkManager : NSObject

/// Thread-safe Singleton Instance
+ (instancetype)sharedManager;

/// 1. Node Authentication (Login)
/// Sends the Key and Hardware ID to the server for validation.
/// Callbacks are guaranteed to be delivered on the main thread.
- (void)authenticateWithKey:(NSString *)key 
                 completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg))completion;

/// 2. Module Toggle & Payload Fetch (Step 1)
/// Requests the specific module payload (ON/OFF file) and operation_id from the server.
- (void)toggleModule:(NSString *)moduleName 
               state:(BOOL)isOn 
          completion:(void(^)(BOOL success, NSDictionary * _Nullable modulePayload, NSString * _Nullable errorMsg))completion;

/// 3. Module State Synchronization (Step 2)
/// Confirms local file overwrite success with the server using operation_id to finalize state.
- (void)syncModuleState:(NSString *)moduleName 
                  state:(BOOL)isOn 
            operationId:(NSString *)operationId 
             completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion;

/// 4. Heartbeat / Session Validator
/// Silently pings the server to ensure the session and key are still active.
- (void)verifySessionWithCompletion:(void(^)(BOOL isValid, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg))completion;

/// 5. Check Active Local Session
/// Safely queries the Keychain to determine if a secure token currently exists.
- (BOOL)hasActiveSession;

/// 6. Secure Logout
/// Purges the active session token from the device Keychain immediately.
- (void)logout;

@end

NS_ASSUME_NONNULL_END
