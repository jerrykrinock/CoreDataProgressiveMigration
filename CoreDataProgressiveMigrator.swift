import Foundation
import CoreData

enum CoreDataProgressiveMigratorError : Error {
    case noVersionNamesFound
    case noStartingIndexEeeek
    case cannotFindModelInBundle
    case cannotLoadModelInBundle
    case cannotGetStoreMetadata(underlyingError: Error)
    case migrationStepFailed(underlyingError: Error)
    case shouldNeverHappen1
    case couldNotGetMappingModel
    case couldNotMakeDestinModel
    case couldNotFindVersionFromWhichToStart
}

/**
 The top level class for Core Data progressive migrations
 */
class CoreDataProgressiveMigrator : NSObject {
    private var storeUrl: URL
    private var storeType: String
    private var momdName: String

    @objc
    public init(storeUrl: URL, storeType: String = NSSQLiteStoreType, momdName: String) {
        self.storeType = storeType
        self.storeUrl = storeUrl
        self.momdName = momdName
    }
    
    /**
     "Main" function called to do the work.
     
     This function is synchronous; blocks until migration is complete or fails.
     */
    public func migrateStoreIfNeeded() throws -> [String]? {
        do {
            var hacker = CoreDataVersionHacker()
            let allVersionNames = try hacker.availableVersionNames(momdName: self.momdName)
            let migrator = CoreDataProgressiveMigratorGuts.init(storeUrl: storeUrl,
                                                                storeType: self.storeType,
                                                                momdName: self.momdName,
                                                                versionNames: allVersionNames)
            
            guard let currentVersion = allVersionNames.last else {
                throw CoreDataProgressiveMigratorError.noVersionNamesFound as NSError
            }
            
            let startingVersion = try migrator.startingVersion()                
            if (startingVersion != currentVersion) {
                /* In William Boles' example, tHe following do+catch was
                 wrapped in DispatchQueue.global(qos: .userInitiated).async {...}
                 but we saw no need for that and want to return synchronously. */
                do {
                    guard let startingIndex = allVersionNames.firstIndex(of: startingVersion) else {
                        throw CoreDataProgressiveMigratorError.noStartingIndexEeeek
                    }
                    var relevantVersionNames = Array(allVersionNames[startingIndex...])
                    try migrator.migrate(thruVersions: relevantVersionNames)
                    relevantVersionNames.removeLast()
                    return relevantVersionNames
                } catch {
                    throw error as NSError
                }
            } else {
                return nil
            }
        } catch {
            throw error as NSError
        }
    }

    /**
     Inner Objective-C wrapper around migrateStoreIfNeeded()

     It seems that returning more than one value from Swift to Objective-C
     is quite a chore!

     - returns: A dictionary containing values for keys "migratedVersions"
     and "error".  If either are internally nil, the values in this
     dictionary are an empty array and a NSNulll, respectively.
     */
    @objc
    func migrateStoreIfNeededObjC() -> ([String : AnyObject]) {
        var migratedVersions: [String] = []
        var nsError: AnyObject = NSNull()
        do {
            migratedVersions = try migrateStoreIfNeeded() ?? []
        } catch {
            nsError = error as NSError
        }

        return ["migratedVersions" : migratedVersions as AnyObject,
                 "error" : nsError] as [String : AnyObject]
    }

}
