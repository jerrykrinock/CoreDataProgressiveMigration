import Foundation

enum CoreDataMigrationShepherdError : Error {
    case couldNotTildefyPath(_ path: String?)
}


/**
 An example of a CoreDataMigrationDelegate

 Of course, this is going to application-specific, so you will probably make
 your own version and include your file in your project instead of this file.
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
        
        /* I do not give the user a choice about migrating, because most
         users will be either confused or irritated. */
        return true
    }
}
