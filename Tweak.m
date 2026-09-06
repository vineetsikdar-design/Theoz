		//
//  Tweak.m
//  Zentrax VIP - Core System Hooks & Execution Bridge
//
//  Createdd by Zentrax Team.
//  Status: PRODUCTION READY (V4)
//

@import UIKit;
#import <objc/runtime.h>
#import <objc/message.h>
#import <xpc/xpc.h>
#import <CommonCrypto/CommonDigest.h>

#include <errno.h>
#include <dirent.h>
#include <fcntl.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dlfcn.h>

// --- ZENTRAX IMPORTS ---
#import "MCMFilzaIntegration.h"
#import "ZentraxUI.h"
#import "ZentraxNetworkManager.h"

#pragma mark - ================= ROOT HELPER HOOKS =================

static BOOL hook_isRootHelperAvailable(id self, SEL _cmd) { return NO; }
static int hook_spawnRootHelper(id self, SEL _cmd) { return 0; }
static int hook_spawnRootHelperIfNeeds(id self, SEL _cmd) { return 0; }
static int hook_respawnRootHelper(id self, SEL _cmd) { return 0; }
static void hook_tryLoadFilzaHelper(id self, SEL _cmd) {}
static void hook_createHelperConnectionIfNeeds(id self, SEL _cmd) {}

static int hook_spawnRoot_args_pid(id self, SEL _cmd, id path, id args, int *pid) {
    if (pid) *pid = 0;
    return -1;
}
static id hook_sendObjectWithReplySync(id self, SEL _cmd, id msg) { return (id)xpc_null_create(); }
static id hook_sendObjectWithReplySync_fd(id self, SEL _cmd, id msg, int *fd) {
    if (fd) *fd = -1;
    return (id)xpc_null_create();
}
static id hook_sendObjectWithReplySync_fd_logintty(id self, SEL _cmd, id msg, int *fd, BOOL logintty) {
    if (fd) *fd = -1;
    return (id)xpc_null_create();
}
static void hook_sendObjectNoReply(id self, SEL _cmd, id msg) {}
static void hook_sendObjectWithReplyAsync(id self, SEL _cmd, id msg, id queue, id completion) {
    if (completion) { void (^block)(id) = completion; block(nil); }
}

#pragma mark - ================= PATH RESOLUTION UTILITIES =================

static NSString *findBundlePath(NSString *bundleId) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *appsDir = @"/var/containers/Bundle/Application";
    for (NSString *uuid in [fm contentsOfDirectoryAtPath:appsDir error:nil]) {
        NSString *uuidPath = [appsDir stringByAppendingPathComponent:uuid];
        for (NSString *item in [fm contentsOfDirectoryAtPath:uuidPath error:nil]) {
            if (![item hasSuffix:@".app"]) continue;
            NSString *appPath = [uuidPath stringByAppendingPathComponent:item];
            NSString *plist = [appPath stringByAppendingPathComponent:@"Info.plist"];
            NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:plist];
            if ([info[@"CFBundleIdentifier"] isEqualToString:bundleId]) return appPath;
        }
    }
    return nil;
}

static NSString *findDataContainer(NSString *bundleId) {
    NSString *error = nil;
    NSString *path = MCMFilzaDataContainerPath(bundleId, &error);
    if (!path) NSLog(@"[Zentrax VIP] Dynamic Container Lookup Failed for id=%@ detail=%@", bundleId, error);
    return path;
}

static NSString *computeSHA256OfData(NSData *data) {
    if (!data) return nil;
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    if (CC_SHA256([data bytes], (CC_LONG)[data length], hash)) {
        NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [output appendFormat:@"%02x", hash[i]];
        }
        return output;
    }
    return nil;
}

#pragma mark - ================= APPS MANAGER HOOKS =================

static IMP orig_allApplications = NULL;
static id hook_allApplications(id self, SEL _cmd) {
    NSArray *origResult = ((id(*)(id,SEL))orig_allApplications)(self, _cmd);
    if (origResult && origResult.count > 0) return origResult;
    return [NSMutableArray array];
}

static IMP orig_setAppProxy = NULL;
static void hook_setAppProxy(id self, SEL _cmd, id proxy) {
    ((void(*)(id,SEL,id))orig_setAppProxy)(self, _cmd, proxy);
    NSString *bundleId = [self performSelector:NSSelectorFromString(@"bundleId")];
    if (!bundleId) return;

    NSString *bundlePath = nil;
    NSString *currentFilePath = [self performSelector:NSSelectorFromString(@"filePath")];

    if (!currentFilePath || currentFilePath.length == 0) {
        NSURL *bundleURL = [proxy performSelector:@selector(bundleURL)];
        if (bundleURL) bundlePath = [bundleURL path];
        if (!bundlePath) bundlePath = findBundlePath(bundleId);
        if (bundlePath) {
            ((void(*)(id,SEL,id))objc_msgSend)(self, NSSelectorFromString(@"setFilePath:"), bundlePath);
        }
    } else {
        bundlePath = currentFilePath;
    }

    NSString *docPath = ((id(*)(id,SEL))objc_msgSend)(self, NSSelectorFromString(@"documentPath"));
    if (!docPath) {
        NSURL *dataURL = [proxy performSelector:@selector(dataContainerURL)];
        if (dataURL) docPath = [dataURL path];
        if (!docPath) docPath = findDataContainer(bundleId);
        if (docPath) {
            ((void(*)(id,SEL,id))objc_msgSend)(self, NSSelectorFromString(@"setDocumentPath:"), docPath);
        }
    }
}

#pragma mark - ================= INTEGRITY BYPASS HOOKS =================

static IMP orig_showAlert = NULL;
static id hook_showAlertWithTitle(id self, SEL _cmd, id title, id text, id cancelButton, id otherButtons, id completion) {
    NSString *textStr = text;
    if ([textStr isKindOfClass:[NSString class]]) {
        if ([textStr containsString:@"binary was modified"] ||
            [textStr containsString:@"reinstall Filza"]) {
            NSLog(@"[Zentrax VIP] Suppressed integrity alert");
            return nil;
        }
    }
    return ((id(*)(id,SEL,id,id,id,id,id))orig_showAlert)(self, _cmd, title, text, cancelButton, otherButtons, completion);
}

static IMP orig_activationViewDidLoad = NULL;
static void hook_activationViewDidLoad(id self, SEL _cmd) {
    ((void(*)(id,SEL))orig_activationViewDidLoad)(self, _cmd);
    dispatch_async(dispatch_get_main_queue(), ^{
        ((void(*)(id,SEL,BOOL,id))objc_msgSend)(self,
            NSSelectorFromString(@"dismissViewControllerAnimated:completion:"), NO, nil);
    });
}


#pragma mark - ================= ZENTRAX VIP EXECUTION BRIDGE =================

#import "ZXStateStore.h"

@interface ZXCoreBridge : NSObject <ZentraxUIDelegate>
@property (nonatomic, weak) ZentraxUI *uiController;
@property (nonatomic, strong) dispatch_queue_t moduleExecutionQueue;
@property (nonatomic, strong) ZXStateStore *stateStore;
@property (nonatomic, strong) NSMutableSet<NSString *> *activeTargetOperations;
+ (instancetype)sharedBridge;
@end

@implementation ZXCoreBridge

+ (instancetype)sharedBridge {
    static ZXCoreBridge *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZXCoreBridge alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _moduleExecutionQueue = dispatch_queue_create("in.zentrax.execution.queue",
                                                       DISPATCH_QUEUE_SERIAL);
        _stateStore = [ZXStateStore sharedStore];
        _activeTargetOperations = [NSMutableSet set];

        /*
         * Open the persistent application-layer ledger before UI work.
         * The ledger records transactions/recovery state only; it does not
         * implement or alter any low-level privilege mechanism.
         */
        [_stateStore open:nil];
        [_stateStore synchronize:nil];
        [_stateStore markUnresolvedRecordsForReconciliation];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(zentraxApplicationWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(zentraxApplicationWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

- (void)zentraxApplicationWillResignActive:(NSNotification *)note {
    (void)note;
    [self.stateStore synchronize:nil];
}

- (void)zentraxApplicationWillTerminate:(NSNotification *)note {
    (void)note;
    [self.stateStore markUnresolvedRecordsForReconciliation];
    [self.stateStore synchronize:nil];
}

#pragma mark - UI / Thread Helpers

- (void)completeOnMain:(void (^)(void))block {
    if (!block) return;
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (ZXAuthError)mapNetworkErrorToAuthError:(ZXNetworkErrorType)networkError {
    switch (networkError) {
        case ZXNetworkErrorNone:
            return ZXAuthErrorNone;
        case ZXNetworkErrorInvalidKey:
            return ZXAuthErrorInvalidKey;
        case ZXNetworkErrorExpiredKey:
            return ZXAuthErrorExpiredKey;
        case ZXNetworkErrorRevokedKey:
            return ZXAuthErrorRevokedKey;
        case ZXNetworkErrorDeviceLimit:
            return ZXAuthErrorDeviceLimit;
        case ZXNetworkErrorInvalidSession:
            return ZXAuthErrorInvalidSession;
        case ZXNetworkErrorConnection:
            return ZXAuthErrorConnection;
        case ZXNetworkErrorMaintenance:
        case ZXNetworkErrorVersionMismatch:
        case ZXNetworkErrorCompatibility:
        case ZXNetworkErrorRateLimited:
            return ZXAuthErrorServer;
        default:
            return ZXAuthErrorServer;
    }
}

#pragma mark - Authentication

- (void)zentraxDidRequestAuthenticationWithKey:(NSString *)key
                                    completion:(void(^)(BOOL success,
                                                        ZXAuthError errorType,
                                                        NSString * _Nullable errorMsg))completion {
    if (key.length == 0) {
        [self completeOnMain:^{
            if (completion) completion(NO, ZXAuthErrorInvalidKey,
                                        @"Please enter a valid license key.");
        }];
        return;
    }

    [[ZentraxNetworkManager sharedManager]
        authenticateWithKey:key
        completion:^(BOOL success,
                     NSDictionary * _Nullable responseData,
                     ZXNetworkErrorType errorType,
                     NSString * _Nullable errorMsg) {

        ZXAuthError mappedError = [self mapNetworkErrorToAuthError:errorType];

        [self completeOnMain:^{
            if (!success || !responseData) {
                if (completion) {
                    completion(NO, mappedError,
                               errorMsg.length ? errorMsg : @"Authentication failed.");
                }
                return;
            }

            NSArray *modules = responseData[@"modules"];
            if ([modules isKindOfClass:NSArray.class]) {
                [self.uiController updateDashboardWithModules:modules];
            }

            NSDictionary *subscription = responseData[@"subscription"];
            if ([subscription isKindOfClass:NSDictionary.class]) {
                [self.uiController updateSubscriptionState:subscription];
            }

            /*
             * Associate any existing ledger records with the newly verified
             * server session. This never changes activation/expiry timing.
             */
            NSString *licenseId = [responseData[@"license"][@"id"] description];
            NSString *deviceId = [responseData[@"device"][@"id"] description];

            if (licenseId.length && deviceId.length) {
                NSError *associationError = nil;
                NSArray *records = [self.stateStore recordsForLicenseId:licenseId];

                for (ZXTargetLedgerRecord *record in records) {
                    if (record.canonicalTarget.length) {
                        [self.stateStore associateTarget:record.canonicalTarget
                                               licenseId:licenseId
                                                deviceId:deviceId
                                                   error:&associationError];
                    }
                }
            }

            if (completion) completion(YES, ZXAuthErrorNone, nil);
        }];
    }];
}

#pragma mark - Session Verification / Recovery

- (void)zentraxDidRequestSessionVerificationWithCompletion:(void(^)(BOOL isValid))completion {
    ZentraxNetworkManager *network = [ZentraxNetworkManager sharedManager];

    if (![network hasActiveSession]) {
        [self completeOnMain:^{
            if (completion) completion(NO);
        }];
        return;
    }

    /*
     * Load/revalidate the local transaction ledger before restoring the
     * dashboard. Unresolved entries remain visible to reconciliation logic
     * instead of being silently discarded.
     */
    [self.stateStore synchronize:nil];
    [self.stateStore validateLedger:nil];

    [network verifySessionWithCompletion:^(BOOL isValid,
                                           NSDictionary * _Nullable responseData,
                                           ZXNetworkErrorType errorType,
                                           NSString * _Nullable errorMsg) {
        [self completeOnMain:^{
            if (!isValid || !responseData) {
                if (completion) completion(NO);
                return;
            }

            NSArray *modules = responseData[@"modules"];
            if ([modules isKindOfClass:NSArray.class]) {
                [self.uiController updateDashboardWithModules:modules];
            }

            NSDictionary *subscription = responseData[@"subscription"];
            if ([subscription isKindOfClass:NSDictionary.class]) {
                [self.uiController updateSubscriptionState:subscription];
            }

            if (completion) completion(YES);
        }];
    }];
}

#pragma mark - Operation Guard / Path Safety

- (BOOL)claimTargetOperation:(NSString *)target operationId:(NSString *)operationId {
    if (target.length == 0 || operationId.length == 0) return NO;
    @synchronized (self) {
        NSString *key = [NSString stringWithFormat:@"%@|%@", target, operationId];
        if ([self.activeTargetOperations containsObject:target]) return NO;
        [self.activeTargetOperations addObject:target];
        return YES;
    }
}

- (void)releaseTargetOperation:(NSString *)target {
    if (target.length == 0) return;
    @synchronized (self) {
        [self.activeTargetOperations removeObject:target];
    }
}

- (NSString *)normalizedRelativePath:(NSString *)relativePath {
    if (relativePath.length == 0 || [relativePath hasPrefix:@"/"] || [relativePath hasPrefix:@"\\"]) return nil;
    NSString *p = [relativePath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    NSArray<NSString *> *parts = [p componentsSeparatedByString:@"/"];
    NSMutableArray<NSString *> *clean = [NSMutableArray arrayWithCapacity:parts.count];
    for (NSString *part in parts) {
        if (part.length == 0 || [part isEqualToString:@"."]) continue;
        if ([part isEqualToString:@".."] || [part containsString:@"\0"] || [part containsString:@":"]) return nil;
        [clean addObject:part];
    }
    return clean.count ? [clean componentsJoinedByString:@"/"] : nil;
}

- (BOOL)isSafeRelativePath:(NSString *)relativePath filename:(NSString *)filename {
    if (relativePath.length == 0 || filename.length == 0) return NO;
    NSString *normalized = [self normalizedRelativePath:relativePath];
    if (!normalized) return NO;
    if ([filename hasPrefix:@"/"] || [filename hasPrefix:@"\\"] ||
        [filename containsString:@"/"] || [filename containsString:@"\\"] ||
        [filename isEqualToString:@"."] || [filename isEqualToString:@".."] ||
        [filename containsString:@"\0"] || [filename containsString:@":"]) return NO;
    return YES;
}

- (NSString *)targetPathForContainer:(NSString *)container
                       relativePath:(NSString *)relativePath
                            filename:(NSString *)filename {
    if (container.length == 0 || ![self isSafeRelativePath:relativePath filename:filename]) return nil;
    NSString *normalized = [self normalizedRelativePath:relativePath];
    if (!normalized) return nil;
    NSString *root = [container stringByStandardizingPath];
    NSString *directory = [root stringByAppendingPathComponent:normalized];
    NSString *target = [directory stringByAppendingPathComponent:filename];
    NSString *standard = [target stringByStandardizingPath];
    NSString *prefix = [root hasSuffix:@"/"] ? root : [root stringByAppendingString:@"/"];
    if (![standard hasPrefix:prefix]) return nil;
    return standard;
}

- (NSString *)sha256OfFileAtPath:(NSString *)path size:(NSUInteger *)size {
    if (size) *size = 0;
    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
    if (!data) return nil;
    if (size) *size = data.length;
    return computeSHA256OfData(data);
}

- (void)finishModuleFailure:(NSString *)message
                 completion:(void(^)(BOOL success,
                                     NSString * _Nullable errorMsg))completion {
    [self completeOnMain:^{
        if (completion) {
            completion(NO, message.length
                      ? message
                      : @"The requested operation could not be completed.");
        }
    }];
}

- (void)executeModulePayload:(NSDictionary *)modulePayload
                   functionId:(NSString *)functionId
                       action:(ZXModuleOperationAction)action
               requestedState:(BOOL)isOn
                    completion:(void(^)(BOOL success,
                                        NSString * _Nullable errorMsg))completion {

    if (![modulePayload isKindOfClass:NSDictionary.class]) {
        [self finishModuleFailure:@"Invalid module operation response."
                       completion:completion];
        return;
    }

    NSString *operationId = [modulePayload[@"operation_id"] description];
    NSString *serverFunctionId = [modulePayload[@"function_id"] description];
    NSString *resolvedFunctionId =
        serverFunctionId.length ? serverFunctionId : functionId;

    NSString *target = [modulePayload[@"target"] description];
    if (target.length == 0) {
        target = [modulePayload[@"canonical_target"] description];
    }

    if (operationId.length == 0 ||
        resolvedFunctionId.length == 0 ||
        target.length == 0) {
        [self finishModuleFailure:@"Invalid module operation contract received from server."
                       completion:completion];
        return;
    }

    if (![self claimTargetOperation:target operationId:operationId]) {
        [self finishModuleFailure:@"This target already has an operation in progress. Please wait for it to finish."
                       completion:completion];
        return;
    }

    NSString *licenseId = [modulePayload[@"license_id"] description];
    NSString *deviceId = [modulePayload[@"device_id"] description];

    NSError *ledgerError = nil;
    [self.stateStore beginOperationWithId:operationId
                                   action:(action == ZXModuleOperationActionON ? @"ON" : @"OFF")
                               functionId:resolvedFunctionId
                                licenseId:licenseId
                                 deviceId:deviceId
                                   target:target
                                    error:&ledgerError];

    if (ledgerError) {
        [self releaseTargetOperation:target];
        [self finishModuleFailure:@"Unable to prepare the local transaction safely."
                       completion:completion];
        return;
    }

    /*
     * OFF is restore/delete-contract driven. The client does not request or
     * manufacture an OFF payload.
     */
    if (!isOn) {
        NSDictionary *restore = modulePayload[@"restore_contract"];
        NSString *mode = [restore[@"mode"] description];

        if (![mode isEqualToString:@"CLIENT_ORIGINAL_BACKUP"]) {
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:@"Invalid restore contract received from server."
                           completion:completion];
            return;
        }

        ZXTargetLedgerRecord *record = [self.stateStore recordForTarget:target];
        NSString *bundleId = [modulePayload[@"bundle_id"] description];
        NSString *relativePath = [modulePayload[@"relative_path"] description];
        NSString *targetFilename = [modulePayload[@"target_filename"] description];

        /*
         * If the server has no file operation to perform locally (for example
         * the ledger has no active target), simply synchronize the state.
         */
        if (!record &&
            bundleId.length == 0 &&
            relativePath.length == 0 &&
            targetFilename.length == 0) {

            [[ZentraxNetworkManager sharedManager]
                syncModuleStateForFunctionId:resolvedFunctionId
                                      state:NO
                                operationId:operationId
                                  completion:^(BOOL syncSuccess,
                                               NSString * _Nullable syncErrorMsg) {
                if (syncSuccess) {
                    [self.stateStore commitOperationWithId:operationId
                                                targetHash:nil
                                                      size:0
                                                     error:nil];
                    [self.stateStore clearCompletedOperationWithId:operationId
                                                               error:nil];
                    [self releaseTargetOperation:target];
                    [self completeOnMain:^{
                        if (completion) completion(YES, nil);
                    }];
                } else {
                    [self.stateStore failOperationWithId:operationId error:nil];
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:syncErrorMsg ?: @"Failed to synchronize module state."
                                   completion:completion];
                }
            }];
            return;
        }

        if (!record ||
            ![self isSafeRelativePath:relativePath filename:targetFilename] ||
            bundleId.length == 0) {
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:@"Security validation failed for the restore target."
                           completion:completion];
            return;
        }

        dispatch_async(self.moduleExecutionQueue, ^{
            NSString *dataContainer = findDataContainer(bundleId);
            if (!dataContainer) {
                [self.stateStore failOperationWithId:operationId error:nil];
                [self finishModuleFailure:@"Target app container could not be resolved."
                               completion:completion];
                return;
            }

            NSString *finalTargetPath = [self targetPathForContainer:dataContainer
                                                           relativePath:relativePath
                                                                filename:targetFilename];
            if (!finalTargetPath) {
                [self.stateStore failOperationWithId:operationId error:nil];
                [self releaseTargetOperation:target];
                [self finishModuleFailure:@"Security validation failed for the resolved target path."
                               completion:completion];
                return;
            }
            NSString *backupPath = [finalTargetPath stringByAppendingString:@".bak"];

            NSFileManager *fm = NSFileManager.defaultManager;
            NSError * __autoreleasing fsError = nil;
            BOOL success = YES;

            if ([fm fileExistsAtPath:backupPath]) {
                [self.stateStore setState:ZXTargetLedgerStateRestoring
                                 forTarget:target
                                    error:nil];

                if (!record.hasOriginalBackup ||
                    record.backupValidity != ZXBackupValidityValid) {
                    success = NO;
                } else {
                    NSUInteger backupSize = 0;
                    NSString *backupHash = [self sha256OfFileAtPath:backupPath size:&backupSize];
                    if (backupHash.length == 0 ||
                        (record.originalBackupHash.length && ![backupHash.lowercaseString isEqualToString:record.originalBackupHash.lowercaseString]) ||
                        (record.originalBackupSize > 0 && backupSize != record.originalBackupSize)) {
                        success = NO;
                    }
                    if (success && [fm fileExistsAtPath:finalTargetPath]) {
                        [fm removeItemAtPath:finalTargetPath error:&fsError];
                    }

                    if (success &&
                        ![fm moveItemAtPath:backupPath
                                     toPath:finalTargetPath
                                      error:&fsError]) {
                        success = NO;
                    }
                }
            } else if (record.activeFunctionId.length > 0 &&
                       [fm fileExistsAtPath:finalTargetPath]) {

                [self.stateStore setState:ZXTargetLedgerStateRestoring
                                 forTarget:target
                                    error:nil];

                success = [fm removeItemAtPath:finalTargetPath
                                          error:&fsError];
            }

            if (!success) {
                [self.stateStore markTarget:target
                  requiresReconciliation:YES
                                    error:nil];
                [self.stateStore failOperationWithId:operationId
                                               error:&fsError];
                [self releaseTargetOperation:target];
                [self finishModuleFailure:@"Failed to restore the original target safely."
                               completion:completion];
                return;
            }

            [self.stateStore setActiveFunctionId:nil
                                      functionName:nil
                                       payloadHash:nil
                                      payloadSize:0
                                         forTarget:target
                                             error:nil];

            [self.stateStore setState:ZXTargetLedgerStateIdle
                             forTarget:target
                                error:nil];

            [[ZentraxNetworkManager sharedManager]
                syncModuleStateForFunctionId:resolvedFunctionId
                                      state:NO
                                operationId:operationId
                                  completion:^(BOOL syncSuccess,
                                               NSString * _Nullable syncErrorMsg) {
                if (!syncSuccess) {
                    [self.stateStore markTarget:target
                      requiresReconciliation:YES
                                        error:nil];
                    [self.stateStore failOperationWithId:operationId error:nil];
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:
                        syncErrorMsg ?: @"Server synchronization failed; recovery is required."
                               completion:completion];
                    return;
                }

                [self.stateStore commitOperationWithId:operationId
                                            targetHash:nil
                                                  size:0
                                                 error:nil];
                [self.stateStore clearCompletedOperationWithId:operationId
                                                           error:nil];
                [self.stateStore markTarget:target
                  requiresReconciliation:NO
                                    error:nil];
                [self releaseTargetOperation:target];

                [self completeOnMain:^{
                    if (completion) completion(YES, nil);
                }];
            }];
        });

        return;
    }

    /*
     * ON receives exactly one server-authorized payload. Verify its declared
     * hash before applying it.
     */
    NSString *base64Data = [modulePayload[@"file_data"] description];
    NSString *bundleId = [modulePayload[@"bundle_id"] description];
    NSString *relativePath = [modulePayload[@"relative_path"] description];
    NSString *targetFilename = [modulePayload[@"target_filename"] description];

    if (base64Data.length == 0 ||
        bundleId.length == 0 ||
        ![self isSafeRelativePath:relativePath filename:targetFilename]) {
        [self.stateStore failOperationWithId:operationId error:nil];
        [self releaseTargetOperation:target];
        [self finishModuleFailure:@"Invalid module payload or target configuration."
                       completion:completion];
        return;
    }

    NSData *fileData =
        [[NSData alloc] initWithBase64EncodedString:base64Data
                                            options:NSDataBase64DecodingIgnoreUnknownCharacters];

    if (!fileData.length) {
        [self.stateStore failOperationWithId:operationId error:nil];
        [self releaseTargetOperation:target];
        [self finishModuleFailure:@"The module payload could not be decoded."
                       completion:completion];
        return;
    }

    NSString *declaredHash = [modulePayload[@"sha256"] description];
    NSUInteger declaredSize = [modulePayload[@"size"] unsignedIntegerValue];
    NSString *computedHash = computeSHA256OfData(fileData);

    if (declaredHash.length == 0 ||
        computedHash.length == 0 ||
        declaredSize == 0 ||
        declaredSize != fileData.length ||
        ![declaredHash.lowercaseString isEqualToString:computedHash.lowercaseString]) {
        [self.stateStore failOperationWithId:operationId error:nil];
        [self releaseTargetOperation:target];
        [self finishModuleFailure:@"Payload integrity verification failed."
                       completion:completion];
        return;
    }

    dispatch_async(self.moduleExecutionQueue, ^{
        NSString *dataContainer = findDataContainer(bundleId);
        if (!dataContainer) {
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:@"Target app container could not be resolved."
                           completion:completion];
            return;
        }

        NSString *finalTargetPath = [self targetPathForContainer:dataContainer
                                                       relativePath:relativePath
                                                            filename:targetFilename];
        if (!finalTargetPath) {
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:@"Security validation failed for the resolved target path."
                           completion:completion];
            return;
        }
        NSString *backupPath = [finalTargetPath stringByAppendingString:@".bak"];

        NSFileManager *fm = NSFileManager.defaultManager;
        NSError * __autoreleasing fsError = nil;

        ZXTargetLedgerRecord *record =
            [self.stateStore recordForTarget:target];

        /*
         * Preserve the original target only once. During a function switch,
         * an existing .bak is never overwritten.
         */
        if (!record || !record.hasOriginalBackup) {
            if ([fm fileExistsAtPath:backupPath]) {
                [self.stateStore markTarget:target
                  requiresReconciliation:YES
                                    error:nil];
                [self.stateStore failOperationWithId:operationId error:nil];
                [self releaseTargetOperation:target];
                [self finishModuleFailure:@"An existing backup was found but is not registered in the recovery ledger."
                               completion:completion];
                return;
            }

            if ([fm fileExistsAtPath:finalTargetPath] &&
                ![fm fileExistsAtPath:backupPath]) {

                if (![fm copyItemAtPath:finalTargetPath
                                 toPath:backupPath
                                  error:&fsError]) {
                    [self.stateStore failOperationWithId:operationId
                                                   error:&fsError];
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:
                        @"Could not preserve the original target safely."
                               completion:completion];
                    return;
                }

                NSData *originalData =
                    [NSData dataWithContentsOfFile:backupPath];
                NSString *originalHash =
                    computeSHA256OfData(originalData);

                if (originalHash.length == 0 || originalData.length == 0) {
                    [self.stateStore markTarget:target
                      requiresReconciliation:YES
                                        error:nil];
                    [self.stateStore failOperationWithId:operationId error:nil];
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:@"The original backup could not be verified."
                                   completion:completion];
                    return;
                }

                [self.stateStore setOriginalBackupHash:originalHash
                                                  size:originalData.length
                                                exists:YES
                                             validity:ZXBackupValidityValid
                                             forTarget:target
                                                 error:nil];
            } else if (![fm fileExistsAtPath:backupPath]) {
                [self.stateStore setOriginalBackupHash:nil
                                                  size:0
                                                exists:NO
                                             validity:ZXBackupValidityMissing
                                             forTarget:target
                                                 error:nil];
            }
        }

        [self.stateStore setState:record.activeFunctionId.length
                                  ? ZXTargetLedgerStateSwitching
                                  : ZXTargetLedgerStateStagingON
                         forTarget:target
                            error:nil];

        BOOL written =
            [fileData writeToFile:finalTargetPath
                          options:NSDataWritingAtomic
                            error:&fsError];

        if (!written) {
            [self.stateStore failOperationWithId:operationId
                                           error:&fsError];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:
                @"Failed to apply the requested module payload."
                       completion:completion];
            return;
        }

        NSData *writtenData =
            [NSData dataWithContentsOfFile:finalTargetPath];
        NSString *writtenHash =
            computeSHA256OfData(writtenData);

        if (!writtenData ||
            writtenData.length != fileData.length ||
            ![writtenHash.lowercaseString
                isEqualToString:computedHash.lowercaseString]) {

            [self.stateStore markTarget:target
              requiresReconciliation:YES
                                error:nil];
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];

            [self finishModuleFailure:
                @"Post-write integrity verification failed."
                       completion:completion];
            return;
        }

        [self.stateStore setState:ZXTargetLedgerStateONInProgress
                         forTarget:target
                            error:nil];

        [self.stateStore setActiveFunctionId:resolvedFunctionId
                                  functionName:[modulePayload[@"function_name"] description]
                                   payloadHash:writtenHash
                                  payloadSize:writtenData.length
                                     forTarget:target
                                         error:nil];

        [[ZentraxNetworkManager sharedManager]
            syncModuleStateForFunctionId:resolvedFunctionId
                                  state:YES
                            operationId:operationId
                              completion:^(BOOL syncSuccess,
                                           NSString * _Nullable syncErrorMsg) {

            if (!syncSuccess) {
                [self.stateStore markTarget:target
                  requiresReconciliation:YES
                                    error:nil];
                [self.stateStore failOperationWithId:operationId
                                               error:nil];
                [self releaseTargetOperation:target];

                [self finishModuleFailure:
                    syncErrorMsg ?: @"Server synchronization failed; recovery is required."
                           completion:completion];
                return;
            }

            [self.stateStore setState:ZXTargetLedgerStateIdle
                             forTarget:target
                                error:nil];

            [self.stateStore commitOperationWithId:operationId
                                        targetHash:writtenHash
                                              size:writtenData.length
                                             error:nil];
            [self.stateStore clearCompletedOperationWithId:operationId
                                                       error:nil];
            [self.stateStore markTarget:target
              requiresReconciliation:NO
                                error:nil];
            [self releaseTargetOperation:target];

            [self completeOnMain:^{
                if (completion) completion(YES, nil);
            }];
        }];
    });
}

#pragma mark - Module Toggle Entry Point

- (void)zentraxDidRequestModuleToggle:(NSString *)moduleId
                                state:(BOOL)isOn
                           completion:(void(^)(BOOL success,
                                               NSString * _Nullable errorMsg))completion {

    if (moduleId.length == 0) {
        [self finishModuleFailure:@"Invalid function identifier."
                       completion:completion];
        return;
    }

    ZXModuleOperationAction action =
        isOn ? ZXModuleOperationActionON : ZXModuleOperationActionOFF;

    [[ZentraxNetworkManager sharedManager]
        performModuleOperationWithFunctionId:moduleId
                                      action:action
                                  completion:^(BOOL success,
                                               NSDictionary * _Nullable modulePayload,
                                               NSString * _Nullable errorMsg) {

        if (!success || !modulePayload) {
            [self finishModuleFailure:
                errorMsg ?: @"The server rejected the module operation."
                       completion:completion];
            return;
        }

        [self executeModulePayload:modulePayload
                         functionId:moduleId
                             action:action
                     requestedState:isOn
                          completion:completion];
    }];
}

#pragma mark - Logout

- (void)zentraxDidRequestLogoutWithCompletion:(void(^)(void))completion {
    ZentraxNetworkManager *network = [ZentraxNetworkManager sharedManager];

    /*
     * Logout removes the authenticated session association only.
     * Persistent target ledger records are retained for recovery and the
     * license activation/expiry clock is never modified here.
     */
    [network logout];
    [self.stateStore clearTransientState];

    [self completeOnMain:^{
        if (completion) completion();
    }];
}

@end

#pragma mark - ================= ZENTRAX LAUNCH COORDINATOR =================

/*
 * IMPORTANT:
 *
 * Zentrax must not replace UIWindow's makeKeyAndVisible implementation.
 * Filza owns the application/window lifecycle, and globally replacing a
 * UIKit lifecycle method makes Zentrax execute in the middle of Filza's
 * own window bootstrap.  The previous implementation did exactly that.
 *
 * We instead wait until UIApplication has finished launching, then attach
 * Zentrax to the already-created application window on the main queue.
 * This leaves the original UIWindow implementation completely untouched.
 */

@interface ZXLaunchCoordinator : NSObject
+ (instancetype)sharedCoordinator;
- (void)start;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (UIWindow *)targetWindow;
- (void)installWhenWindowIsReadyWithAttempt:(NSInteger)attempt;
@end

@implementation ZXLaunchCoordinator

+ (instancetype)sharedCoordinator {
    static ZXLaunchCoordinator *coordinator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coordinator = [[ZXLaunchCoordinator alloc] init];
    });
    return coordinator;
}

- (void)start {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(applicationDidFinishLaunching:)
                   name:UIApplicationDidFinishLaunchingNotification
                 object:nil];

    /*
     * The constructor can execute after UIApplication has already posted the
     * launch notification in some loading arrangements.  The main-queue
     * fallback below therefore checks for the window independently.
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        [self installWhenWindowIsReadyWithAttempt:0];
    });
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    [self installWhenWindowIsReadyWithAttempt:0];
}

- (UIWindow *)targetWindow {
    UIApplication *application = UIApplication.sharedApplication;

    /* Prefer the key window from an active scene. */
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (scene.activationState == UISceneActivationStateUnattached ||
                scene.activationState == UISceneActivationStateBackground) {
                continue;
            }

            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene *windowScene = (UIWindowScene *)scene;

            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow && !window.hidden) {
                    return window;
                }
            }

            for (UIWindow *window in windowScene.windows) {
                if (!window.hidden && window.windowLevel == UIWindowLevelNormal) {
                    return window;
                }
            }
        }
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    for (UIWindow *window in application.windows) {
        if (window.isKeyWindow && !window.hidden) {
            return window;
        }
    }

    for (UIWindow *window in application.windows) {
        if (!window.hidden && window.windowLevel == UIWindowLevelNormal) {
            return window;
        }
    }
#pragma clang diagnostic pop

    return nil;
}

- (void)installWhenWindowIsReadyWithAttempt:(NSInteger)attempt {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self installWhenWindowIsReadyWithAttempt:attempt];
        });
        return;
    }

    /*
     * The launch notification is normally enough.  The bounded retry exists
     * only for the case where Filza creates its UIWindow immediately after
     * the notification has been delivered.
     */
    UIWindow *window = [self targetWindow];
    if (!window) {
        if (attempt < 40) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                          (int64_t)(0.05 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [self installWhenWindowIsReadyWithAttempt:attempt + 1];
            });
        } else {
            NSLog(@"[Zentrax VIP] Launch window was not available after startup retries.");
        }
        return;
    }

    static dispatch_once_t installToken;
    dispatch_once(&installToken, ^{
        NSLog(@"[Zentrax VIP] Installing UI on the post-launch Filza window.");

        /* MCM initialization is deliberately performed after application
         * launch rather than from a UIKit lifecycle-method hook. */
        MCMFilzaStart();

        Class ZentraxUIClass = NSClassFromString(@"ZentraxUI");
        if (!ZentraxUIClass) {
            NSLog(@"[Zentrax VIP] ZentraxUI class is unavailable.");
            return;
        }

        ZentraxUI *zentraxVC = [[ZentraxUIClass alloc] init];
        if (!zentraxVC) {
            NSLog(@"[Zentrax VIP] Failed to create ZentraxUI controller.");
            return;
        }

        ZXCoreBridge *bridge = [ZXCoreBridge sharedBridge];
        bridge.uiController = zentraxVC;
        zentraxVC.delegate = bridge;

        UINavigationController *navController =
            [[UINavigationController alloc] initWithRootViewController:zentraxVC];
        if (!navController) {
            NSLog(@"[Zentrax VIP] Failed to create navigation controller.");
            return;
        }

        navController.navigationBarHidden = YES;
        navController.modalPresentationStyle = UIModalPresentationFullScreen;

        /*
         * The window is already owned and managed by Filza.  We only replace
         * its root controller after launch; we never intercept or replace
         * UIWindow's makeKeyAndVisible implementation.
         */
        window.rootViewController = navController;

        if (!window.isKeyWindow || window.hidden) {
            [window makeKeyAndVisible];
        }
    });
}

@end

#pragma mark - ================= HOOK INSTALLATION =================

static void installSystemHooks(void) {
    Class rfm = NSClassFromString(@"TGRootFileManager");
    if (rfm) {
        Class meta = object_getClass(rfm);
        class_replaceMethod(meta, NSSelectorFromString(@"isRootHelperAvailable"), (IMP)hook_isRootHelperAvailable, "B@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"spawnRootHelper"), (IMP)hook_spawnRootHelper, "i@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"spawnRootHelperIfNeeds"), (IMP)hook_spawnRootHelperIfNeeds, "i@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"respawnRootHelper"), (IMP)hook_respawnRootHelper, "i@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"tryLoadFilzaHelper"), (IMP)hook_tryLoadFilzaHelper, "v@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"createHelperConnectionIfNeeds"), (IMP)hook_createHelperConnectionIfNeeds, "v@:");
        class_replaceMethod(rfm, NSSelectorFromString(@"spawnRoot:args:pid:"), (IMP)hook_spawnRoot_args_pid, "i@:@@^i");
        class_replaceMethod(rfm, NSSelectorFromString(@"sendObjectWithReplySync:"), (IMP)hook_sendObjectWithReplySync, "@@:@");
        class_replaceMethod(rfm, NSSelectorFromString(@"sendObjectWithReplySync:fileDescriptor:"), (IMP)hook_sendObjectWithReplySync_fd, "@@:@^i");
        class_replaceMethod(rfm, NSSelectorFromString(@"sendObjectWithReplySync:fileDescriptor:logintty:"), (IMP)hook_sendObjectWithReplySync_fd_logintty, "@@:@^iB");
        class_replaceMethod(rfm, NSSelectorFromString(@"sendObjectNoReply:"), (IMP)hook_sendObjectNoReply, "v@:@");
        class_replaceMethod(rfm, NSSelectorFromString(@"sendObjectWithReplyAsync:queue:completion:"), (IMP)hook_sendObjectWithReplyAsync, "v@:@@?");
    }

    Class alertCtrl = NSClassFromString(@"TGAlertController");
    if (alertCtrl) {
        Class alertMeta = object_getClass(alertCtrl);
        Method m = class_getClassMethod(alertCtrl, NSSelectorFromString(@"showAlertWithTitle:text:cancelButton:otherButtons:completion:"));
        if (m) {
            orig_showAlert = method_getImplementation(m);
            class_replaceMethod(alertMeta, NSSelectorFromString(@"showAlertWithTitle:text:cancelButton:otherButtons:completion:"),
                (IMP)hook_showAlertWithTitle, "@@:@@@@@");
        }
    }

    Class activationVC = NSClassFromString(@"NewActivationViewController");
    if (activationVC) {
        Method m = class_getInstanceMethod(activationVC, @selector(viewDidLoad));
        if (m) {
            orig_activationViewDidLoad = method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_activationViewDidLoad);
        }
    }

    Class lsWorkspace = NSClassFromString(@"LSApplicationWorkspace");
    if (lsWorkspace) {
        Method m = class_getInstanceMethod(lsWorkspace, NSSelectorFromString(@"allApplications"));
        if (m) {
            orig_allApplications = method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_allApplications);
        }
    }

    Class appItem = NSClassFromString(@"ApplicationItem");
    if (appItem) {
        Method m = class_getInstanceMethod(appItem, NSSelectorFromString(@"setAppProxy:"));
        if (m) {
            orig_setAppProxy = method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_setAppProxy);
        }
    }

    /*
     * DO NOT hook UIWindow::makeKeyAndVisible here.
     * Filza's original UIKit window lifecycle must remain untouched.
     */
}

__attribute__((constructor)) void ZentraxInit(void) {
    installSystemHooks();

    /*
     * Register the launch coordinator only.  No UI, MCM, StateStore or
     * UIWindow work is performed from the dylib constructor.
     */
    [[ZXLaunchCoordinator sharedCoordinator] start];
}
