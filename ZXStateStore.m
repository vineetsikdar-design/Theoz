//
//  ZXStateStore.m
//  ZENTRAX
//
//  Persistent target-operation ledger.
//  Responsibilities:
//  - Crash/relaunch-safe metadata persistence
//  - Target ownership tracking
//  - Original-backup metadata tracking
//  - Operation transaction state
//  - Recovery checkpoints
//  - Session/license association
//  - Ledger validation/reconciliation flags
//
//  IMPORTANT:
//  This class intentionally does NOT perform filesystem modification.
//  Actual target/file operations belong to the operation layer.
//

#import "ZXStateStore.h"

#import <Foundation/Foundation.h>

#pragma mark - Private Constants

static NSString * const ZXStateStoreDirectoryName = @"Zentrax";
static NSString * const ZXStateStoreFileName = @"state-ledger.archive";
static NSString * const ZXStateStoreCheckpointFileName = @"recovery-checkpoint.archive";

static NSString * const ZXStateStoreSchemaVersionKey = @"schema_version";
static NSInteger const ZXStateStoreCurrentSchemaVersion = 1;

#pragma mark - ZXTargetLedgerRecord

@interface ZXTargetLedgerRecord ()

@property (nonatomic, assign, readwrite) BOOL requiresReconciliation;

@end

@implementation ZXTargetLedgerRecord

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)init
{
    self = [super init];

    if (self) {
        _recordIdentifier = [[NSUUID UUID] UUIDString];

        _canonicalTarget = @"";
        _activeFunctionId = @"";
        _activeFunctionName = @"";
        _activePayloadHash = @"";
        _originalBackupHash = @"";

        _originalBackupSize = 0;
        _activePayloadSize = 0;

        _hasOriginalBackup = NO;
        _backupValidity = ZXBackupValidityUnknown;

        _state = ZXTargetLedgerStateIdle;
        _operationState = ZXLedgerOperationStateNone;

        _operationId = @"";
        _operationAction = ZXModuleOperationActionUnknown;

        _licenseId = @"";
        _deviceId = @"";

        _createdAt = [NSDate date];
        _updatedAt = _createdAt;
        _lastReconciledAt = nil;

        _lastObservedTargetHash = @"";
        _lastObservedTargetSize = 0;

        _requiresReconciliation = NO;
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];

    if (!self) {
        return nil;
    }

    NSString *recordIdentifier =
        [coder decodeObjectOfClass:[NSString class]
                            forKey:@"recordIdentifier"];

    NSString *canonicalTarget =
        [coder decodeObjectOfClass:[NSString class]
                            forKey:@"canonicalTarget"];

    NSString *activeFunctionId =
        [coder decodeObjectOfClass:[NSString class]
                            forKey:@"activeFunctionId"];

    NSString *activeFunctionName =
        [coder decodeObjectOfClass:[NSString class]
                            forKey:@"activeFunctionName"];

    NSString *activePayloadHash =
        [coder decodeObjectOfClass:[NSString class]
                            forKey:@"activePayloadHash"];

    NSString *originalBackupHash =
        [coder decodeObjectOfClass:[NSString class]
                            forKey:@"originalBackupHash"];

    NSString *operationId =
        [coder decodeObjectOfClass:[NSString class]
                            forKey:@"operationId"];

    NSString *licenseId =
        [coder decodeObjectOfClass:[NSString class]
                            forKey:@"licenseId"];

    NSString *deviceId =
        [coder decodeObjectOfClass:[NSString class]
                            forKey:@"deviceId"];

    NSString *lastObservedTargetHash =
        [coder decodeObjectOfClass:[NSString class]
                            forKey:@"lastObservedTargetHash"];

    NSDate *createdAt =
        [coder decodeObjectOfClass:[NSDate class]
                            forKey:@"createdAt"];

    NSDate *updatedAt =
        [coder decodeObjectOfClass:[NSDate class]
                            forKey:@"updatedAt"];

    NSDate *lastReconciledAt =
        [coder decodeObjectOfClass:[NSDate class]
                            forKey:@"lastReconciledAt"];

    NSNumber *originalBackupSize =
        [coder decodeObjectOfClass:[NSNumber class]
                            forKey:@"originalBackupSize"];

    NSNumber *activePayloadSize =
        [coder decodeObjectOfClass:[NSNumber class]
                            forKey:@"activePayloadSize"];

    NSNumber *hasOriginalBackup =
        [coder decodeObjectOfClass:[NSNumber class]
                            forKey:@"hasOriginalBackup"];

    NSNumber *backupValidity =
        [coder decodeObjectOfClass:[NSNumber class]
                            forKey:@"backupValidity"];

    NSNumber *state =
        [coder decodeObjectOfClass:[NSNumber class]
                            forKey:@"state"];

    NSNumber *operationState =
        [coder decodeObjectOfClass:[NSNumber class]
                            forKey:@"operationState"];

    NSNumber *operationAction =
        [coder decodeObjectOfClass:[NSNumber class]
                            forKey:@"operationAction"];

    NSNumber *lastObservedTargetSize =
        [coder decodeObjectOfClass:[NSNumber class]
                            forKey:@"lastObservedTargetSize"];

    NSNumber *requiresReconciliation =
        [coder decodeObjectOfClass:[NSNumber class]
                            forKey:@"requiresReconciliation"];

    _recordIdentifier = recordIdentifier.length
        ? [recordIdentifier copy]
        : [[NSUUID UUID] UUIDString];

    _canonicalTarget = canonicalTarget.length
        ? [canonicalTarget copy]
        : @"";

    _activeFunctionId = activeFunctionId.length
        ? [activeFunctionId copy]
        : @"";

    _activeFunctionName = activeFunctionName.length
        ? [activeFunctionName copy]
        : @"";

    _activePayloadHash = activePayloadHash.length
        ? [activePayloadHash copy]
        : @"";

    _originalBackupHash = originalBackupHash.length
        ? [originalBackupHash copy]
        : @"";

    _operationId = operationId.length
        ? [operationId copy]
        : @"";

    _licenseId = licenseId.length
        ? [licenseId copy]
        : @"";

    _deviceId = deviceId.length
        ? [deviceId copy]
        : @"";

    _lastObservedTargetHash = lastObservedTargetHash.length
        ? [lastObservedTargetHash copy]
        : @"";

    _originalBackupSize = originalBackupSize
        ? originalBackupSize.unsignedLongLongValue
        : 0;

    _activePayloadSize = activePayloadSize
        ? activePayloadSize.unsignedLongLongValue
        : 0;

    _hasOriginalBackup = hasOriginalBackup.boolValue;

    _backupValidity = backupValidity
        ? (ZXBackupValidity)backupValidity.integerValue
        : ZXBackupValidityUnknown;

    _state = state
        ? (ZXTargetLedgerState)state.integerValue
        : ZXTargetLedgerStateIdle;

    _operationState = operationState
        ? (ZXLedgerOperationState)operationState.integerValue
        : ZXLedgerOperationStateNone;

    _operationAction = operationAction
        ? (ZXModuleOperationAction)operationAction.integerValue
        : ZXModuleOperationActionUnknown;

    _lastObservedTargetSize = lastObservedTargetSize
        ? lastObservedTargetSize.unsignedLongLongValue
        : 0;

    _requiresReconciliation = requiresReconciliation.boolValue;

    _createdAt = createdAt ?: [NSDate date];
    _updatedAt = updatedAt ?: _createdAt;
    _lastReconciledAt = lastReconciledAt;

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.recordIdentifier ?: @""
                 forKey:@"recordIdentifier"];

    [coder encodeObject:self.canonicalTarget ?: @""
                 forKey:@"canonicalTarget"];

    [coder encodeObject:self.activeFunctionId ?: @""
                 forKey:@"activeFunctionId"];

    [coder encodeObject:self.activeFunctionName ?: @""
                 forKey:@"activeFunctionName"];

    [coder encodeObject:self.activePayloadHash ?: @""
                 forKey:@"activePayloadHash"];

    [coder encodeObject:self.originalBackupHash ?: @""
                 forKey:@"originalBackupHash"];

    [coder encodeObject:@(self.originalBackupSize)
                 forKey:@"originalBackupSize"];

    [coder encodeObject:@(self.activePayloadSize)
                 forKey:@"activePayloadSize"];

    [coder encodeObject:@(self.hasOriginalBackup)
                 forKey:@"hasOriginalBackup"];

    [coder encodeObject:@(self.backupValidity)
                 forKey:@"backupValidity"];

    [coder encodeObject:@(self.state)
                 forKey:@"state"];

    [coder encodeObject:@(self.operationState)
                 forKey:@"operationState"];

    [coder encodeObject:self.operationId ?: @""
                 forKey:@"operationId"];

    [coder encodeObject:@(self.operationAction)
                 forKey:@"operationAction"];

    [coder encodeObject:self.licenseId ?: @""
                 forKey:@"licenseId"];

    [coder encodeObject:self.deviceId ?: @""
                 forKey:@"deviceId"];

    [coder encodeObject:self.createdAt ?: [NSDate date]
                 forKey:@"createdAt"];

    [coder encodeObject:self.updatedAt ?: [NSDate date]
                 forKey:@"updatedAt"];

    if (self.lastReconciledAt) {
        [coder encodeObject:self.lastReconciledAt
                     forKey:@"lastReconciledAt"];
    }

    [coder encodeObject:self.lastObservedTargetHash ?: @""
                 forKey:@"lastObservedTargetHash"];

    [coder encodeObject:@(self.lastObservedTargetSize)
                 forKey:@"lastObservedTargetSize"];

    [coder encodeObject:@(self.requiresReconciliation)
                 forKey:@"requiresReconciliation"];
}

@end

#pragma mark - ZXStateStore

@interface ZXStateStore ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, ZXTargetLedgerRecord *> *records;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *recoveryCheckpoint;

@property (nonatomic, copy) NSString *storageDirectory;
@property (nonatomic, copy) NSString *storageFilePath;
@property (nonatomic, copy) NSString *checkpointFilePath;

@property (nonatomic, assign) BOOL opened;

@end

@implementation ZXStateStore

#pragma mark Singleton

+ (instancetype)sharedStore
{
    static ZXStateStore *sharedStore = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedStore = [[self alloc] initPrivate];
    });

    return sharedStore;
}

- (instancetype)init
{
    return [ZXStateStore sharedStore];
}

- (instancetype)initPrivate
{
    self = [super init];

    if (self) {
        _records = [NSMutableDictionary dictionary];
        _recoveryCheckpoint = [NSMutableDictionary dictionary];
        _opened = NO;

        [self buildStoragePaths];
    }

    return self;
}

#pragma mark Storage Paths

- (void)buildStoragePaths
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSArray<NSURL *> *urls =
        [fileManager URLsForDirectory:NSApplicationSupportDirectory
                            inDomains:NSUserDomainMask];

    NSURL *baseURL = urls.firstObject;

    if (!baseURL) {
        baseURL =
            [NSURL fileURLWithPath:
                NSTemporaryDirectory()
                isDirectory:YES];
    }

    NSURL *directoryURL =
        [baseURL URLByAppendingPathComponent:ZXStateStoreDirectoryName
                                 isDirectory:YES];

    self.storageDirectory = directoryURL.path;

    self.storageFilePath =
        [[directoryURL URLByAppendingPathComponent:ZXStateStoreFileName]
            path];

    self.checkpointFilePath =
        [[directoryURL URLByAppendingPathComponent:
            ZXStateStoreCheckpointFileName]
            path];
}

- (BOOL)ensureStorageDirectory:(NSError **)error
{
    if (self.storageDirectory.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"ZXStateStore"
                                          code:1001
                                      userInfo:@{
                NSLocalizedDescriptionKey:
                    @"State store directory is unavailable."
            }];
        }

        return NO;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDirectory = NO;

    if ([fileManager fileExistsAtPath:self.storageDirectory
                          isDirectory:&isDirectory]) {
        if (isDirectory) {
            return YES;
        }

        if (error) {
            *error = [NSError errorWithDomain:@"ZXStateStore"
                                          code:1002
                                      userInfo:@{
                NSLocalizedDescriptionKey:
                    @"State store path is not a directory."
            }];
        }

        return NO;
    }

    BOOL created =
        [fileManager createDirectoryAtPath:self.storageDirectory
               withIntermediateDirectories:YES
                                attributes:@{
        NSFileProtectionKey:
            NSFileProtectionCompleteUntilFirstUserAuthentication
    }
                                     error:error];

    return created;
}

#pragma mark Open / Load

- (BOOL)open:(NSError **)error
{
    @synchronized (self) {
        if (self.opened) {
            return YES;
        }

        if (![self ensureStorageDirectory:error]) {
            return NO;
        }

        self.records = [NSMutableDictionary dictionary];
        self.recoveryCheckpoint = [NSMutableDictionary dictionary];

        if (![[NSFileManager defaultManager]
                fileExistsAtPath:self.storageFilePath]) {

            self.opened = YES;

            if (![self persistLocked:error]) {
                self.opened = NO;
                return NO;
            }
        } else {
            if (![self loadLocked:error]) {
                return NO;
            }
        }

        [self loadRecoveryCheckpointLocked:nil];

        self.opened = YES;

        return YES;
    }
}

- (BOOL)synchronize:(NSError **)error
{
    @synchronized (self) {
        if (!self.opened) {
            if (![self open:error]) {
                return NO;
            }
        }

        return [self persistLocked:error];
    }
}

- (void)clearTransientState
{
    @synchronized (self) {
        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if (record.operationState == ZXLedgerOperationStateCommitted) {
                record.operationId = @"";
                record.operationAction = ZXModuleOperationActionUnknown;
                record.operationState = ZXLedgerOperationStateNone;
                record.updatedAt = [NSDate date];
            }

            if (record.state == ZXTargetLedgerStateStagingON ||
                record.state == ZXTargetLedgerStateONInProgress ||
                record.state == ZXTargetLedgerStateOFFInProgress ||
                record.state == ZXTargetLedgerStateRestoring ||
                record.state == ZXTargetLedgerStateSwitching ||
                record.state == ZXTargetLedgerStateSwapping) {

                record.requiresReconciliation = YES;
                record.operationState =
                    ZXLedgerOperationStateNeedsReconciliation;

                record.updatedAt = [NSDate date];
            }
        }

        [self persistLocked:nil];
    }
}

#pragma mark Persistence

- (BOOL)loadLocked:(NSError **)error
{
    NSData *data =
        [NSData dataWithContentsOfFile:self.storageFilePath
                               options:NSDataReadingMappedIfSafe
                                 error:error];

    if (!data) {
        return NO;
    }

    NSError *unarchiveError = nil;

    NSSet *allowedClasses =
        [NSSet setWithObjects:
            [NSDictionary class],
            [NSMutableDictionary class],
            [NSString class],
            [NSNumber class],
            [NSDate class],
            [ZXTargetLedgerRecord class],
            [NSArray class],
            [NSMutableArray class],
            nil];

    NSDictionary *root =
        [NSKeyedUnarchiver unarchivedObjectOfClasses:allowedClasses
                                           fromData:data
                                              error:&unarchiveError];

    if (![root isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = unarchiveError ?: [NSError errorWithDomain:@"ZXStateStore"
                                                            code:1003
                                                        userInfo:@{
                NSLocalizedDescriptionKey:
                    @"State store archive is invalid."
            }];
        }

        return NO;
    }

    NSDictionary *storedRecords = root[@"records"];

    if ([storedRecords isKindOfClass:[NSDictionary class]]) {
        [storedRecords enumerateKeysAndObjectsUsingBlock:
            ^(id key, id obj, BOOL *stop) {

            if (![key isKindOfClass:[NSString class]]) {
                return;
            }

            if (![obj isKindOfClass:[ZXTargetLedgerRecord class]]) {
                return;
            }

            ZXTargetLedgerRecord *record =
                (ZXTargetLedgerRecord *)obj;

            if (record.canonicalTarget.length == 0) {
                return;
            }

            self.records[key] = record;
        }];
    }

    return YES;
}

- (BOOL)persistLocked:(NSError **)error
{
    if (![self ensureStorageDirectory:error]) {
        return NO;
    }

    NSDictionary *root = @{
        ZXStateStoreSchemaVersionKey:
            @(ZXStateStoreCurrentSchemaVersion),

        @"records":
            [self.records copy],

        @"saved_at":
            [NSDate date]
    };

    NSError *archiveError = nil;

    NSData *data =
        [NSKeyedArchiver archivedDataWithRootObject:root
                               requiringSecureCoding:YES
                                               error:&archiveError];

    if (!data) {
        if (error) {
            *error = archiveError;
        }

        return NO;
    }

    NSString *temporaryPath =
        [self.storageFilePath stringByAppendingString:@".tmp"];

    BOOL wrote =
        [data writeToFile:temporaryPath
                  options:NSDataWritingAtomic
                    error:error];

    if (!wrote) {
        return NO;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSError *replaceError = nil;

    if ([fileManager fileExistsAtPath:self.storageFilePath]) {
        NSURL *destinationURL =
            [NSURL fileURLWithPath:self.storageFilePath];

        NSURL *temporaryURL =
            [NSURL fileURLWithPath:temporaryPath];

        BOOL replaced =
            [fileManager replaceItemAtURL:destinationURL
                             withItemAtURL:temporaryURL
                            backupItemName:nil
                                   options:0
                          resultingItemURL:nil
                                     error:&replaceError];

        if (!replaced) {
            [fileManager removeItemAtPath:temporaryPath
                                    error:nil];

            if (error) {
                *error = replaceError;
            }

            return NO;
        }
    } else {
        BOOL moved =
            [fileManager moveItemAtPath:temporaryPath
                                 toPath:self.storageFilePath
                                  error:&replaceError];

        if (!moved) {
            [fileManager removeItemAtPath:temporaryPath
                                    error:nil];

            if (error) {
                *error = replaceError;
            }

            return NO;
        }
    }

    [fileManager setAttributes:@{
        NSFileProtectionKey:
            NSFileProtectionCompleteUntilFirstUserAuthentication
    }
                  ofItemAtPath:self.storageFilePath
                         error:nil];

    return YES;
}

#pragma mark Record Lookup

- (ZXTargetLedgerRecord *)recordForTarget:(NSString *)canonicalTarget
{
    @synchronized (self) {
        if (!self.opened) {
            [self open:nil];
        }

        if (canonicalTarget.length == 0) {
            return nil;
        }

        return self.records[canonicalTarget];
    }
}

- (ZXTargetLedgerRecord *)recordForFunctionId:(NSString *)functionId
{
    @synchronized (self) {
        if (!self.opened) {
            [self open:nil];
        }

        if (functionId.length == 0) {
            return nil;
        }

        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if ([record.activeFunctionId isEqualToString:functionId]) {
                return record;
            }
        }

        return nil;
    }
}

- (NSArray<ZXTargetLedgerRecord *> *)allTargetRecords
{
    @synchronized (self) {
        if (!self.opened) {
            [self open:nil];
        }

        return [self.records.allValues copy];
    }
}

#pragma mark Save / Remove

- (BOOL)saveRecord:(ZXTargetLedgerRecord *)record
             error:(NSError **)error
{
    @synchronized (self) {
        if (!self.opened && ![self open:error]) {
            return NO;
        }

        if (!record) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1101
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Cannot save a nil ledger record."
                }];
            }

            return NO;
        }

        if (record.recordIdentifier.length == 0) {
            record.recordIdentifier =
                [[NSUUID UUID] UUIDString];
        }

        if (record.canonicalTarget.length == 0) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1102
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Ledger record has no canonical target."
                }];
            }

            return NO;
        }

        if (!record.createdAt) {
            record.createdAt = [NSDate date];
        }

        record.updatedAt = [NSDate date];

        self.records[record.canonicalTarget] = record;

        if (![self persistLocked:error]) {
            [self.records removeObjectForKey:record.canonicalTarget];
            return NO;
        }

        return YES;
    }
}

- (BOOL)removeRecordForTarget:(NSString *)canonicalTarget
                        error:(NSError **)error
{
    @synchronized (self) {
        if (!self.opened && ![self open:error]) {
            return NO;
        }

        ZXTargetLedgerRecord *record =
            self.records[canonicalTarget];

        if (!record) {
            return YES;
        }

        if (record.operationState == ZXLedgerOperationStateInProgress ||
            record.operationState == ZXLedgerOperationStatePrepared ||
            record.requiresReconciliation) {

            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1103
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Cannot remove a ledger record with pending recovery."
                }];
            }

            return NO;
        }

        [self.records removeObjectForKey:canonicalTarget];

        return [self persistLocked:error];
    }
}

#pragma mark State Updates

- (BOOL)setState:(ZXTargetLedgerState)state
       forTarget:(NSString *)canonicalTarget
           error:(NSError **)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1201
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Target ledger record does not exist."
                }];
            }

            return NO;
        }

        record.state = state;
        record.updatedAt = [NSDate date];

        return [self persistLocked:error];
    }
}

- (BOOL)setOperationState:(ZXLedgerOperationState)operationState
                forTarget:(NSString *)canonicalTarget
                    error:(NSError **)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1202
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Target ledger record does not exist."
                }];
            }

            return NO;
        }

        record.operationState = operationState;
        record.updatedAt = [NSDate date];

        if (operationState ==
            ZXLedgerOperationStateNeedsReconciliation) {

            record.requiresReconciliation = YES;
        }

        return [self persistLocked:error];
    }
}

- (BOOL)markRequiresReconciliationForTarget:(NSString *)canonicalTarget
                                      error:(NSError **)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1203
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Target ledger record does not exist."
                }];
            }

            return NO;
        }

        record.requiresReconciliation = YES;
        record.operationState =
            ZXLedgerOperationStateNeedsReconciliation;

        record.updatedAt = [NSDate date];

        return [self persistLocked:error];
    }
}

- (BOOL)markReconciledForTarget:(NSString *)canonicalTarget
                          error:(NSError **)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1204
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Target ledger record does not exist."
                }];
            }

            return NO;
        }

        record.requiresReconciliation = NO;
        record.operationState =
            ZXLedgerOperationStateNone;

        record.lastReconciledAt = [NSDate date];
        record.updatedAt = [NSDate date];

        return [self persistLocked:error];
    }
}

#pragma mark Active Function

- (BOOL)setActiveFunctionId:(NSString *)functionId
                 functionName:(NSString *)functionName
                  payloadHash:(NSString *)payloadHash
                  payloadSize:(NSUInteger)payloadSize
                    forTarget:(NSString *)canonicalTarget
                        error:(NSError **)error
{
    @synchronized (self) {
        if (!canonicalTarget.length) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1301
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Canonical target is required."
                }];
            }

            return NO;
        }

        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            record = [[ZXTargetLedgerRecord alloc] init];
            record.canonicalTarget = canonicalTarget;
            record.createdAt = [NSDate date];
        }

        record.activeFunctionId = functionId ?: @"";
        record.activeFunctionName = functionName ?: @"";
        record.activePayloadHash = payloadHash ?: @"";
        record.activePayloadSize = payloadSize;

        record.state =
            functionId.length
            ? ZXTargetLedgerStateIdle
            : ZXTargetLedgerStateIdle;

        record.updatedAt = [NSDate date];

        self.records[canonicalTarget] = record;

        return [self persistLocked:error];
    }
}

#pragma mark Original Backup

- (BOOL)setOriginalBackupHash:(NSString *)hash
                          size:(NSUInteger)size
                         exists:(BOOL)exists
                       validity:(ZXBackupValidity)validity
                      forTarget:(NSString *)canonicalTarget
                          error:(NSError **)error
{
    @synchronized (self) {
        if (!canonicalTarget.length) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1401
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Canonical target is required."
                }];
            }

            return NO;
        }

        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            record = [[ZXTargetLedgerRecord alloc] init];
            record.canonicalTarget = canonicalTarget;
            record.createdAt = [NSDate date];
        }

        record.originalBackupHash = hash ?: @"";
        record.originalBackupSize = size;
        record.hasOriginalBackup = exists;
        record.backupValidity = validity;
        record.updatedAt = [NSDate date];

        self.records[canonicalTarget] = record;

        return [self persistLocked:error];
    }
}

- (BOOL)setBackupValidity:(ZXBackupValidity)validity
                forTarget:(NSString *)canonicalTarget
                    error:(NSError **)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1402
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Target ledger record does not exist."
                }];
            }

            return NO;
        }

        record.backupValidity = validity;
        record.updatedAt = [NSDate date];

        if (validity == ZXBackupValidityInvalid) {
            record.requiresReconciliation = YES;
        }

        return [self persistLocked:error];
    }
}

#pragma mark Operations

- (BOOL)beginOperationWithId:(NSString *)operationId
                       action:(ZXModuleOperationAction)action
                   functionId:(NSString *)functionId
                    licenseId:(NSString *)licenseId
                     deviceId:(NSString *)deviceId
                       target:(NSString *)canonicalTarget
                        error:(NSError **)error
{
    @synchronized (self) {
        if (!operationId.length ||
            !canonicalTarget.length) {

            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1501
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Operation ID and target are required."
                }];
            }

            return NO;
        }

        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            record = [[ZXTargetLedgerRecord alloc] init];
            record.canonicalTarget = canonicalTarget;
            record.createdAt = [NSDate date];
        }

        if (record.operationState ==
                ZXLedgerOperationStateInProgress ||
            record.operationState ==
                ZXLedgerOperationStatePrepared) {

            if (![record.operationId isEqualToString:operationId]) {
                if (error) {
                    *error =
                        [NSError errorWithDomain:@"ZXStateStore"
                                             code:1502
                                         userInfo:@{
                        NSLocalizedDescriptionKey:
                            @"Another operation is already pending for this target."
                    }];
                }

                return NO;
            }
        }

        record.operationId = operationId;
        record.operationAction = action;

        if (functionId.length) {
            record.activeFunctionId = functionId;
        }

        if (licenseId.length) {
            record.licenseId = licenseId;
        }

        if (deviceId.length) {
            record.deviceId = deviceId;
        }

        record.operationState =
            ZXLedgerOperationStatePrepared;

        switch (action) {
            case ZXModuleOperationActionON:
                record.state =
                    ZXTargetLedgerStateStagingON;
                break;

            case ZXModuleOperationActionOFF:
                record.state =
                    ZXTargetLedgerStateOFFInProgress;
                break;

            default:
                record.state =
                    ZXTargetLedgerStateIdle;
                break;
        }

        record.updatedAt = [NSDate date];

        self.records[canonicalTarget] = record;

        return [self persistLocked:error];
    }
}

- (ZXTargetLedgerRecord *)pendingOperationForTarget:(NSString *)canonicalTarget
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            return nil;
        }

        if (record.operationState ==
                ZXLedgerOperationStatePrepared ||
            record.operationState ==
                ZXLedgerOperationStateInProgress ||
            record.operationState ==
                ZXLedgerOperationStateNeedsReconciliation) {

            return record;
        }

        return nil;
    }
}

- (ZXTargetLedgerRecord *)pendingOperationForFunctionId:(NSString *)functionId
{
    @synchronized (self) {
        if (!functionId.length) {
            return nil;
        }

        for (ZXTargetLedgerRecord *record in self.records.allValues) {
            if (![record.activeFunctionId
                    isEqualToString:functionId]) {
                continue;
            }

            if (record.operationState ==
                    ZXLedgerOperationStatePrepared ||
                record.operationState ==
                    ZXLedgerOperationStateInProgress ||
                record.operationState ==
                    ZXLedgerOperationStateNeedsReconciliation) {

                return record;
            }
        }

        return nil;
    }
}

- (BOOL)commitOperationWithId:(NSString *)operationId
                    targetHash:(NSString *)targetHash
                          size:(NSUInteger)size
                         error:(NSError **)error
{
    @synchronized (self) {
        if (!operationId.length) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1601
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Operation ID is required."
                }];
            }

            return NO;
        }

        ZXTargetLedgerRecord *record = nil;

        for (ZXTargetLedgerRecord *candidate
             in self.records.allValues) {

            if ([candidate.operationId
                    isEqualToString:operationId]) {

                record = candidate;
                break;
            }
        }

        if (!record) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1602
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Operation was not found."
                }];
            }

            return NO;
        }

        record.lastObservedTargetHash =
            targetHash ?: @"";

        record.lastObservedTargetSize =
            size;

        record.operationState =
            ZXLedgerOperationStateCommitted;

        record.requiresReconciliation = NO;
        record.lastReconciledAt = [NSDate date];
        record.updatedAt = [NSDate date];

        return [self persistLocked:error];
    }
}

- (BOOL)failOperationWithId:(NSString *)operationId
                      error:(NSError **)error
{
    @synchronized (self) {
        if (!operationId.length) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1603
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Operation ID is required."
                }];
            }

            return NO;
        }

        ZXTargetLedgerRecord *record = nil;

        for (ZXTargetLedgerRecord *candidate
             in self.records.allValues) {

            if ([candidate.operationId
                    isEqualToString:operationId]) {

                record = candidate;
                break;
            }
        }

        if (!record) {
            return YES;
        }

        record.operationState =
            ZXLedgerOperationStateNeedsReconciliation;

        record.requiresReconciliation = YES;
        record.updatedAt = [NSDate date];

        return [self persistLocked:error];
    }
}

- (BOOL)clearCompletedOperationWithId:(NSString *)operationId
                                error:(NSError **)error
{
    @synchronized (self) {
        if (!operationId.length) {
            return YES;
        }

        ZXTargetLedgerRecord *record = nil;

        for (ZXTargetLedgerRecord *candidate
             in self.records.allValues) {

            if ([candidate.operationId
                    isEqualToString:operationId]) {

                record = candidate;
                break;
            }
        }

        if (!record) {
            return YES;
        }

        if (record.operationState !=
            ZXLedgerOperationStateCommitted) {

            if (error) {
                *error = [NSError errorWithDomain:@"ZXStateStore"
                                              code:1604
                                          userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Only committed operations can be cleared."
                }];
            }

            return NO;
        }

        record.operationId = @"";
        record.operationAction =
            ZXModuleOperationActionUnknown;

        record.operationState =
            ZXLedgerOperationStateNone;

        record.state =
            ZXTargetLedgerStateIdle;

        record.updatedAt = [NSDate date];

        return [self persistLocked:error];
    }
}

#pragma mark Reconciliation

- (NSArray<ZXTargetLedgerRecord *> *)recordsRequiringReconciliation
{
    @synchronized (self) {
        NSMutableArray *result =
            [NSMutableArray array];

        for (ZXTargetLedgerRecord *record
             in self.records.allValues) {

            if (record.requiresReconciliation ||
                record.operationState ==
                    ZXLedgerOperationStateNeedsReconciliation ||
                record.state != ZXTargetLedgerStateIdle) {

                [result addObject:record];
            }
        }

        [result sortUsingComparator:
            ^NSComparisonResult(ZXTargetLedgerRecord *a,
                                ZXTargetLedgerRecord *b) {

            return [a.updatedAt compare:b.updatedAt];
        }];

        return [result copy];
    }
}

- (BOOL)validateLedger:(NSError **)error
{
    @synchronized (self) {
        if (!self.opened && ![self open:error]) {
            return NO;
        }

        NSMutableSet<NSString *> *targets =
            [NSMutableSet set];

        NSMutableSet<NSString *> *recordIds =
            [NSMutableSet set];

        for (ZXTargetLedgerRecord *record
             in self.records.allValues) {

            if (record.canonicalTarget.length == 0) {
                if (error) {
                    *error =
                        [NSError errorWithDomain:@"ZXStateStore"
                                             code:1701
                                         userInfo:@{
                        NSLocalizedDescriptionKey:
                            @"Ledger contains a record without a canonical target."
                    }];
                }

                return NO;
            }

            if ([targets containsObject:record.canonicalTarget]) {
                if (error) {
                    *error =
                        [NSError errorWithDomain:@"ZXStateStore"
                                             code:1702
                                         userInfo:@{
                        NSLocalizedDescriptionKey:
                            @"Duplicate canonical target detected."
                    }];
                }

                return NO;
            }

            [targets addObject:record.canonicalTarget];

            if (record.recordIdentifier.length == 0) {
                if (error) {
                    *error =
                        [NSError errorWithDomain:@"ZXStateStore"
                                             code:1703
                                         userInfo:@{
                        NSLocalizedDescriptionKey:
                            @"Ledger contains a record without an identifier."
                    }];
                }

                return NO;
            }

            if ([recordIds containsObject:record.recordIdentifier]) {
                if (error) {
                    *error =
                        [NSError errorWithDomain:@"ZXStateStore"
                                             code:1704
                                         userInfo:@{
                        NSLocalizedDescriptionKey:
                            @"Duplicate ledger record identifier detected."
                    }];
                }

                return NO;
            }

            [recordIds addObject:record.recordIdentifier];

            if (record.operationState ==
                    ZXLedgerOperationStatePrepared ||
                record.operationState ==
                    ZXLedgerOperationStateInProgress) {

                if (record.operationId.length == 0) {
                    if (error) {
                        *error =
                            [NSError errorWithDomain:@"ZXStateStore"
                                                 code:1705
                                             userInfo:@{
                            NSLocalizedDescriptionKey:
                                @"Pending operation has no operation ID."
                        }];
                    }

                    return NO;
                }
            }

            if (record.hasOriginalBackup &&
                record.originalBackupHash.length == 0 &&
                record.backupValidity == ZXBackupValidityValid) {

                if (error) {
                    *error =
                        [NSError errorWithDomain:@"ZXStateStore"
                                             code:1706
                                         userInfo:@{
                        NSLocalizedDescriptionKey:
                            @"Valid original backup is missing its hash."
                    }];
                }

                return NO;
            }

            if (record.activeFunctionId.length > 0 &&
                record.activePayloadHash.length == 0 &&
                record.state == ZXTargetLedgerStateIdle) {

                record.requiresReconciliation = YES;
            }
        }

        return YES;
    }
}

- (BOOL)markUnresolvedRecordsForReconciliation:(NSError **)error
{
    @synchronized (self) {
        BOOL changed = NO;

        for (ZXTargetLedgerRecord *record
             in self.records.allValues) {

            BOOL unresolved =
                record.operationState ==
                    ZXLedgerOperationStatePrepared ||
                record.operationState ==
                    ZXLedgerOperationStateInProgress ||
                record.operationState ==
                    ZXLedgerOperationStateNeedsReconciliation ||
                record.state != ZXTargetLedgerStateIdle;

            if (unresolved &&
                !record.requiresReconciliation) {

                record.requiresReconciliation = YES;
                record.operationState =
                    ZXLedgerOperationStateNeedsReconciliation;
                record.updatedAt = [NSDate date];

                changed = YES;
            }
        }

        if (!changed) {
            return YES;
        }

        return [self persistLocked:error];
    }
}

#pragma mark License Association

- (NSArray<ZXTargetLedgerRecord *> *)recordsForLicenseId:(NSString *)licenseId
{
    @synchronized (self) {
        if (!licenseId.length) {
            return @[];
        }

        NSMutableArray *result =
            [NSMutableArray array];

        for (ZXTargetLedgerRecord *record
             in self.records.allValues) {

            if ([record.licenseId
                    isEqualToString:licenseId]) {

                [result addObject:record];
            }
        }

        return [result copy];
    }
}

- (BOOL)associateTarget:(NSString *)canonicalTarget
              licenseId:(NSString *)licenseId
               deviceId:(NSString *)deviceId
                  error:(NSError **)error
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            if (error) {
                *error =
                    [NSError errorWithDomain:@"ZXStateStore"
                                         code:1801
                                     userInfo:@{
                    NSLocalizedDescriptionKey:
                        @"Target ledger record does not exist."
                }];
            }

            return NO;
        }

        record.licenseId = licenseId ?: @"";
        record.deviceId = deviceId ?: @"";
        record.updatedAt = [NSDate date];

        return [self persistLocked:error];
    }
}

- (BOOL)clearSessionAssociationForLicenseId:(NSString *)licenseId
                                      error:(NSError **)error
{
    @synchronized (self) {
        if (!licenseId.length) {
            return YES;
        }

        BOOL changed = NO;

        for (ZXTargetLedgerRecord *record
             in self.records.allValues) {

            if (![record.licenseId
                    isEqualToString:licenseId]) {

                continue;
            }

            record.licenseId = @"";
            record.deviceId = @"";
            record.updatedAt = [NSDate date];

            changed = YES;
        }

        if (!changed) {
            return YES;
        }

        return [self persistLocked:error];
    }
}

#pragma mark Recovery

- (BOOL)hasPendingRecovery
{
    @synchronized (self) {
        if (!self.opened) {
            [self open:nil];
        }

        for (ZXTargetLedgerRecord *record
             in self.records.allValues) {

            if (record.requiresReconciliation ||
                record.operationState ==
                    ZXLedgerOperationStatePrepared ||
                record.operationState ==
                    ZXLedgerOperationStateInProgress ||
                record.operationState ==
                    ZXLedgerOperationStateNeedsReconciliation) {

                return YES;
            }
        }

        return NO;
    }
}

- (NSUInteger)pendingRecoveryCount
{
    @synchronized (self) {
        if (!self.opened) {
            [self open:nil];
        }

        NSUInteger count = 0;

        for (ZXTargetLedgerRecord *record
             in self.records.allValues) {

            if (record.requiresReconciliation ||
                record.operationState ==
                    ZXLedgerOperationStatePrepared ||
                record.operationState ==
                    ZXLedgerOperationStateInProgress ||
                record.operationState ==
                    ZXLedgerOperationStateNeedsReconciliation) {

                count++;
            }
        }

        return count;
    }
}

- (BOOL)createRecoveryCheckpoint:(NSError **)error
{
    @synchronized (self) {
        if (!self.opened && ![self open:error]) {
            return NO;
        }

        NSMutableArray *pending =
            [NSMutableArray array];

        for (ZXTargetLedgerRecord *record
             in [self recordsRequiringReconciliation]) {

            NSDictionary *entry = @{
                @"record_identifier":
                    record.recordIdentifier ?: @"",

                @"target":
                    record.canonicalTarget ?: @"",

                @"function_id":
                    record.activeFunctionId ?: @"",

                @"payload_hash":
                    record.activePayloadHash ?: @"",

                @"original_backup_hash":
                    record.originalBackupHash ?: @"",

                @"operation_id":
                    record.operationId ?: @"",

                @"operation_action":
                    @(record.operationAction),

                @"state":
                    @(record.state),

                @"operation_state":
                    @(record.operationState),

                @"created_at":
                    record.createdAt ?: [NSDate date],

                @"updated_at":
                    record.updatedAt ?: [NSDate date]
            };

            [pending addObject:entry];
        }

        NSDictionary *checkpoint = @{
            @"schema_version":
                @(ZXStateStoreCurrentSchemaVersion),

            @"created_at":
                [NSDate date],

            @"pending":
                pending
        };

        NSError *archiveError = nil;

        NSData *data =
            [NSKeyedArchiver archivedDataWithRootObject:checkpoint
                               requiringSecureCoding:YES
                                               error:&archiveError];

        if (!data) {
            if (error) {
                *error = archiveError;
            }

            return NO;
        }

        BOOL written =
            [data writeToFile:self.checkpointFilePath
                      options:NSDataWritingAtomic
                        error:error];

        if (!written) {
            return NO;
        }

        self.recoveryCheckpoint =
            [checkpoint mutableCopy];

        return YES;
    }
}

- (BOOL)clearRecoveryCheckpoint:(NSError **)error
{
    @synchronized (self) {
        self.recoveryCheckpoint =
            [NSMutableDictionary dictionary];

        if (![[NSFileManager defaultManager]
                fileExistsAtPath:self.checkpointFilePath]) {

            return YES;
        }

        return [[NSFileManager defaultManager]
            removeItemAtPath:self.checkpointFilePath
                       error:error];
    }
}

- (BOOL)loadRecoveryCheckpointLocked:(NSError **)error
{
    if (![[NSFileManager defaultManager]
            fileExistsAtPath:self.checkpointFilePath]) {

        self.recoveryCheckpoint =
            [NSMutableDictionary dictionary];

        return YES;
    }

    NSData *data =
        [NSData dataWithContentsOfFile:self.checkpointFilePath
                               options:NSDataReadingMappedIfSafe
                                 error:error];

    if (!data) {
        return NO;
    }

    NSError *unarchiveError = nil;

    NSSet *allowedClasses =
        [NSSet setWithObjects:
            [NSDictionary class],
            [NSMutableDictionary class],
            [NSArray class],
            [NSMutableArray class],
            [NSString class],
            [NSNumber class],
            [NSDate class],
            nil];

    NSDictionary *checkpoint =
        [NSKeyedUnarchiver unarchivedObjectOfClasses:allowedClasses
                                           fromData:data
                                              error:&unarchiveError];

    if (![checkpoint isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = unarchiveError ?: [NSError errorWithDomain:@"ZXStateStore"
                                                            code:1901
                                                        userInfo:@{
                NSLocalizedDescriptionKey:
                    @"Recovery checkpoint is invalid."
            }];
        }

        return NO;
    }

    self.recoveryCheckpoint =
        [checkpoint mutableCopy];

    return YES;
}

#pragma mark Target Ownership

- (BOOL)isTargetOwned:(NSString *)canonicalTarget
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            return NO;
        }

        return record.activeFunctionId.length > 0 ||
               record.hasOriginalBackup;
    }
}

- (BOOL)hasValidOriginalBackup:(NSString *)canonicalTarget
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            return NO;
        }

        return record.hasOriginalBackup &&
               record.backupValidity == ZXBackupValidityValid &&
               record.originalBackupHash.length > 0;
    }
}

- (NSString *)activeFunctionIdForTarget:(NSString *)canonicalTarget
{
    @synchronized (self) {
        ZXTargetLedgerRecord *record =
            [self recordForTarget:canonicalTarget];

        if (!record) {
            return nil;
        }

        return record.activeFunctionId.length
            ? record.activeFunctionId
            : nil;
    }
}

@end
