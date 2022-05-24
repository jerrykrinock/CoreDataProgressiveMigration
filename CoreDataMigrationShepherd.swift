import Foundation

enum CoreDataMigrationShepherdError : Error {
    case couldNotTildefyPath(_ path: String?)
}


/**
 An **example** of a CoreDataMigrationDelegate

 Of course, this is going to application-specific.  You may copy this file
 to your project if you want to, but it will not compile until you remove the
 references to symbols in my app.
  */
class CoreDataMigrationShepherd : NSObject, CoreDataMigrationDelegate {
    
    func shpuldMigrate(_ storeUrl: URL) throws -> Bool {
        let dccumentStoreName = BSManagedDocument.persistentStoreName as String
        if (storeUrl.lastPathComponent == dccumentStoreName) {
            /* This is a document package.  Copy the entire document. */
            let docUrl = storeUrl.deletingLastPathComponent().deletingLastPathComponent()
            let preservedPath = docUrl.path.tildefiedPath()
            guard let preservedPath = preservedPath else {
                throw CoreDataMigrationShepherdError.couldNotTildefyPath(preservedPath)
            }
            try FileManager.default.copyItem(atPath: storeUrl.path,
                                         toPath: preservedPath)
            
        } else if (storeUrl.pathExtension == "sql") {
            /* This is a loose file in Application Support directory.  Copy
             the store, and its -shm and -wal files. */
            
            let originalPath = storeUrl.path
            let originalShmPath = originalPath.appending("-shm")
            let originalWalPath = originalPath.appending("-wal")
            let tildefiedPath = originalPath.tildefiedPath()
            let tildefiedShmPath = originalShmPath.tildefiedPath()
            let tildefiedWalPath = originalWalPath.tildefiedPath()
            
            guard
                let tildefiedPath = tildefiedPath,
                let tildefiedShmPath = tildefiedShmPath,
                let tildefiedWalPath = tildefiedWalPath
            else {
                throw CoreDataMigrationShepherdError.couldNotTildefyPath(originalPath)
            }
            try FileManager.default.copyItem(atPath: originalPath,
                                             toPath: tildefiedPath)
            try FileManager.default.copyItem(atPath: originalShmPath,
                                             toPath: tildefiedShmPath)
            try FileManager.default.copyItem(atPath: originalWalPath,
                                             toPath: tildefiedWalPath)
        }
        
        /* My documents can be automatically edited by a helper tool which
         watches for browser bookmarks changes, etc.  We want to inhibit
         any such automatic editing during migration. */
        let appDelegate = NSApp.delegate as! BkmxAppDel
        appDelegate.inhibit(forMigration: true)
        
        /* Note: I shall uninhibit immeditiately after our call to
         CoreDataProgressiveMigrator.migrateStoreIfNeeded() returns.  This is
         in my NSDocument subclass extension. */
        
        /* I do not give the user a choice about migrating, because most
         users will be either confused or irritated.  Therefore, I hard-code
         the return value… */
        return true
    }
}
