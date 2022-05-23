/**
 Error codes used in CoreDataProgressiveMigration classes
 */
let CoreDataMigrationErrorDomain = "CoreDataMigrationErrorDomain"

class CoreDataProgressiveMigration : NSObject {
    @objc
    public static func doesErrorIndicateStoreCorrupt(_ error: NSError?) -> Bool {
        guard let error = error else {
            return false
        }
        if (error.domain != CoreDataMigrationErrorDomain) {
            return false
        }
        return (
            error.code == CoreDataProgressiveMigrationErrorCodes.noSourceVersion.rawValue
        ||
            error.code == CoreDataProgressiveMigrationErrorCodes.cannotGetStoreMetadata.rawValue
        )
    }

    @objc
    public static func doesErrorIndicateNoModelForStore(_ error: NSError?) -> Bool {
        guard let error = error else {
            return false
        }
        if (error.domain != CoreDataMigrationErrorDomain) {
            return false
        }
        return (
            error.code == CoreDataProgressiveMigrationErrorCodes.couldNotFindAMatchingDataModel.rawValue
        )
    }
}


@objc
enum CoreDataProgressiveMigrationErrorCodes : Int {
    case noVersionNamesFound = 492801
    case noStartingIndexEeeek = 492802
    case cannotFindModelInBundle = 492803
    case cannotLoadModelInBundle = 492804
    case cannotGetStoreMetadata = 492805
    case migrationStepFailed = 492806
    case noSourceVersion = 492807
    case couldNotGetMappingModel = 492808
    case couldNotMakeDestinModel = 492809
    case couldNotFindAMatchingDataModel = 492810
    case delegateFailedPreflight = 492811
    case delegateFailedPostflight = 492812
    case delegateSaidNo = 492813
}


