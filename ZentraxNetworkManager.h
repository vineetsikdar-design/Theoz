//
//  ZentraxNetworkManager.h
//  Zentrax VIP - Premium Execution Node
//
//  Created by Zentrax Team.
//  Status: PRODUCTION READY
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Network Error

/**
 * Unified network/application error mapping.
 *
 * The implementation maps server responses into these stable
 * client-side error types so UI and integration code do not need
 * to depend on raw HTTP status codes or server strings.
 */
typedef NS_ENUM(NSInteger, ZXNetworkErrorType) {
    ZXNetworkErrorNone = 0,
    ZXNetworkErrorInvalidKey,
    ZXNetworkErrorExpiredKey,
    ZXNetworkErrorRevokedKey,
    ZXNetworkErrorDeviceLimit,
    ZXNetworkErrorInvalidSession,
    ZXNetworkErrorConnection,
    ZXNetworkErrorServer,
    ZXNetworkErrorMaintenance,
    ZXNetworkErrorVersionMismatch,
    ZXNetworkErrorCompatibility,
    ZXNetworkErrorRateLimited,
    ZXNetworkErrorInvalidResponse
};

#pragma mark - Startup / Bootstrap

/**
 * Real authentication/startup phases.
 *
 * These are event-driven states. They are not intended to represent
 * artificial percentage-based progress.
 */
typedef NS_ENUM(NSInteger, ZXAuthenticationPhase) {
    ZXAuthenticationPhaseIdle = 0,
    ZXAuthenticationPhaseConnecting,
    ZXAuthenticationPhaseAuthenticating,
    ZXAuthenticationPhaseVerifyingLicense,
    ZXAuthenticationPhaseSecuringSession,
    ZXAuthenticationPhaseLoadingConfiguration,
    ZXAuthenticationPhaseAccessGranted
};

/**
 * Server startup policy state.
 */
typedef NS_ENUM(NSInteger, ZXBootstrapState) {
    ZXBootstrapStateUnknown = 0,
    ZXBootstrapStateReady,
    ZXBootstrapStateMaintenance,
    ZXBootstrapStateVersionMismatch,
    ZXBootstrapStateIncompatible,
    ZXBootstrapStateConnectionError
};

#pragma mark - License Status

/**
 * Server-authoritative license status.
 */
typedef NS_ENUM(NSInteger, ZXLicenseStatus) {
    ZXLicenseStatusUnknown = 0,
    ZXLicenseStatusUnactivated,
    ZXLicenseStatusActive,
    ZXLicenseStatusExpired,
    ZXLicenseStatusRevoked,
    ZXLicenseStatusDisabled
};

#pragma mark - Module Operation

/**
 * Server-authorized module operation.
 *
 * OFF does not require an OFF payload. The server returns a restore/delete
 * contract and the local state layer is responsible for preserving the
 * original file state safely.
 */
typedef NS_ENUM(NSInteger, ZXModuleOperationAction) {
    ZXModuleOperationActionUnknown = 0,
    ZXModuleOperationActionON,
    ZXModuleOperationActionOFF
};

#pragma mark - Compatibility

/**
 * Device compatibility result.
 */
typedef NS_ENUM(NSInteger, ZXDeviceCompatibilityStatus) {
    ZXDeviceCompatibilityStatusUnknown = 0,
    ZXDeviceCompatibilityStatusSupported,
    ZXDeviceCompatibilityStatusUnsupported
};

#pragma mark - Callback Types

typedef void (^ZXNetworkCompletion)(BOOL success,
                                    NSDictionary * _Nullable responseData,
                                    ZXNetworkErrorType errorType,
                                    NSString * _Nullable errorMsg);

typedef void (^ZXAuthenticationPhaseHandler)(ZXAuthenticationPhase phase,
                                              NSString * _Nullable message);

typedef void (^ZXBootstrapCompletion)(BOOL success,
                                       NSDictionary * _Nullable responseData,
                                       ZXBootstrapState state,
                                       ZXNetworkErrorType errorType,
                                       NSString * _Nullable errorMsg);

typedef void (^ZXModuleCompletion)(BOOL success,
                                   NSDictionary * _Nullable modulePayload,
                                   NSString * _Nullable errorMsg);

typedef void (^ZXModuleSyncCompletion)(BOOL success,
                                       NSString * _Nullable errorMsg);

typedef void (^ZXSessionCompletion)(BOOL isValid,
                                    NSDictionary * _Nullable responseData,
                                    ZXNetworkErrorType errorType,
                                    NSString * _Nullable errorMsg);

typedef void (^ZXCompatibilityCompletion)(BOOL success,
                                           NSDictionary * _Nullable compatibilityData,
                                           ZXDeviceCompatibilityStatus status,
                                           NSString * _Nullable errorMsg);

#pragma mark - ZentraxNetworkManager

@interface ZentraxNetworkManager : NSObject

/// Thread-safe singleton instance.
+ (instancetype)sharedManager;

#pragma mark - Startup / Bootstrap

/**
 * Performs the server-controlled startup/bootstrap check.
 *
 * This is intended to run before the login screen is presented.
 * The server may return:
 *
 * - ready
 * - maintenance
 * - version mismatch
 * - compatibility restriction
 * - server configuration
 * - server time
 * - feature/category configuration
 *
 * No license credentials are required for this startup policy check.
 */
- (void)bootstrapWithCompletion:(ZXBootstrapCompletion)completion;

/**
 * Performs bootstrap while reporting real network/bootstrap events.
 *
 * The handler is called only when an actual authentication/startup
 * phase changes. No artificial timer or fake percentage is involved.
 */
- (void)bootstrapWithPhaseHandler:(ZXAuthenticationPhaseHandler _Nullable)phaseHandler
                       completion:(ZXBootstrapCompletion)completion;

#pragma mark - Authentication

/**
 * Node Authentication / Login.
 *
 * Sends the license key and device identity to the server.
 * Callbacks are guaranteed to be delivered on the main thread.
 */
- (void)authenticateWithKey:(NSString *)key
                 completion:(ZXNetworkCompletion)completion;

/**
 * Authentication with real event-driven phase callbacks.
 *
 * The phase handler reports actual stages such as:
 *
 * Connecting
 * Authenticating
 * Verifying License
 * Securing Session
 * Loading Configuration
 * Access Granted
 */
- (void)authenticateWithKey:(NSString *)key
               phaseHandler:(ZXAuthenticationPhaseHandler _Nullable)phaseHandler
                 completion:(ZXNetworkCompletion)completion;

/**
 * Returns the currently stored license key when available.
 *
 * The implementation may return a masked/secure representation where
 * appropriate. The actual secret should not be exposed unnecessarily.
 */
- (NSString * _Nullable)rememberedLicenseKey;

#pragma mark - Server Time

/**
 * Returns the current server-clock offset relative to the local device.
 *
 * The offset is established from a trusted server response and is used
 * for client-side display calculations only. License validity remains
 * server authoritative.
 */
- (NSTimeInterval)serverTimeOffset;

/**
 * Returns the estimated current server time using the last known
 * server-clock offset.
 */
- (NSDate * _Nullable)estimatedServerDate;

/**
 * Clears the cached server-clock information.
 *
 * Normally used when logging out or when a fresh bootstrap is required.
 */
- (void)resetServerTimeState;

#pragma mark - Dynamic Configuration

/**
 * Requests the current server-controlled configuration for the active
 * session, including categories/functions and related feature metadata.
 *
 * The response is expected to contain server-authoritative configuration.
 * The client must not assume a hardcoded function list.
 */
- (void)loadConfigurationWithCompletion:(ZXNetworkCompletion)completion;

/**
 * Returns the last successfully loaded configuration, if available.
 *
 * This is intended for UI rendering while a fresh server request is
 * being performed. It must never be treated as authoritative for a
 * security-sensitive operation.
 */
- (NSDictionary * _Nullable)cachedConfiguration;

#pragma mark - Module Operations

/**
 * Module Toggle / Payload Fetch.
 *
 * Requests a server-authorized operation for the specified function.
 *
 * For ON:
 * - returns the verified payload
 * - returns target metadata
 * - returns operation_id
 *
 * For OFF:
 * - returns the server restore/delete contract
 * - does not require a separate OFF payload
 *
 * The returned operation must subsequently be finalized through
 * syncModuleState:state:operationId:completion: after the local
 * operation has completed successfully.
 */
- (void)toggleModule:(NSString *)moduleName
               state:(BOOL)isOn
          completion:(ZXModuleCompletion)completion;

/**
 * Preferred operation API using the server function identifier.
 *
 * Function IDs are preferred over display names because names may
 * change and are not guaranteed to be unique.
 */
- (void)performModuleOperationWithFunctionId:(NSString *)functionId
                                       action:(ZXModuleOperationAction)action
                                  completion:(ZXModuleCompletion)completion;

/**
 * Finalizes a server-authorized module operation after the local
 * operation has completed successfully.
 *
 * operationId is single-use and server validated.
 */
- (void)syncModuleState:(NSString *)moduleName
                  state:(BOOL)isOn
            operationId:(NSString *)operationId
             completion:(ZXModuleSyncCompletion)completion;

/**
 * Preferred synchronization API using the server function identifier.
 */
- (void)syncModuleStateForFunctionId:(NSString *)functionId
                               state:(BOOL)isOn
                         operationId:(NSString *)operationId
                          completion:(ZXModuleSyncCompletion)completion;

#pragma mark - Function Status

/**
 * Requests the authoritative status of a single function.
 *
 * Intended for Dashboard, Settings and Shortcuts/App Intents.
 */
- (void)getFunctionStatus:(NSString *)functionId
               completion:(ZXNetworkCompletion)completion;

/**
 * Requests the authoritative status of multiple functions.
 */
- (void)getFunctionStatusesWithCompletion:(ZXNetworkCompletion)completion;

#pragma mark - Heartbeat / Session

/**
 * Heartbeat / Session Validator.
 *
 * Silently verifies that the current session, license and device
 * authorization remain valid.
 */
- (void)verifySessionWithCompletion:(ZXSessionCompletion)completion;

/**
 * Explicit heartbeat request.
 *
 * Intended for the background/session monitor.
 */
- (void)sendHeartbeatWithCompletion:(ZXSessionCompletion)completion;

#pragma mark - Session State

/**
 * Checks whether a secure session token currently exists.
 */
- (BOOL)hasActiveSession;

/**
 * Returns whether the current session is considered locally usable.
 *
 * This is only a local convenience check. Server authorization remains
 * authoritative.
 */
- (BOOL)isSessionLocallyUsable;

/**
 * Secure Logout.
 *
 * Purges the active session token and associated transient
 * authentication state from secure local storage.
 */
- (void)logout;

#pragma mark - Device Compatibility

/**
 * Performs a server-controlled compatibility check for the current
 * device/application environment.
 *
 * The response may include:
 * - device model/name
 * - iOS version
 * - architecture
 * - app version
 * - required iOS version
 * - supported / unsupported status
 * - reason
 * - server compatibility policy
 */
- (void)checkDeviceCompatibilityWithCompletion:(ZXCompatibilityCompletion)completion;

/**
 * Returns the last known compatibility information.
 *
 * This is display/cache information only and must not bypass a fresh
 * server authorization decision.
 */
- (NSDictionary * _Nullable)cachedCompatibilityData;

/**
 * Clears locally cached compatibility information.
 */
- (void)resetCompatibilityState;

#pragma mark - Shortcut / Automation Support

/**
 * Performs a function operation intended for a Shortcut/App Intent.
 *
 * Shortcut actions must use the same authenticated session,
 * server authorization and normal operation lifecycle as the main UI.
 *
 * This method does not provide an unrestricted local filesystem path
 * or an authentication bypass.
 */
- (void)performShortcutFunctionOperation:(NSString *)functionId
                                  action:(ZXModuleOperationAction)action
                             completion:(ZXModuleCompletion)completion;

/**
 * Gets the current authoritative function status for Shortcut/App
 * Intent presentation.
 */
- (void)getShortcutFunctionStatus:(NSString *)functionId
                      completion:(ZXNetworkCompletion)completion;

#pragma mark - Connection / Request State

/**
 * Cancels currently running network requests owned by the manager.
 */
- (void)cancelAllRequests;

/**
 * Indicates whether the manager currently has an active network
 * request.
 */
@property (nonatomic, readonly, getter=isRequestInFlight) BOOL requestInFlight;

/**
 * Last known server/application error message, if any.
 */
@property (nonatomic, copy, readonly, nullable) NSString *lastErrorMessage;

@end

NS_ASSUME_NONNULL_END