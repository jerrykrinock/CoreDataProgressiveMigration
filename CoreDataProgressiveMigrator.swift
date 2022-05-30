import Foundation
import CoreData

/**
 The top level class for Core Data progressive migrations
 
 We did not mark this class @objc because a parameter of its init() method
 is CoreDataMigrationDelegate, and the shpuldMigrate() func in that
 protocol throws an error and returns a BOOL, which is not allowed in a
 @objc func, and we don't want to sacrifice that Swift nicety for Objective-C.
 */
class CoreDataProgressiveMigrator : NSObject {
    private var storeUrl: URL
    private var storeType: String
    private var momdName: String
    private var delegate: CoreDataMigrationDelegate?

    public init(storeUrl: URL, storeType: String = NSSQLiteStoreType, momdName: String, delegate: CoreDataMigrationDelegate? = nil) {
        self.storeType = storeType
        self.storeUrl = storeUrl
        self.momdName = momdName
        self.delegate = delegate
    }
    
    /**
     The function which you shall call to perform the migration
     
     This function retruns synchronously, blocking until all migration version
     steps are complete.  If desired, you can call it on a secondary thread
     and wrap it with a progress indicator.
     
     If no file exists at the store URL which this class has been initialized
     with, this function will throw a system error indicating such.  For
     example, in macOS 12, the error has domain NSCocoaErrorDomain and code
     260.  Note that this is in contrast to  the -migrate… method in my old
     Objective-C SSYPersistentMultiMigrator class which, in this case of no
     file, would return YES (success) with no error.
     */
    @discardableResult public func migrateStoreIfNeeded() throws -> [String]? {
       do {
            var hacker = CoreDataVersionHacker()
            let allVersionNames = try hacker.availableVersionNames(momdName: self.momdName)
            
            guard let currentVersion = allVersionNames.last else {
                throw NSError.init(
                    domain: CoreDataMigrationErrorDomain,
                    code: CoreDataProgressiveMigrationErrorCodes.noVersionNamesFound.rawValue,
                    localizedDescription: NSLocalizedString(
                        "No version names found to migrate user data",
                        comment: "error during migration of user's data to new version"),
                    localizedRecoverySuggestion: NSLocalizedString(
                        "Reinstall this application",
                        comment: "error during migration of user's data to new version"))
            }
            
            let startingVersion = try self.startingVersionfromAmong(allVersionNames)
            if (startingVersion != currentVersion) {
                var shouldMigrate = true
                if let myDelegate = self.delegate {
                    shouldMigrate = try myDelegate.shpuldMigrate(self.storeUrl)
                }
                if (shouldMigrate) {
                    let migrator = CoreDataProgressiveMigratorGuts.init(storeUrl: storeUrl,
                                                                        storeType: self.storeType,
                                                                        momdName: self.momdName,
                                                                        versionNames: allVersionNames)
                    /* In William Boles' example, tHe following do+catch was
                     wrapped in DispatchQueue.global(qos: .userInitiated).async {...}
                     but we saw no need for that and want to return synchronously. */
                    do {
                        guard let startingIndex = allVersionNames.firstIndex(of: startingVersion) else {
                            throw NSError.init(
                                domain: CoreDataMigrationErrorDomain,
                                code: CoreDataProgressiveMigrationErrorCodes.noStartingIndexEeeek.rawValue,
                                localizedDescription: NSLocalizedString(
                                    "No starting index found of versions to migrate user data",
                                    comment: "error during migration of user's data to new version"),
                                localizedRecoverySuggestion: NSLocalizedString(
                                    "Reinstall this application",
                                    comment: "error during migration of user's data to new version"))
                        }
                        var relevantVersionNames = Array(allVersionNames[startingIndex...])
                        try migrator.migrate(thruVersions: relevantVersionNames)
                        relevantVersionNames.removeLast()
                        return relevantVersionNames
                    } catch {
                        throw error as NSError
                    }
                } else {
                    throw NSError.init(
                        domain: CoreDataMigrationErrorDomain,
                        code: CoreDataProgressiveMigrationErrorCodes.delegateSaidNo.rawValue,
                        localizedDescription: NSLocalizedString(
                            "The delegate said 'no' to migrating this user data",
                            comment: "error during migration of user's data to new version"))
                }
            } else {
                /* Normal case when migration is not necessary */
                return nil
            }
        } catch {
            throw error as NSError
        }
    }
    
    public func startingVersionfromAmong(_ versionNames: [String]) throws -> String {
        var metadata: [String: Any]
        metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: self.storeType,
                                                                               at: self.storeUrl,
                                                                               options: nil)
        
        let bundle = Bundle.mainAppBundle()
        var startingVersion: String
        for aVersion in versionNames.reversed() {
            let model = try NSManagedObjectModel.loadFrom(bundle: bundle,
                                                          momdName: self.momdName,
                                                          versionName: aVersion)
            if (model.isConfiguration(withName: nil,
                                      compatibleWithStoreMetadata: metadata)) {
                startingVersion = aVersion
                return startingVersion
            }
        }
        throw NSError.init(
            domain: CoreDataMigrationErrorDomain,
            code: CoreDataProgressiveMigrationErrorCodes.couldNotFindAMatchingDataModel.rawValue,
            localizedDescription: NSLocalizedString(
                "Cound not find model version for given store",
                comment: "error during migration of user's data to new version"))
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
