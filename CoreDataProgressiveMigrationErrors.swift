/**
 Error codes used in CoreDataProgressiveMigration classes
 */
let CoreDataMigrationErrorDomain = "CoreDataMigrationErrorDomain"

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
    case couldNotFindVersionFromWhichToStart = 492810
    case delegateFailedPreflight = 492811
    case delegateFailedPostflight = 492812
    case delegateSaidNo = 492813
}


