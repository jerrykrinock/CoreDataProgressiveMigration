import Foundation
import CoreData

extension Bundle {
    public class func mainAppBundle() -> Bundle {
        var mainAppBundle: Bundle? = nil
        let path = ProcessInfo.processInfo.arguments.first
        if var path = path {
            /* See if path is a symbolic link, because if this process
             was launched by a symbolic link, starting in macOS 10.14,
             this path will be the symbolic link's path!!
             
             (Similarly, if this process is a bare executable, and was
             launched via symbolic link, [[NSBundle mainBundle] bundlePath]
             will return the parent of the symbolic link, which is useless
             for our purpose here.)  I have not  tested what
             [[NSBundle mainBundle] bundlePath] returns if this process is in a
             bundle but launched via a symbolic link. */
            do {
                let symlinkDestin = try FileManager.default.destinationOfSymbolicLink(atPath: path)
                path = symlinkDestin
            } catch {
                /* This should never happen, but we need to shut up the
                 Swift compiler */
                mainAppBundle = Bundle.main
            }
            
            /* Each iteration of the following loop clips off one path
             component at the end, so that `path` is eventually only "/" and
             the loop exits.  Along the way, whenever we find a path ending
             in ".app", we store its bundle, because it is a candidate for
             being the mainAppBundle ew are looking for.  The last such
             candidate is the winner. */
            while (path.count > 4) {
                if (path.hasSuffix(".app")) {
                    /* This path is a candidate. */
                    mainAppBundle = Bundle.init(path: path)
                }
                let url = URL.init(string: path)
                if let url = url {
                    let newUrl = url.deletingLastPathComponent()
                    path = newUrl.path
                }
            }
        }
        
        let answer = mainAppBundle ?? Bundle.main
        
        return answer
    }
}


struct CoreDataVersionHacker {
    enum CoreDataVersionScraperError: Error {
        case noMomdInAppBundle
        case momdIsNotABundle
        case couldNotGetBundle
        case noVersionInfo
        case errorReadingVersionPlist(underlyingError: Error)
        case cannotDecodeVersionPlistData(underlyingError: Error)
        case noCurrentVersionName
    }
    
    private var modelBundle: Bundle? = nil
    private var availableVersionNames: [String]? = nil
    
    /**
     Peeks into a Core Data momd bundle and returns a sorted array of version
     names
     
     Based upon a reverse engineering of the momd bundle
     - parameter momdName: The name of the momd resource file in the bundle
     of the current app whic is to be peeked into, not including the ".momd"
     - returns: The returned array is sorted alphanumerically.
     - throws:A member of CoreDataVersionScraperError
     */
    public mutating func modelBundle(momdName: String) throws -> Bundle? {
        if (self.modelBundle == nil) {
            let appBundle = Bundle.mainAppBundle()
            guard let momdPath = appBundle.path(forResource: momdName,
                                                ofType: "momd") else {
                throw CoreDataVersionScraperError.noMomdInAppBundle
            }
            guard let modelBundle = Bundle.init(path: momdPath) else {
                throw CoreDataVersionScraperError.momdIsNotABundle
            }
            
            self.modelBundle = modelBundle
        }
        
        return self.modelBundle
    }

    public mutating func availableVersionNames(momdName: String) throws -> [String] {
        if (self.availableVersionNames == nil) {
            guard let modelBundle = try self.modelBundle(momdName: momdName) else {
                throw CoreDataVersionScraperError.couldNotGetBundle
            }
            
            guard let plistPath = modelBundle.path(forResource: "VersionInfo", ofType: "plist") else {
                throw CoreDataVersionScraperError.noVersionInfo
            }

            let plistUrl = URL.init(fileURLWithPath: plistPath)
            
            var plistData: Data
            do {
                plistData = try Data.init(contentsOf: plistUrl)
            } catch {
                throw CoreDataVersionScraperError.errorReadingVersionPlist(underlyingError: error)
            }
            
            var versionInfo: Dictionary<String, Any>
            do {
                versionInfo = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? Dictionary<String, Any> ?? Dictionary()
            } catch {
                throw CoreDataVersionScraperError.cannotDecodeVersionPlistData(underlyingError: error)
            }
            
            /* I suppose that modelVersionNames could be nil if there was only
             so no guard let on this; provide default value instead… */
            let versionDic = versionInfo["NSManagedObjectModel_VersionHashes"] as? Dictionary<String, Any> ?? [:]
            
            self.availableVersionNames = Array(versionDic.keys).sorted()
        }
        
        return self.availableVersionNames ?? []
    }
}
