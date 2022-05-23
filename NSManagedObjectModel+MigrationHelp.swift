//  Adapted from file "NSManagedObjectModel+Compatible.swift" in project
//  "CoreDataMigration-Example", written by William Boles on 02/01/2019.
//  Copyright © 2019 William Boles. All rights reserved.

import Foundation
import CoreData

extension NSManagedObjectModel {
    static func compatibleModelForStoreMetadata(_ metadata: [String : Any]) -> NSManagedObjectModel? {
        return NSManagedObjectModel.mergedModel(from: [Bundle.mainAppBundle()], forStoreMetadata: metadata)
    }
    
    static func loadFrom(bundle: Bundle, momdName: String, versionName: String) throws -> NSManagedObjectModel {
        let momdPkgName = momdName + ".momd"
        
        var omoURL: URL?
        if #available(iOS 11, *) {
            omoURL = bundle.url(forResource: versionName, withExtension: "omo", subdirectory: momdPkgName) // optimized model file
        }
        let momURL = bundle.url(forResource: versionName, withExtension: "mom", subdirectory: momdPkgName)
        
        guard let url = omoURL ?? momURL else {
            throw NSError.init(
                domain: CoreDataMigrationErrorDomain,
                code: CoreDataProgressiveMigrationErrorCodes.cannotFindModelInBundle.rawValue,
                localizedDescription: NSLocalizedString(
                    "Cannot find path to data model in application bundle",
                    comment: "error during migration of user's data to new version"),
                localizedRecoverySuggestion: NSLocalizedString(
                    "Reinstall this application",
                    comment: "error during migration of user's data to new version"))
        }
        
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            throw NSError.init(
                domain: CoreDataMigrationErrorDomain,
                code: CoreDataProgressiveMigrationErrorCodes.cannotLoadModelInBundle.rawValue,
                localizedDescription: NSLocalizedString(
                    "Found path to data model in app bundle, but cannot load it",
                    comment: "error during migration of user's data to new version"),
                localizedRecoverySuggestion: NSLocalizedString(
                    "Reinstall this application",
                    comment: "error during migration of user's data to new version"))
        }
        
        return model
    }

}
