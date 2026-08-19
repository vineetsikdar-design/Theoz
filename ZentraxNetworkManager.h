//
//  ZentraxNetworkManager.h
//  Zentrax VIP - Premium Execution Node
//
//  Created by Zentrax Team.
//  Architecture: Token-Based Secure Networking
//  Status: PRODUCTION READY
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZentraxNetworkManager : NSObject

/// Singleton Instance
+ (instancetype)sharedManager;

/// Safely checks if a session token exists in the Keychain
@property (nonatomic, readonly) BOOL hasActiveSession;

/// 1. Node Authentication (Login)
/// Sends the Key and Hardware ID to the server. Server must return a 'token' on success.
- (void)authenticateWithKey:(NSString *)key completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, NSString * _Nullable errorMsg))completion;

/// 2. Module Toggle & Payload Fetch
/// Requests the module payload. Returns a dictionary containing 'file_data', 'bundle_id', and 'relative_path'.
- (void)toggleModule:(NSString *)moduleName state:(BOOL)isOn completion:(void(^)(BOOL success, NSDictionary * _Nullable modulePayload, NSString * _Nullable errorMsg))completion;

/// 3. Heartbeat / Session Validator
/// Pings the server using the active token to ensure the session is still valid.
- (void)verifySessionWithCompletion:(void(^)(BOOL isValid))completion;

/// 4. Secure Logout
/// Completely wipes the session token from the device hardware keychain.
- (void)logout;

@end

NS_ASSUME_NONNULL_END
