//
//  ZentraxUI.h
//  Zentrax VIP - Premium Execution Node UI
//
//  Created by Zentrax Team.
//  Architecture: Ultra-Premium SaaS Layer
//  Status: PRODUCTION READY
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Strict Authentication Error Mapping
 * Matches exact server-side responses for unified UI handling.
 */
typedef NS_ENUM(NSInteger, ZXAuthError) {
    ZXAuthErrorNone,
    ZXAuthErrorInvalidKey,
    ZXAuthErrorExpiredKey,
    ZXAuthErrorRevokedKey,
    ZXAuthErrorDeviceLimit,
    ZXAuthErrorInvalidSession,
    ZXAuthErrorConnection,
    ZXAuthErrorServer
};

/// Delegate protocol for secure backend network integration and execution bridge
@protocol ZentraxUIDelegate <NSObject>
@optional

/// Fired when the user attempts to authenticate with a license key
- (void)zentraxDidRequestAuthenticationWithKey:(NSString *)key completion:(void(^)(BOOL success, ZXAuthError errorType, NSString * _Nullable errorMsg))completion;

/// Fired when a module switch is toggled. The execution bridge handles the 2-step secure payload synchronization.
- (void)zentraxDidRequestModuleToggle:(NSString *)moduleId state:(BOOL)isOn completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion;

/// Fired if a secure logout action is triggered, purging local keychain and state
- (void)zentraxDidRequestLogoutWithCompletion:(void(^)(void))completion;

/// Silently verifies the existing Keychain session on app launch and triggers dashboard restore
- (void)zentraxDidRequestSessionVerificationWithCompletion:(void(^)(BOOL isValid))completion;

@end

@interface ZentraxUI : UIViewController

/// Set this delegate to the Core Bridge (Tweak.m) to handle secure execution and requests
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

// MARK: - Dynamic Data Injection
/// Passes the array of module dictionaries received from the PHP backend to dynamically build the dashboard
- (void)updateDashboardWithModules:(NSArray<NSDictionary *> *)modules;

/// Updates the session details (e.g., expiry date, license status) on the premium dashboard
- (void)updateSubscriptionState:(NSDictionary *)subData;

@end

NS_ASSUME_NONNULL_END
