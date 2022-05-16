//
//  NSManagedObjectModel+Compatible.swift
//  CoreDataMigration-Example
//
//  Created by William Boles on 02/01/2019.
//  Copyright © 2019 William Boles. All rights reserved.
//

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
            throw CoreDataProgressiveMigratorError.cannotFindModelInBundle
        }
        
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            throw CoreDataProgressiveMigratorError.cannotLoadModelInBundle
        }
        
        return model
    }

}
