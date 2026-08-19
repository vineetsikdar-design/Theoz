//
//  ZentraxNetworkManager.h
//  Zentrax VIP - Premium Execution Node
//
//  Created by Zentrax Team.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZentraxNetworkManager : NSObject

/// Singleton Instance
+ (instancetype)sharedManager;

/// 1. Node Authentication (Login)
/// Sends the Key and Hardware ID to the server for validation.
- (void)authenticateWithKey:(NSString *)key completion:(void(^)(BOOL success, NSDictionary * _Nullable responseData, NSString * _Nullable errorMsg))completion;

/// 2. Module Toggle & Payload Fetch
/// Requests the specific module payload (ON/OFF file) from the server.
- (void)toggleModule:(NSString *)moduleName state:(BOOL)isOn completion:(void(^)(BOOL success, NSData * _Nullable fileData, NSString * _Nullable errorMsg))completion;

/// 3. Heartbeat / Session Validator
/// Silently pings the server to ensure the session and key are still active.
- (void)verifySessionWithCompletion:(void(^)(BOOL isValid))completion;

@end

NS_ASSUME_NONNULL_END
