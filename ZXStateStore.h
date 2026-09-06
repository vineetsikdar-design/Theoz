//
//  ZXStateStore.h
//  Zentrax  VIP
//
//  Persistent local state / operation ledger.
//  This layer stores only client-side execution state.
//  Server authorization remains authoritative.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Target State

typedef NS_ENUM(NSInteger, ZXTargetLedgerState) {
    ZXTargetLedgerStateIdle = 0,
    ZXTargetLedgerStateStagingON,
    ZXTargetLedgerStateONInProgress,
    ZXTargetLedgerStateOFFInProgress,
    ZXTargetLedgerStateRestoring,
    ZXTargetLedgerStateSwitching,
    ZXTargetLedgerStateSwapping
};

#pragma mark - Backup State

typedef NS_ENUM(NSInteger, ZXBackupValidity) {
    ZXBackupValidityUnknown = 0,
    ZXBackupValidityValid,
    ZXBackupValidityInvalid,
    ZXBackupValidityMissing
};

#pragma mark - Operation State

typedef NS_ENUM(NSInteger, ZXLedgerOperationState) {
    ZXLedgerOperationStateNone = 0,
    ZXLedgerOperationStatePrepared,
    ZXLedgerOperationStateInProgress,
    ZXLedgerOperationStateCommitted,
    ZXLedgerOperationStateFailed,
    ZXLedgerOperationStateNeedsReconciliation
};

#pragma mark - Target Ledger Record

@interface ZXTargetLedgerRecord : NSObject <NSSecureCoding>

@property (nonatomic, copy) NSString *recordIdentifier;

/// Canonical target path used as the stable identity of this record.
@property (nonatomic, copy) NSString *canonicalTarget;

/// Function currently owning the target.
@property (nonatomic, copy, nullable) NSString *activeFunctionId;

/// Human-readable function name, if available.
@property (nonatomic, copy, nullable) NSString *activeFunctionName;

/// Hash of the currently active payload.
@property (nonatomic, copy, nullable) NSString *activePayloadHash;

/// Hash of the original file preserved in the backup.
@property (nonatomic, copy, nullable) NSString *originalBackupHash;

/// Original target size, when known.
@property (nonatomic, assign) long long originalBackupSize;

/// Active payload size, when known.
@property (nonatomic, assign) long long activePayloadSize;

/// Indicates whether an original backup is expected to exist.
@property (nonatomic, assign) BOOL hasOriginalBackup;

/// Indicates whether the preserved backup was verified.
@property (nonatomic, assign) ZXBackupValidity backupValidity;

/// Current local execution state.
@property (nonatomic, assign) ZXTargetLedgerState state;

/// Current operation state.
@property (nonatomic, assign) ZXLedgerOperationState operationState;

/// Last server-issued operation identifier.
@property (nonatomic, copy, nullable) NSString *operationId;

/// Server-issued action associated with the pending operation.
@property (nonatomic, copy, nullable) NSString *operationAction;

/// License identifier associated with the ledger record.
@property (nonatomic, copy, nullable) NSString *licenseId;

/// Device identifier associated with the ledger record.
@property (nonatomic, copy, nullable) NSString *deviceId;

/// Timestamp at which the record was first created.
@property (nonatomic, strong) NSDate *createdAt;

/// Timestamp of the most recent local modification.
@property (nonatomic, strong) NSDate *updatedAt;

/// Timestamp of the most recent successful reconciliation.
@property (nonatomic, strong, nullable) NSDate *lastReconciledAt;

/// Last known local filesystem hash of the target.
@property (nonatomic, copy, nullable) NSString *lastObservedTargetHash;

/// Last known local filesystem size of the target.
@property (nonatomic, assign) long long lastObservedTargetSize;

/// Whether the record requires recovery/reconciliation on next launch.
@property (nonatomic, assign) BOOL requiresReconciliation;

@end

#pragma mark - Store

@interface ZXStateStore : NSObject

+ (instancetype)sharedStore;

#pragma mark - Store Lifecycle

/**
 * Opens/initializes the persistent state store.
 *
 * The store must remain usable across application relaunches.
 */
- (BOOL)open:(NSError * _Nullable * _Nullable)error;

/**
 * Flushes pending state to persistent storage.
 */
- (BOOL)synchronize:(NSError * _Nullable * _Nullable)error;

/**
 * Removes transient state while preserving persistent records required
 * for safe reconciliation.
 */
- (void)clearTransientState;

#pragma mark - Target Records

/**
 * Returns the record associated with a canonical target.
 */
- (ZXTargetLedgerRecord * _Nullable)recordForTarget:(NSString *)canonicalTarget;

/**
 * Returns the record associated with a function.
 */
- (ZXTargetLedgerRecord * _Nullable)recordForFunctionId:(NSString *)functionId;

/**
 * Returns all persisted target records.
 */
- (NSArray<ZXTargetLedgerRecord *> *)allTargetRecords;

/**
 * Creates or updates a target record.
 */
- (BOOL)saveTargetRecord:(ZXTargetLedgerRecord *)record
                  error:(NSError * _Nullable * _Nullable)error;

/**
 * Removes a target record only when it is safe to remove.
 *
 * The implementation must not silently delete a record that is still
 * required to restore or reconcile a target.
 */
- (BOOL)removeTargetRecordForTarget:(NSString *)canonicalTarget
                              error:(NSError * _Nullable * _Nullable)error;

#pragma mark - State Transitions

/**
 * Updates the local execution state of a target.
 */
- (BOOL)setState:(ZXTargetLedgerState)state
       forTarget:(NSString *)canonicalTarget
           error:(NSError * _Nullable * _Nullable)error;

/**
 * Updates the operation state of a target.
 */
- (BOOL)setOperationState:(ZXLedgerOperationState)operationState
                forTarget:(NSString *)canonicalTarget
                    error:(NSError * _Nullable * _Nullable)error;

/**
 * Marks a target as requiring reconciliation.
 */
- (BOOL)markTargetForReconciliation:(NSString *)canonicalTarget
                              error:(NSError * _Nullable * _Nullable)error;

/**
 * Marks a target as successfully reconciled.
 */
- (BOOL)markTargetReconciled:(NSString *)canonicalTarget
                       error:(NSError * _Nullable * _Nullable)error;

/**
 * Sets the reconciliation flag directly.
 * This is the convenience form used by the module transaction layer.
 */
- (BOOL)markTarget:(NSString *)canonicalTarget
requiresReconciliation:(BOOL)requiresReconciliation
            error:(NSError * _Nullable * _Nullable)error;

#pragma mark - Backup Ownership

/**
 * Records ownership of the currently active target.
 *
 * This is used when switching between functions that share the same
 * target. Existing original backups must never be overwritten merely
 * because another function becomes active.
 */
- (BOOL)setActiveFunctionId:(NSString * _Nullable)functionId
                    functionName:(NSString * _Nullable)functionName
                       payloadHash:(NSString * _Nullable)payloadHash
                         payloadSize:(long long)payloadSize
                           forTarget:(NSString *)canonicalTarget
                              error:(NSError * _Nullable * _Nullable)error;

/**
 * Records the original backup metadata.
 */
- (BOOL)setOriginalBackupHash:(NSString * _Nullable)backupHash
                         size:(long long)size
                       exists:(BOOL)exists
                     validity:(ZXBackupValidity)validity
                    forTarget:(NSString *)canonicalTarget
                        error:(NSError * _Nullable * _Nullable)error;

/**
 * Updates the known backup validity.
 */
- (BOOL)setBackupValidity:(ZXBackupValidity)validity
                forTarget:(NSString *)canonicalTarget
                    error:(NSError * _Nullable * _Nullable)error;

#pragma mark - Server Operation Ledger

/**
 * Stores a server-issued operation before local execution starts.
 */
- (BOOL)beginOperationWithId:(NSString *)operationId
                      action:(NSString *)action
                   functionId:(NSString *)functionId
                      licenseId:(NSString * _Nullable)licenseId
                     deviceId:(NSString * _Nullable)deviceId
                       target:(NSString *)canonicalTarget
                        error:(NSError * _Nullable * _Nullable)error;

/**
 * Returns the currently pending operation for a target.
 */
- (ZXTargetLedgerRecord * _Nullable)pendingOperationForTarget:(NSString *)canonicalTarget;

/**
 * Returns the currently pending operation for a function.
 */
- (ZXTargetLedgerRecord * _Nullable)pendingOperationForFunctionId:(NSString *)functionId;

/**
 * Marks a server operation as committed after local verification.
 */
- (BOOL)commitOperationWithId:(NSString *)operationId
                    targetHash:(NSString * _Nullable)targetHash
                         size:(long long)size
                        error:(NSError * _Nullable * _Nullable)error;

/**
 * Marks an operation as failed and requiring reconciliation.
 */
- (BOOL)failOperationWithId:(NSString *)operationId
                       error:(NSError * _Nullable * _Nullable)error;

/**
 * Clears an operation only when its lifecycle has safely completed.
 */
- (BOOL)clearCompletedOperationWithId:(NSString *)operationId
                                error:(NSError * _Nullable * _Nullable)error;

#pragma mark - Reconciliation

/**
 * Returns all records that require reconciliation.
 */
- (NSArray<ZXTargetLedgerRecord *> *)recordsRequiringReconciliation;

/**
 * Performs local ledger consistency checks.
 *
 * This method only validates persistent state consistency. It does not
 * grant authorization and does not bypass server-side authorization.
 */
- (BOOL)validateLedger:(NSError * _Nullable * _Nullable)error;

/**
 * Marks every currently unresolved record for reconciliation.
 *
 * Intended for crash/relaunch recovery when the previous execution
 * cannot be proven to have completed.
 */
- (void)markUnresolvedRecordsForReconciliation;

#pragma mark - License / Session Association

/**
 * Returns records belonging to a specific license.
 */
- (NSArray<ZXTargetLedgerRecord *> *)recordsForLicenseId:(NSString *)licenseId;

/**
 * Associates a target record with a license and device.
 */
- (BOOL)associateTarget:(NSString *)canonicalTarget
              licenseId:(NSString * _Nullable)licenseId
               deviceId:(NSString * _Nullable)deviceId
                  error:(NSError * _Nullable * _Nullable)error;

/**
 * Removes only session/transient association data.
 *
 * Persistent target ownership information remains intact so that an
 * interrupted local operation can still be reconciled safely.
 */
- (BOOL)clearSessionAssociationForLicenseId:(NSString *)licenseId
                                      error:(NSError * _Nullable * _Nullable)error;

#pragma mark - Crash Recovery

/**
 * Indicates whether the store contains unresolved work from a previous
 * execution.
 */
@property (nonatomic, readonly) BOOL hasPendingRecovery;

/**
 * Returns the number of target records requiring reconciliation.
 */
@property (nonatomic, readonly) NSUInteger pendingRecoveryCount;

/**
 * Creates a persistent recovery checkpoint.
 */
- (BOOL)createRecoveryCheckpoint:(NSError * _Nullable * _Nullable)error;

/**
 * Clears the recovery checkpoint only after reconciliation succeeds.
 */
- (BOOL)clearRecoveryCheckpoint:(NSError * _Nullable * _Nullable)error;

#pragma mark - Safety

/**
 * Returns YES when a target currently has an active local owner.
 *
 * This is a local state check and must not be interpreted as server
 * authorization.
 */
- (BOOL)isTargetOwned:(NSString *)canonicalTarget;

/**
 * Returns YES when a target has a verified original backup.
 */
- (BOOL)hasValidOriginalBackup:(NSString *)canonicalTarget;

/**
 * Returns the active function identifier for a target.
 */
- (NSString * _Nullable)activeFunctionIdForTarget:(NSString *)canonicalTarget;

@end

NS_ASSUME_NONNULL_END
