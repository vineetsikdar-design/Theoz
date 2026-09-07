//
//  Tweak.m
//  Zentrax VIP - Core System Hooks & Execution Bridge
//
//  Createdd by Zentrax Team.
//  Status: PRODUCTION AUDITED (V8 - Jailed IPA Sandbox & Move-Delete Fallback)
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
#import "ZXStateStore.h"

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

@interface ZXCoreBridge : NSObject <ZentraxUIDelegate>
@property (nonatomic, weak) ZentraxUI *uiController;
@property (nonatomic, strong) dispatch_queue_t moduleExecutionQueue;
@property (nonatomic, strong) ZXStateStore *stateStore;
@property (nonatomic, strong) NSMutableSet<NSString *> *activeTargetOperations;
+ (instancetype)sharedBridge;
@end

@implementation ZXCoreBridge

- (ZXStateStore *)stateStore {
    if (!_stateStore) {
        @synchronized (self) {
            if (!_stateStore) {
                ZXStateStore *store = [ZXStateStore sharedStore];
                NSError *openError = nil;
                if (![store open:&openError]) {
                    NSLog(@"[Zentrax VIP] StateStore open deferred/failed: %@", openError);
                } else {
                    [store synchronize:nil];
                    [store markUnresolvedRecordsForReconciliation];
                }
                _stateStore = store;
            }
        }
    }
    return _stateStore;
}

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
        _activeTargetOperations = [NSMutableSet set];

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
        case ZXNetworkErrorNone: return ZXAuthErrorNone;
        case ZXNetworkErrorInvalidKey: return ZXAuthErrorInvalidKey;
        case ZXNetworkErrorExpiredKey: return ZXAuthErrorExpiredKey;
        case ZXNetworkErrorRevokedKey: return ZXAuthErrorRevokedKey;
        case ZXNetworkErrorDeviceLimit: return ZXAuthErrorDeviceLimit;
        case ZXNetworkErrorInvalidSession: return ZXAuthErrorInvalidSession;
        case ZXNetworkErrorConnection: return ZXAuthErrorConnection;
        case ZXNetworkErrorMaintenance: return ZXAuthErrorMaintenance;
        case ZXNetworkErrorVersionMismatch: return ZXAuthErrorVersionMismatch;
        case ZXNetworkErrorCompatibility: return ZXAuthErrorCompatibility;
        case ZXNetworkErrorRateLimited: return ZXAuthErrorRateLimited;
        default: return ZXAuthErrorServer;
    }
}

- (BOOL)responseContainsUsableDashboardConfiguration:(NSDictionary *)response {
    if (![response isKindOfClass:NSDictionary.class]) return NO;
    NSDictionary *configuration = nil;
    id nested = response[@"configuration"] ?: response[@"config"] ?: response[@"dashboard_data"];
    if ([nested isKindOfClass:NSDictionary.class]) {
        configuration = nested;
    } else {
        configuration = response;
    }
    NSArray *categories = [configuration[@"categories"] isKindOfClass:NSArray.class] ? configuration[@"categories"] : nil;
    NSArray *modules = [configuration[@"modules"] isKindOfClass:NSArray.class] ? configuration[@"modules"] : nil;
    NSArray *functions = [configuration[@"functions"] isKindOfClass:NSArray.class] ? configuration[@"functions"] : nil;

    return categories.count > 0 || modules.count > 0 || functions.count > 0;
}

- (NSDictionary *)dashboardConfigurationFromServerResponse:(NSDictionary *)response {
    if (![response isKindOfClass:NSDictionary.class]) return nil;
    id nested = response[@"configuration"] ?: response[@"config"] ?: response[@"dashboard_data"];
    if ([nested isKindOfClass:NSDictionary.class]) return nested;
    if ([response[@"categories"] isKindOfClass:NSArray.class] ||
        [response[@"modules"] isKindOfClass:NSArray.class] ||
        [response[@"functions"] isKindOfClass:NSArray.class]) {
        return response;
    }
    return nil;
}

- (NSDictionary *)licenseDictionaryFromServerResponse:(NSDictionary *)response {
    if (![response isKindOfClass:NSDictionary.class]) return nil;
    id license = response[@"license"];
    if ([license isKindOfClass:NSDictionary.class]) return license;
    id subscription = response[@"subscription"];
    if ([subscription isKindOfClass:NSDictionary.class]) return subscription;
    NSDictionary *configuration = [self dashboardConfigurationFromServerResponse:response];
    if ([configuration[@"license"] isKindOfClass:NSDictionary.class]) return configuration[@"license"];
    if ([configuration[@"subscription"] isKindOfClass:NSDictionary.class]) return configuration[@"subscription"];
    return nil;
}

- (NSDictionary *)compatibilityDictionaryFromServerResponse:(NSDictionary *)response {
    if (![response isKindOfClass:NSDictionary.class]) return nil;
    id compatibility = response[@"compatibility"];
    if ([compatibility isKindOfClass:NSDictionary.class]) return compatibility;
    id deviceCompatibility = response[@"device_compatibility"];
    if ([deviceCompatibility isKindOfClass:NSDictionary.class]) return deviceCompatibility;
    return nil;
}

- (void)applyServerResponseToUI:(NSDictionary *)response allowDashboard:(BOOL)allowDashboard {
    if (![response isKindOfClass:NSDictionary.class]) return;
    [self completeOnMain:^{
        if (!self.uiController) return;
        NSDictionary *configuration = [self dashboardConfigurationFromServerResponse:response];
        if (allowDashboard && configuration.count > 0 && [self responseContainsUsableDashboardConfiguration:response]) {
            [self.uiController updateDashboardWithConfiguration:configuration];
        }
        NSDictionary *license = [self licenseDictionaryFromServerResponse:response];
        if (license.count > 0) {
            [self.uiController updateSubscriptionState:license];
        }
        NSDictionary *compatibility = [self compatibilityDictionaryFromServerResponse:response];
        if (compatibility.count > 0) {
            [self.uiController updateDeviceCompatibility:compatibility];
        }
        id banner = response[@"banner"] ?: response[@"notice"];
        if ([banner isKindOfClass:NSDictionary.class]) {
            [self.uiController updateServerBanner:banner];
        }
    }];
}

#pragma mark - Authentication

- (void)zentraxDidRequestAuthenticationWithKey:(NSString *)key completion:(void(^)(BOOL success, ZXAuthError errorType, NSString * _Nullable errorMsg))completion {
    if (key.length == 0) {
        [self completeOnMain:^{ if (completion) completion(NO, ZXAuthErrorInvalidKey, @"Please enter a valid license key."); }];
        return;
    }

    [[ZentraxNetworkManager sharedManager] authenticateWithKey:key completion:^(BOOL success, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg) {
        ZXAuthError mappedError = [self mapNetworkErrorToAuthError:errorType];
        [self completeOnMain:^{
            if (!success || !responseData) {
                if (completion) completion(NO, mappedError, errorMsg.length ? errorMsg : @"Authentication failed.");
                return;
            }
            [self applyServerResponseToUI:responseData allowDashboard:YES];
            if (completion) completion(YES, ZXAuthErrorNone, nil);
        }];
    }];
}

- (void)zentraxDidRequestSessionVerificationWithCompletion:(void(^)(BOOL isValid))completion {
    ZentraxNetworkManager *network = [ZentraxNetworkManager sharedManager];
    if (![network hasActiveSession]) {
        [self completeOnMain:^{ if (completion) completion(NO); }];
        return;
    }

    [self.stateStore synchronize:nil];
    [self.stateStore validateLedger:nil];

    [network verifySessionWithCompletion:^(BOOL isValid, NSDictionary * _Nullable responseData, ZXNetworkErrorType errorType, NSString * _Nullable errorMsg) {
        [self completeOnMain:^{
            if (!isValid || !responseData) {
                if (completion) completion(NO);
                return;
            }
            [self applyServerResponseToUI:responseData allowDashboard:YES];
            if (completion) completion(YES);
        }];
    }];
}

#pragma mark - Operation Guard / Path Safety

- (BOOL)claimTargetOperation:(NSString *)target operationId:(NSString *)operationId {
    if (target.length == 0 || operationId.length == 0) return NO;
    @synchronized (self) {
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
    if ([filename hasPrefix:@"/"] || [filename hasPrefix:@"\\"] || [filename containsString:@"/"] || [filename containsString:@"\\"] || [filename isEqualToString:@"."] || [filename isEqualToString:@".."] || [filename containsString:@"\0"] || [filename containsString:@":"]) return NO;
    return YES;
}

- (NSString *)targetPathForContainer:(NSString *)container relativePath:(NSString *)relativePath filename:(NSString *)filename {
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

- (void)finishModuleFailure:(NSString *)message completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion {
    [self completeOnMain:^{
        if (completion) completion(NO, message.length ? message : @"The requested operation could not be completed.");
    }];
}

- (void)executeModulePayload:(NSDictionary *)modulePayload
                   functionId:(NSString *)functionId
                       action:(ZXModuleOperationAction)action
               requestedState:(BOOL)isOn
                    completion:(void(^)(BOOL success, NSString * _Nullable errorMsg))completion {

    if (![modulePayload isKindOfClass:NSDictionary.class]) {
        [self finishModuleFailure:@"Invalid module operation response." completion:completion];
        return;
    }

    NSString *operationId = [modulePayload[@"operation_id"] description];
    NSString *serverFunctionId = [modulePayload[@"function_id"] description];
    NSString *resolvedFunctionId = serverFunctionId.length ? serverFunctionId : functionId;

    // V8 FIX: Properly extract nested target configuration from module.php
    NSDictionary *targetDict = [modulePayload[@"target"] isKindOfClass:[NSDictionary class]] ? modulePayload[@"target"] : nil;
    NSString *target = targetDict ? [targetDict[@"canonical"] description] : [modulePayload[@"canonical_target"] description];
    NSString *bundleId = targetDict ? [targetDict[@"bundle_id"] description] : [modulePayload[@"bundle_id"] description];
    NSString *relativePath = targetDict ? [targetDict[@"relative_path"] description] : [modulePayload[@"relative_path"] description];
    NSString *targetFilename = targetDict ? [targetDict[@"target_filename"] description] : [modulePayload[@"target_filename"] description];

    if (operationId.length == 0 || resolvedFunctionId.length == 0 || target.length == 0) {
        [self finishModuleFailure:@"Invalid module operation contract received from server." completion:completion];
        return;
    }

    if (![self claimTargetOperation:target operationId:operationId]) {
        [self finishModuleFailure:@"Target busy. Please wait for the current operation to finish." completion:completion];
        return;
    }

    NSString *licenseId = [modulePayload[@"license_id"] description];
    NSString *deviceId = [modulePayload[@"device_id"] description];

    NSError *ledgerError = nil;
    NSString *actionString = (action == ZXModuleOperationActionON) ? @"ON" : @"OFF";

    BOOL began = [self.stateStore beginOperationWithId:operationId action:actionString functionId:resolvedFunctionId licenseId:licenseId deviceId:deviceId target:target error:&ledgerError];

    // Force reconciliation if DB is locked (Code 1502)
    if (!began && ledgerError.code == 1502) {
        ZXTargetLedgerRecord *staleRecord = [self.stateStore recordForTarget:target];
        if (staleRecord && staleRecord.operationId.length > 0) {
            [self.stateStore failOperationWithId:staleRecord.operationId error:nil];
        }
        [self.stateStore markTargetReconciled:target error:nil];
        
        ledgerError = nil;
        began = [self.stateStore beginOperationWithId:operationId action:actionString functionId:resolvedFunctionId licenseId:licenseId deviceId:deviceId target:target error:&ledgerError];
    }

    if (!began) {
        NSString *debugMsg = [NSString stringWithFormat:@"DB Init Error [%ld]: %@", (long)ledgerError.code, ledgerError.localizedDescription ?: @"Ledger initialization failed."];
        [self releaseTargetOperation:target];
        [self finishModuleFailure:debugMsg completion:completion];
        return;
    }

    // --- OFF RESTORE FLOW ---
    if (!isOn) {
        NSDictionary *restore = modulePayload[@"restore_contract"];
        NSString *mode = [restore[@"mode"] description];

        if (![mode isEqualToString:@"CLIENT_ORIGINAL_BACKUP"]) {
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:[NSString stringWithFormat:@"Invalid restore mode: %@", mode] completion:completion];
            return;
        }

        ZXTargetLedgerRecord *record = [self.stateStore recordForTarget:target];

        if (!record && bundleId.length == 0 && relativePath.length == 0 && targetFilename.length == 0) {
            [[ZentraxNetworkManager sharedManager] syncModuleStateForFunctionId:resolvedFunctionId state:NO operationId:operationId completion:^(BOOL syncSuccess, NSString * _Nullable syncErrorMsg) {
                if (syncSuccess) {
                    NSError *commitErr = nil;
                    BOOL committed = [self.stateStore commitOperationWithId:operationId targetHash:nil size:0 error:&commitErr];
                    if (!committed) {
                        [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
                        [self releaseTargetOperation:target];
                        [self finishModuleFailure:[NSString stringWithFormat:@"Commit Failed: %@", commitErr.localizedDescription] completion:completion];
                        return;
                    }
                    [self.stateStore clearCompletedOperationWithId:operationId error:nil];
                    [self releaseTargetOperation:target];
                    [self completeOnMain:^{ if (completion) completion(YES, nil); }];
                } else {
                    [self.stateStore failOperationWithId:operationId error:nil];
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:[NSString stringWithFormat:@"Sync Failed: %@", syncErrorMsg] completion:completion];
                }
            }];
            return;
        }

        if (!record || ![self isSafeRelativePath:relativePath filename:targetFilename] || bundleId.length == 0) {
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:[NSString stringWithFormat:@"Security validation failed for path: %@", targetFilename] completion:completion];
            return;
        }

        dispatch_async(self.moduleExecutionQueue, ^{
            NSString *dataContainer = findDataContainer(bundleId);
            if (!dataContainer) {
                [self.stateStore failOperationWithId:operationId error:nil];
                [self releaseTargetOperation:target];
                [self finishModuleFailure:[NSString stringWithFormat:@"Container not found for Bundle ID: %@", bundleId] completion:completion];
                return;
            }

            NSString *finalTargetPath = [self targetPathForContainer:dataContainer relativePath:relativePath filename:targetFilename];
            if (!finalTargetPath) {
                [self.stateStore failOperationWithId:operationId error:nil];
                [self releaseTargetOperation:target];
                [self finishModuleFailure:@"Resolved path failed security checks." completion:completion];
                return;
            }
            NSString *backupPath = [finalTargetPath stringByAppendingString:@".bak"];

            NSFileManager *fm = NSFileManager.defaultManager;
            NSError * __autoreleasing fsError = nil;
            BOOL success = YES;

            if ([fm fileExistsAtPath:backupPath]) {
                BOOL stateSet = [self.stateStore setState:ZXTargetLedgerStateRestoring forTarget:target error:&fsError];
                if (!stateSet) {
                    success = NO;
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:[NSString stringWithFormat:@"DB State Error: %@", fsError.localizedDescription] completion:completion];
                    return;
                } 
                
                if (!record.hasOriginalBackup || record.backupValidity != ZXBackupValidityValid) {
                    success = NO;
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:@"Backup metadata missing or invalid in DB." completion:completion];
                    return;
                } 
                
                NSUInteger backupSize = 0;
                NSString *backupHash = [self sha256OfFileAtPath:backupPath size:&backupSize];
                if (backupHash.length == 0 || (record.originalBackupHash.length && ![backupHash.lowercaseString isEqualToString:record.originalBackupHash.lowercaseString]) || (record.originalBackupSize > 0 && backupSize != record.originalBackupSize)) {
                    success = NO;
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:@"Backup file hash/size mismatch. Restore aborted." completion:completion];
                    return;
                }
                
                // V8 FIX: Safe replacement using Apple's replaceItemAtURL instead of explicit delete.
                NSURL *destURL = [NSURL fileURLWithPath:finalTargetPath];
                NSURL *srcURL = [NSURL fileURLWithPath:backupPath];
                NSURL *tempURL = nil;

                if ([fm fileExistsAtPath:finalTargetPath]) {
                    success = [fm replaceItemAtURL:destURL withItemAtURL:srcURL backupItemName:nil options:0 resultingItemURL:&tempURL error:&fsError];
                } else {
                    success = [fm moveItemAtPath:backupPath toPath:finalTargetPath error:&fsError];
                }
                
            } else if (record.activeFunctionId.length > 0 && [fm fileExistsAtPath:finalTargetPath]) {
                // V8 FIX: Server says DELETE_ACTIVE_TARGET, but we don't have delete permission.
                // Fallback: Move it to a .trash extension instead!
                BOOL stateSet = [self.stateStore setState:ZXTargetLedgerStateRestoring forTarget:target error:&fsError];
                if (!stateSet) {
                    success = NO;
                } else {
                    NSString *trashPath = [finalTargetPath stringByAppendingString:@".trash"];
                    [fm removeItemAtPath:trashPath error:nil]; // Clean old trash quietly
                    success = [fm moveItemAtPath:finalTargetPath toPath:trashPath error:&fsError];
                }
            }

            if (!success) {
                [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
                [self.stateStore failOperationWithId:operationId error:&fsError];
                [self releaseTargetOperation:target];
                [self finishModuleFailure:[NSString stringWithFormat:@"Recovery Action Failed: %@", fsError.localizedDescription] completion:completion];
                return;
            }

            BOOL activeCleared = [self.stateStore setActiveFunctionId:nil functionName:nil payloadHash:nil payloadSize:0 forTarget:target error:&fsError];
            BOOL stateIdled = [self.stateStore setState:ZXTargetLedgerStateIdle forTarget:target error:&fsError];

            if (!activeCleared || !stateIdled) {
                [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
                [self.stateStore failOperationWithId:operationId error:nil];
                [self releaseTargetOperation:target];
                [self finishModuleFailure:[NSString stringWithFormat:@"DB Sync Error: %@", fsError.localizedDescription] completion:completion];
                return;
            }

            [[ZentraxNetworkManager sharedManager] syncModuleStateForFunctionId:resolvedFunctionId state:NO operationId:operationId completion:^(BOOL syncSuccess, NSString * _Nullable syncErrorMsg) {
                if (!syncSuccess) {
                    [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
                    [self.stateStore failOperationWithId:operationId error:nil];
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:[NSString stringWithFormat:@"Server Sync Failed: %@", syncErrorMsg] completion:completion];
                    return;
                }

                NSError *commitErr = nil;
                BOOL committed = [self.stateStore commitOperationWithId:operationId targetHash:nil size:0 error:&commitErr];
                if (!committed) {
                    [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:[NSString stringWithFormat:@"DB Commit Failed: %@", commitErr.localizedDescription] completion:completion];
                    return;
                }

                [self.stateStore clearCompletedOperationWithId:operationId error:nil];
                [self.stateStore markTarget:target requiresReconciliation:NO error:nil];
                [self releaseTargetOperation:target];

                [self completeOnMain:^{ if (completion) completion(YES, nil); }];
            }];
        });

        return;
    }

    // --- ON WRITE FLOW ---
    
    // V8 FIX: Properly extract nested payload dict if server wrapped it
    NSDictionary *payloadDict = [modulePayload[@"payload"] isKindOfClass:[NSDictionary class]] ? modulePayload[@"payload"] : modulePayload;
    
    NSString *base64Data = [payloadDict[@"file_data"] description];
    NSString *declaredHash = [payloadDict[@"sha256"] description];
    NSUInteger declaredSize = [payloadDict[@"size"] unsignedIntegerValue];

    if (base64Data.length == 0 || bundleId.length == 0 || ![self isSafeRelativePath:relativePath filename:targetFilename]) {
        [self.stateStore failOperationWithId:operationId error:nil];
        [self releaseTargetOperation:target];
        [self finishModuleFailure:@"Invalid payload or target configuration." completion:completion];
        return;
    }

    NSData *fileData = [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!fileData.length) {
        [self.stateStore failOperationWithId:operationId error:nil];
        [self releaseTargetOperation:target];
        [self finishModuleFailure:@"Payload Base64 decoding failed." completion:completion];
        return;
    }

    NSString *computedHash = computeSHA256OfData(fileData);

    if (declaredHash.length == 0 || computedHash.length == 0 || declaredSize == 0 || declaredSize != fileData.length || ![declaredHash.lowercaseString isEqualToString:computedHash.lowercaseString]) {
        [self.stateStore failOperationWithId:operationId error:nil];
        [self releaseTargetOperation:target];
        [self finishModuleFailure:@"Payload SHA256 integrity verification failed." completion:completion];
        return;
    }

    dispatch_async(self.moduleExecutionQueue, ^{
        NSString *dataContainer = findDataContainer(bundleId);
        if (!dataContainer) {
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:[NSString stringWithFormat:@"App container not found for Bundle ID: %@", bundleId] completion:completion];
            return;
        }

        NSString *finalTargetPath = [self targetPathForContainer:dataContainer relativePath:relativePath filename:targetFilename];
        if (!finalTargetPath) {
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:@"Resolved path failed security validation." completion:completion];
            return;
        }
        NSString *backupPath = [finalTargetPath stringByAppendingString:@".bak"];

        NSFileManager *fm = NSFileManager.defaultManager;
        NSError * __autoreleasing fsError = nil;
        ZXTargetLedgerRecord *record = [self.stateStore recordForTarget:target];

        if (!record || !record.hasOriginalBackup) {
            if ([fm fileExistsAtPath:backupPath]) {
                [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
                [self.stateStore failOperationWithId:operationId error:nil];
                [self releaseTargetOperation:target];
                [self finishModuleFailure:@"A backup file exists but is unregistered. Aborting to prevent data loss." completion:completion];
                return;
            }

            if ([fm fileExistsAtPath:finalTargetPath] && ![fm fileExistsAtPath:backupPath]) {
                if (![fm copyItemAtPath:finalTargetPath toPath:backupPath error:&fsError]) {
                    [self.stateStore failOperationWithId:operationId error:&fsError];
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:[NSString stringWithFormat:@"Original file backup failed: %@", fsError.localizedDescription] completion:completion];
                    return;
                }

                NSData *originalData = [NSData dataWithContentsOfFile:backupPath];
                NSString *originalHash = computeSHA256OfData(originalData);

                if (originalHash.length == 0 || originalData.length == 0) {
                    [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
                    [self.stateStore failOperationWithId:operationId error:nil];
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:@"Original backup file hash generation failed." completion:completion];
                    return;
                }

                BOOL backupSet = [self.stateStore setOriginalBackupHash:originalHash size:originalData.length exists:YES validity:ZXBackupValidityValid forTarget:target error:&fsError];
                if (!backupSet) {
                    [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
                    [self.stateStore failOperationWithId:operationId error:nil];
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:[NSString stringWithFormat:@"DB Backup Register Failed: %@", fsError.localizedDescription] completion:completion];
                    return;
                }
            } else if (![fm fileExistsAtPath:backupPath]) {
                BOOL backupSet = [self.stateStore setOriginalBackupHash:nil size:0 exists:NO validity:ZXBackupValidityMissing forTarget:target error:&fsError];
                if (!backupSet) {
                    [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
                    [self.stateStore failOperationWithId:operationId error:nil];
                    [self releaseTargetOperation:target];
                    [self finishModuleFailure:[NSString stringWithFormat:@"DB Backup Missing Reg Failed: %@", fsError.localizedDescription] completion:completion];
                    return;
                }
            }
        }

        BOOL stateSet = [self.stateStore setState:record.activeFunctionId.length ? ZXTargetLedgerStateSwitching : ZXTargetLedgerStateStagingON forTarget:target error:&fsError];
        if (!stateSet) {
            [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:[NSString stringWithFormat:@"DB Staging State Failed: %@", fsError.localizedDescription] completion:completion];
            return;
        }

        // NSDataWritingAtomic automatically creates a temp file and MOVES it over the target, bypassing delete restrictions!
        BOOL written = [fileData writeToFile:finalTargetPath options:NSDataWritingAtomic error:&fsError];
        if (!written) {
            [self.stateStore failOperationWithId:operationId error:&fsError];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:[NSString stringWithFormat:@"Payload Write Failed: %@", fsError.localizedDescription] completion:completion];
            return;
        }

        NSData *writtenData = [NSData dataWithContentsOfFile:finalTargetPath];
        NSString *writtenHash = computeSHA256OfData(writtenData);

        if (!writtenData || writtenData.length != fileData.length || ![writtenHash.lowercaseString isEqualToString:computedHash.lowercaseString]) {
            [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:@"Post-write payload verification failed on disk." completion:completion];
            return;
        }

        BOOL inProgSet = [self.stateStore setState:ZXTargetLedgerStateONInProgress forTarget:target error:&fsError];
        BOOL activeSet = [self.stateStore setActiveFunctionId:resolvedFunctionId functionName:[modulePayload[@"function_name"] description] payloadHash:writtenHash payloadSize:writtenData.length forTarget:target error:&fsError];
                                                        
        if (!inProgSet || !activeSet) {
            [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
            [self.stateStore failOperationWithId:operationId error:nil];
            [self releaseTargetOperation:target];
            [self finishModuleFailure:[NSString stringWithFormat:@"DB Active Reg Failed: %@", fsError.localizedDescription] completion:completion];
            return;
        }

        [[ZentraxNetworkManager sharedManager] syncModuleStateForFunctionId:resolvedFunctionId state:YES operationId:operationId completion:^(BOOL syncSuccess, NSString * _Nullable syncErrorMsg) {
            if (!syncSuccess) {
                [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
                [self.stateStore failOperationWithId:operationId error:nil];
                [self releaseTargetOperation:target];
                [self finishModuleFailure:[NSString stringWithFormat:@"Server Sync Failed: %@", syncErrorMsg] completion:completion];
                return;
            }

            NSError *commitErr = nil;
            BOOL idledSet = [self.stateStore setState:ZXTargetLedgerStateIdle forTarget:target error:&commitErr];
            BOOL committed = [self.stateStore commitOperationWithId:operationId targetHash:writtenHash size:writtenData.length error:&commitErr];
                                                              
            if (!idledSet || !committed) {
                [self.stateStore markTarget:target requiresReconciliation:YES error:nil];
                [self releaseTargetOperation:target];
                [self finishModuleFailure:[NSString stringWithFormat:@"DB Commit Failed: %@", commitErr.localizedDescription] completion:completion];
                return;
            }

            [self.stateStore clearCompletedOperationWithId:operationId error:nil];
            [self.stateStore markTarget:target requiresReconciliation:NO error:nil];
            [self releaseTargetOperation:target];

            [self completeOnMain:^{ if (completion) completion(YES, nil); }];
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

#pragma mark - Device Compatibility

- (void)zentraxDidRequestCompatibilityRecheckWithCompletion:(void(^)(BOOL success,
                                                                       NSDictionary * _Nullable compatibility,
                                                                       NSString * _Nullable errorMsg))completion {
    if (!completion) return;

    ZentraxNetworkManager *network = [ZentraxNetworkManager sharedManager];
    [network checkDeviceCompatibilityWithCompletion:^(BOOL success,
                                                      NSDictionary * _Nullable compatibility,
                                                      ZXDeviceCompatibilityStatus status,
                                                      NSString * _Nullable errorMsg) {
        NSDictionary *safeCompatibility =
            [compatibility isKindOfClass:NSDictionary.class] ? compatibility : @{};

        [self completeOnMain:^{
            if (success) {
                [self.uiController updateDeviceCompatibility:safeCompatibility];
                completion(YES, safeCompatibility, nil);
                return;
            }

            /* Preserve the last known compatibility result when the network
             * check is temporarily unavailable. Do not manufacture support. */
            NSDictionary *cached = [network cachedCompatibilityData];
            if (cached.count > 0) {
                [self.uiController updateDeviceCompatibility:cached];
            }

            NSString *message = errorMsg.length
                ? errorMsg
                : (status == ZXDeviceCompatibilityStatusUnsupported
                   ? @"This device is not supported."
                   : @"Unable to verify device compatibility right now.");
            completion(NO, safeCompatibility.count ? safeCompatibility : cached, message);
        }];
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

#pragma mark - ================= ZENTRAX UI BOOTLOADER =================

static IMP orig_UIWindow_makeKeyAndVisible = NULL;
static BOOL ZXUIInstalled = NO;

static void ZXInstallUIBeforeVisibility(UIWindow *window) {
    if (ZXUIInstalled || !window) return;
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ZXInstallUIBeforeVisibility(window);
        });
        return;
    }

    Class uiClass = NSClassFromString(@"ZentraxUI");
    if (!uiClass) return;

    UIViewController *root = window.rootViewController;
    if ([root isKindOfClass:[UINavigationController class]]) {
        UIViewController *first = ((UINavigationController *)root).viewControllers.firstObject;
        if ([first isKindOfClass:uiClass]) {
            ZXUIInstalled = YES;
            return;
        }
    }
    if ([root isKindOfClass:uiClass]) {
        ZXUIInstalled = YES;
        return;
    }

    @try {
        /*
         * This is intentionally the original interception point used by the
         * working Filza integration.  Do NOT wait for UIWindowDidBecomeVisible
         * or UIApplicationDidBecomeActive: by then Filza has already rendered
         * its Documents dashboard.  The Zentrax controller must be installed
         * while Filza is still inside makeKeyAndVisible.
         */
        MCMFilzaStart();

        ZentraxUI *zentraxVC = [[uiClass alloc] init];
        if (!zentraxVC) return;

        ZXCoreBridge *bridge = [ZXCoreBridge sharedBridge];
        bridge.uiController = zentraxVC;
        zentraxVC.delegate = bridge;

        UINavigationController *navController =
            [[UINavigationController alloc] initWithRootViewController:zentraxVC];
        navController.navigationBarHidden = YES;
        navController.modalPresentationStyle = UIModalPresentationFullScreen;

        window.rootViewController = navController;
        ZXUIInstalled = YES;
    } @catch (NSException *exception) {
        NSLog(@"[Zentrax VIP] UI install exception: %@", exception);
        ZXUIInstalled = NO;
    }
}

static void hook_UIWindow_makeKeyAndVisible(UIWindow *self, SEL _cmd) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZXInstallUIBeforeVisibility(self);
    });

    /*
     * Keep Filza's original visibility/lifecycle call.  The only thing being
     * intercepted is the controller installed immediately before visibility.
     * This avoids both the Filza dashboard flash and the lifecycle break caused
     * by replacing the root from a later notification callback.
     */
    if (orig_UIWindow_makeKeyAndVisible) {
        ((void(*)(id, SEL))orig_UIWindow_makeKeyAndVisible)(self, _cmd);
    }
}

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
        if (m) { orig_allApplications = method_getImplementation(m); method_setImplementation(m, (IMP)hook_allApplications); }
    }
    Class appItem = NSClassFromString(@"ApplicationItem");
    if (appItem) {
        Method m = class_getInstanceMethod(appItem, NSSelectorFromString(@"setAppProxy:"));
        if (m) { orig_setAppProxy = method_getImplementation(m); method_setImplementation(m, (IMP)hook_setAppProxy); }
    }

    Class windowClass = NSClassFromString(@"UIWindow");
    if (windowClass) {
        Method m = class_getInstanceMethod(windowClass, @selector(makeKeyAndVisible));
        if (m) {
            orig_UIWindow_makeKeyAndVisible = method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_UIWindow_makeKeyAndVisible);
        }
    }
}

__attribute__((constructor)) void ZentraxInit(void) {
    installSystemHooks();
}
