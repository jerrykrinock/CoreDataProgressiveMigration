import Foundation

enum BkmxCoreDataMigrationDelegateError : Error {
    case couldNotTildefyPath(_ path: String?)
}


/**
 An **example** of a CoreDataMigrationDelegate

 Of course, this is going to application-specific.  You may copy this file
 to your project if you want to, but it will not compile until you remove the
 references to symbols in my app.
  */
class BkmxCoreDataMigrationDelegate : NSObject, CoreDataMigrationDelegate {
    
    func shpuldMigrate(_ storeUrl: URL) throws -> Bool {
        /* My documents can be automatically edited by a helper tool which
         watches for browser bookmarks changes, etc.  We do two things to
         avoid trouble during the migration process. */
        
        /*  Thing 1.. Inhibit any such automatic editing by our agent
         process. */
        let appDelegate = NSApp.delegate as! BkmxAppDel
        appDelegate.inhibit(forMigration: true)
        /* We shall uninhibit immeditiately after our call to
         CoreDataProgressiveMigrator.migrateStoreIfNeeded() returns.  This is
         in our NSDocument subclass extension. */
        
        /* Thing 2.  Terminate our agent process, because it might
         have the document's Core Data store, or associated Core Data
         stores, open.*/
        do {
            var quitPid: pid_t = 0
            try BkmxBasis.shared().quillBkmxAgentPid_p(&quitPid)
            if (quitPid > 0) {
                /* Our BkmxBasis calss does have a -logFormat instance method,
                 but that would not compile, I think because you cannot
                 call variadic Objective-C functions from Swift.  So we do the
                 formatting in Swift… */
                BkmxBasis.shared().logString(String(format: "Migration starting! Quitting BkmxAgent pid=%ld", quitPid))
                BkmxBasis.shared().isDoingCoreDataMigration = true
            }
        } catch {
            /* This failure should occur very rarely, given the double-whammy
             which is written into quillBkmxAgentPid_p.  Also, the migration
             may succeed anyhow.  So we just log this error. */
            BkmxBasis.shared().logError(error as NSError,
                                        markAsPresented: false)
        }
        /* We shall relaunch our agent immeditiately after our call to
         CoreDataProgressiveMigrator.migrateStoreIfNeeded() returns.  This is
         in our NSDocument subclass extension. */

        /* Another thing we want to do prior to migrating is to copy the
         Core Data database, and its -shm and -wal files, appending tilde(s)
         to the copies.  This is in case the user wants to revert back to the
         */
        let documentStoreName = BSManagedDocument.persistentStoreName as String
        if (storeUrl.lastPathComponent == documentStoreName) {
            /* This is a document package.  Copy the entire document. */
            let docUrl = storeUrl.deletingLastPathComponent().deletingLastPathComponent()
            let preservedPath = docUrl.path.tildefiedPath()
            guard let preservedPath = preservedPath else {
                throw BkmxCoreDataMigrationDelegateError.couldNotTildefyPath(preservedPath)
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
                throw BkmxCoreDataMigrationDelegateError.couldNotTildefyPath(originalPath)
            }
            try FileManager.default.copyItem(atPath: originalPath,
                                             toPath: tildefiedPath)
            try FileManager.default.copyItem(atPath: originalShmPath,
                                             toPath: tildefiedShmPath)
            try FileManager.default.copyItem(atPath: originalWalPath,
                                             toPath: tildefiedWalPath)
        }
                
        /* Note: I shall uninhibit immeditiately after our call to
         CoreDataProgressiveMigrator.migrateStoreIfNeeded() returns.  This is
         in my NSDocument subclass extension. */
        
        /* I do not give the user a choice about migrating, because most
         users will be either confused or irritated.  Therefore, I hard-code
         the return value… */
        return true
    }
    
    func didMigrate(_ storeUrl: URL, migratedVersionNames: [String]) throws {
        let appDelegate = NSApp.delegate as! BkmxAppDel
        let basis = appDelegate.basis()!
        var readableName: String?
        var documentUuid: String?
        if (storeUrl.lastPathComponent == BSManagedDocument.persistentStoreName) {
            if let documentSuffix = NSDocumentController.shared.defaultDocumentFilenameExtension() {
                let comps = storeUrl.pathComponents
                readableName = comps.first(where: {$0.hasSuffix(documentSuffix)}) ?? "Cannot find document name"
                documentUuid = BkmxDoc.uuidOfDocumentWithStoreUrl(storeUrl)
            }
        } else if (storeUrl.lastPathComponent.hasPrefix(constBaseNameLogs)) {
            readableName = storeUrl.lastPathComponent
            documentUuid = nil
        } else {
            readableName = storeUrl.lastPathComponent
            documentUuid = BkmxDoc.uuidOfAncillaryMocWithUrl(storeUrl)
        }
        let logMsg = "Did migrate \(readableName ?? "No-name??") through versions \(migratedVersionNames)"
        basis.logString(logMsg)

        if let documentUuid = documentUuid {
            let documentController = NSDocumentController.shared as! BkmxDocumentController
            
            /* We do not need to switch BkmxAgent back on, because that
             will be done a few milliseconds from now, during the "housekeeping"
             end of -[BkmxDoc readFromURL:ofType:error], when it calls
             -[BkmxDoc realizeSyncersToWatchesError_p:].  However, we need to
             re-enable others to do so
             */
            BkmxBasis.shared().isDoingCoreDataMigration = false
            
            if (documentController.allStoresMigratedForDocumentUuid(documentUuid)) {
                /* We should only need to uninhibit if any migration was done.
                 But, for defensive programming, we uninhibit without testing
                 that condition.  Inhibiting syncing makes users upset. */
                appDelegate.inhibit(forMigration: false)
            }
        }
    }
}
