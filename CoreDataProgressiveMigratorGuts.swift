//  Adapted from file "CoreDataMigrator.swift" in project
//  "CoreDataMigration-Example", written by William Boles on 11/09/2017.
//  Copyright © 2017 William Boles. All rights reserved.

import CoreData

class CoreDataProgressiveMigratorGuts {
    var storeUrl: URL
    var storeType: String
    var momdName: String
    var versionNames: [String]
    private var _startingVersion: String? = nil
    
    init(storeUrl: URL, storeType: String, momdName: String, versionNames: [String]) {
        self.storeUrl = storeUrl
        self.storeType = storeType
        self.momdName = momdName
        self.versionNames = versionNames
    }
    
    var currentVersion: String? {
         get {
             self.versionNames.last
         }
    }
        
    private static func mappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel) -> NSMappingModel? {
        guard let customMapping = customMappingModel(fromSourceModel: sourceModel, toDestinationModel: destinationModel) else {
            return inferredMappingModel(fromSourceModel:sourceModel, toDestinationModel: destinationModel)
        }
        return customMapping
    }

    private static func inferredMappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel) -> NSMappingModel? {
        return try? NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
    }

    private static func customMappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel) -> NSMappingModel? {
        return NSMappingModel(from: [Bundle.main], forSourceModel: sourceModel, destinationModel: destinationModel)
    }

    /**
     Does the actual migration, all required steps
     
     - parameter thruVersions: An array beginning with th"e name of the version
     now present in the store to be migrated and ending with the name of the
     current version required by the current version of the app.  For example,
     if a store has had data model versions "v1", "v2", "v3", "v4", "v5", and
     a store is at version "v3", `thruVersions` should be ["v3", "v4", "v5"].
     */
    func migrate(thruVersions: [String]) throws {
        if (self.storeType == NSSQLiteStoreType) {
            try forceWALCheckpointing()
        }
        
        let sourceStoreUrl = self.storeUrl
        var sourceVersion = thruVersions.first
        var destinModel: NSManagedObjectModel? = nil;
        var destinStoreUrl: URL
        var i = 0
        let mainAppBundle = Bundle.mainAppBundle()
        while (true) {
            guard let sourceVersionGuarded = sourceVersion else {
                throw NSError.init(
                    domain: CoreDataMigrationErrorDomain,
                    code: CoreDataProgressiveMigrationErrorCodes.noSourceVersion.rawValue,
                    localizedDescription: NSLocalizedString(
                        "No source version for migration",
                        comment: "error during migration of user's data to new version"),
                    localizedRecoverySuggestion: NSLocalizedString(
                        "Reinstall this application",
                        comment: "error during migration of user's data to new version"))
            }
            let sourceModel = try NSManagedObjectModel.loadFrom(bundle: mainAppBundle,
                                                                momdName: self.momdName,
                                                                versionName: sourceVersionGuarded)
            let destinVersion = thruVersions[i+1]
            if (destinModel == nil) {
                /* This branch will only execute on the first iteration of this
                 loop.  For subsequent iterations, we re-use the sourceModel
                 from the previous iteration.  See the assignment at the
                 bottom of this loop. */
                destinModel = try NSManagedObjectModel.loadFrom(bundle: mainAppBundle,
                                                                momdName: self.momdName,
                                                                versionName: destinVersion)
            }
            guard let destinModelGuarded = destinModel else {
                throw NSError.init(
                    domain: CoreDataMigrationErrorDomain,
                    code: CoreDataProgressiveMigrationErrorCodes.couldNotMakeDestinModel.rawValue,
                    localizedDescription: NSLocalizedString(
                        "Could not create data model for destination when migrating user data",
                        comment: "error during migration of user's data to new version"),
                    localizedRecoverySuggestion: NSLocalizedString(
                        "Reinstall this application",
                        comment: "error during migration of user's data to new version"))
            }
            guard let mappingModel = Self.mappingModel(fromSourceModel: sourceModel,
                                                       toDestinationModel: destinModelGuarded) else {
                throw NSError.init(
                    domain: CoreDataMigrationErrorDomain,
                    code: CoreDataProgressiveMigrationErrorCodes.couldNotGetMappingModel.rawValue,
                    localizedDescription: NSLocalizedString(
                        "Could not get mapping model to migrate user data",
                        comment: "error during migration of user's data to new version"),
                    localizedRecoverySuggestion: NSLocalizedString(
                        "Reinstall this application",
                        comment: "error during migration of user's data to new version"))
            }
            let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinModelGuarded)
            destinStoreUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
            
            do {
                try manager.migrateStore(from: sourceStoreUrl,
                                         sourceType: self.storeType,
                                         options: nil,
                                         with: mappingModel,
                                         toDestinationURL: destinStoreUrl,
                                         destinationType: self.storeType,
                                         destinationOptions: nil)
            } catch let error {
                let descFormat = NSLocalizedString(
                    "Failed when migrating user data from model version %@ to model version %@",
                    comment: "error during migration of user's data to new version")
                let desc = String(format: descFormat, sourceVersionGuarded, destinVersion)
                throw NSError.init(
                    domain: CoreDataMigrationErrorDomain,
                    code: CoreDataProgressiveMigrationErrorCodes.migrationStepFailed.rawValue,
                    localizedDescription: desc,
                    underlyingError: error)
            }
            
            if sourceStoreUrl != self.storeUrl {
                //Destroy intermediate step's store
                try NSPersistentStoreCoordinator.destroyStore(at: sourceStoreUrl)
            }
            
            i = i+1
            destinModel = sourceModel
            sourceVersion = thruVersions[i]
            
            if (sourceVersion == thruVersions.last) {
                try NSPersistentStoreCoordinator.replaceStore(at: self.storeUrl,
                                                          withStoreAt: destinStoreUrl)

                if (destinStoreUrl != self.storeUrl) {
                    try NSPersistentStoreCoordinator.destroyStore(at: destinStoreUrl)
                }
                break
            }
        }
    }

    func forceWALCheckpointing() throws {
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: self.storeType, at: self.storeUrl, options: nil)
        guard let currentModel = NSManagedObjectModel.mergedModel(from: [Bundle.mainAppBundle()], forStoreMetadata: metadata)
        else {
            return
        }
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)
        
        let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
        let store = try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                                      configurationName: nil,
                                                                      at: self.storeUrl,
                                                                      options: options)
        try persistentStoreCoordinator.remove(store)
    }
}
