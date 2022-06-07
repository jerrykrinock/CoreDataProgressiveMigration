import Foundation

protocol CoreDataMigrationDelegate {
    /**
     CoreDataProgressiveMigrator sends this to its delegate, if any, after it
     has determined that a migration is necessary, and before the migration
     begins.

     - parameter storeUrl:  The file URL of the store which is proposed to be
     migrated
     - returns: true to allow the migration to proceed, false to abort the
     migration and have CoreDataProgressiveMigrator.migrateStoreIfNeeded()
     throw an error indicating that the delegate said "no".
     - throws:  Whatever Error or NSError you throw in your implementation
     */
    func shpuldMigrate(_ storeUrl: URL) throws -> Bool
    
    func didMigrate(_ storeUrl: URL, migratedVersionNames: [String]) throws
}

/**
 This extension provides default implementations for those funcs which
 we want to be optional
 */
extension CoreDataMigrationDelegate {
    func shpuldMigrate(_ storeUrl: URL) throws -> Bool {
        return true
    }

    func didMigrate(_ storeUrl: URL, migratedVersionNames: [String]) throws {
    }
}
