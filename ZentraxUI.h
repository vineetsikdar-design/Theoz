//
//  ZentraxUI.h
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//  Architecture: Ultra-Premium SaaS Layer
//  Status: PRODUCTION READY (Strictly Dynamic Data)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Delegate protocol for backend network integration
@protocol ZentraxUIDelegate <NSObject>
@optional
/// Fired when the user attempts to log in. Must call completion block with server response.
- (void)zentraxDidRequestAuthenticationWithKey:(NSString *)key completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion;

/// Fired when a module switch is toggled. `moduleId` is the exact name provided by the backend.
- (void)zentraxDidRequestModuleToggle:(NSString *)moduleId state:(BOOL)isOn completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion;

/// Fired if a logout action is triggered
- (void)zentraxDidRequestLogoutWithCompletion:(void(^)(void))completion;
@end

@interface ZentraxUI : UIViewController

/// Set this delegate to your ZentraxNetworkManager to handle server requests
@property (nonatomic, weak) id<ZentraxUIDelegate> delegate;

// MARK: - Global UI Overlays
- (void)showGlobalLoadingState:(NSString *)message;
- (void)hideGlobalLoadingState;

// MARK: - Error & Success Handling Modals
- (void)showNetworkError;
- (void)showServerError;
- (void)showRateLimitErrorWithSecondsRemaining:(NSInteger)seconds;
- (void)showSuccessMessage:(NSString *)title message:(NSString *)message;
- (void)showGlobalErrorWithTitle:(NSString *)title message:(NSString *)msg;

// MARK: - Dynamic Data Injection (Strictly populated by server response)
/// Passes the array of module dictionaries received from the PHP backend to build the list
- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules;

/// Updates the session details (e.g., expiry date, license status) on the dashboard
- (void)updateSubscriptionState:(NSDictionary *)subData;

@end

NS_ASSUME_NONNULL_END
