//
//  ZentraxNetworkManager.h
//  Zentrax VIP - Secure Networking Bridge
//
//  Created by Zentrax Team.
//  Status: PRODUCTION READY
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Strict Error Mapping for Zentrax Authentication and Validation
 * These map exactly to the PHP Backend 'error_code' responses.
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

/**
 * Singleton instance for centralized network and session management.
 */
+ (instancetype)sharedManager;

/**
 * Checks if a valid session token currently exists in the secure iOS Keychain.
 */
- (BOOL)hasActiveSession;

/**
 * Completely purges the current session token from the secure iOS Keychain.
 */
- (void)logout;

/**
 * Performs primary authentication with the Master Node using a license key.
 *
 * @param key The user's license key.
 * @param completion Returns success boolean, raw response data for UI dashboard injection, exact error type, and error message.
 */
- (void)authenticateWithKey:(NSString *)key 
                 completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg))completion;

/**
 * Step 1 of 2-Step Execution Contract: Retrieves the secure payload and cryptographic operation_id.
 * DOES NOT save the state on the server.
 *
 * @param moduleName The exact name of the function to retrieve payload for.
 * @param isOn The desired target state (ON/OFF).
 * @param completion Returns success boolean, the combined payload dictionary (including file_data, bundle_id, relative_path, target_filename, and operation_id), and error message.
 */
- (void)toggleModule:(NSString *)moduleName 
               state:(BOOL)isOn 
          completion:(void(^)(BOOL success, NSDictionary * _Nullable modulePayload, NSString * _Nullable errorMsg))completion;

/**
 * Step 2 of 2-Step Execution Contract: Confirms successful local file modification.
 * Consumes the operation_id and permanently updates the database state for the user.
 *
 * @param moduleName The exact name of the function.
 * @param isOn The successfully applied state.
 * @param operationId The secure token received from Step 1 (get_payload).
 * @param completion Returns success boolean and error message.
 */
- (void)syncModuleState:(NSString *)moduleName 
                  state:(BOOL)isOn 
            operationId:(NSString *)operationId 
             completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion;

/**
 * Validates the current Keychain session against the Master Node.
 * Detects administrative actions like Revokes, Bans, and Expirations, and triggers local logout if invalid.
 * Also returns the complete dashboard data to restore UI state.
 *
 * @param completion Returns validity boolean, the full dashboard dictionary (modules, states, subscription), exact error type, and error message.
 */
- (void)verifySessionWithCompletion:(void(^)(BOOL isValid, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg))completion;

@end

NS_ASSUME_NONNULL_END
