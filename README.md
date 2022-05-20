[![Build Status](https://travis-ci.org/wibosco/CoreDataMigrationRevised-Example.svg)](https://travis-ci.org/wibosco/CoreDataMigrationRevised-Example)
<a href="https://swift.org"><img src="https://img.shields. io/badge/Swift-4.2-orange.svg?style=flat" alt="Swift" /></a>

#  CoreDataProgressiveMigration

CoreDataProgressiveMigration is a fork of William Boles' CoreDataMigrationExample.  Progressive migration is explained in William Boles' [blog post on progressive migration](https://williamboles.me/progressive-core-data-migration/)

Our fork is it is not a tutorial example as William's code is.  CoreDataProgressiveMigration is a group of source files with a API that can be spliced into your Core Data target, either Swift or Objective-C (with a little shim).  We feel that dropping CoreDataProgressiveMigration into your actual project and trying it will be much faster than studying an example.

## Features

* Synchronous, so you can just it splice into overrides of existing synchronous methods such as `NSDocument.read(from:ofType:)`.

* Independent of your Core Data stack or persistent container.  CoreDataProgressiveMigration should be spliced in before your Core Data stack is created.  Returns very quickly in the normal case of no migration needed.

* Includes a CoreDataVersionHacker which reads the .plist file which Xcode embeds in data model (.momd) bundles. [1]  The order of your versions is inferred from your model version names:  When placed into an Array<String> and sorted with .sorted(), your version names must sort in order with the earliest version first and the latest (current) version last.

* Searches for Core Data resources in the outermost parent app bundle.  To do this, includes and uses an extension on NSBundle which provides the `mainAppBundle`.  For simple .apps, the `mainAppBundle` is just the main bundle.  But for tools, helper apps, agents, XPC bundles, etc., which are embedded in a main app, the mainAppBundle is the outermost "parent" .app bundle containing them.  This allows such tools, etc. to use data model and mapping model resources from the parent "main" app.  This is usually what we want.

* All errors are generated as NSErrors and propagate up the call stack to the migrateStoreIfNeeded… methods and are available to your code.  No fatalError() calls.

* Optional delegate is called when it is determined that migration is necessary, but before beginning the migration.  Some examples of things you might want to do in a CoreDataMigrationDelegate:
  * Notify the user that their data is to be migrated
  * Show a progress indicator
  * Copy the old databases to an archive before they are migrated and overwritten
  * Give the user the choice to abort the migration.

## How To Use

* Determine where you are going to splice the call to CoreDataProgressiveMigrator into your code.  This call will require three parameters: `storeType` (for example, NSSQLiteStoreType), `storeURL` (file URL), and name of the data model (.momd) file.  This call returns synchronously.  When CoreDataProgressiveMigrator returns, your code may create its Core Data stack and load its store as before, completely unaware that anything was done.  For Core Data document stores (`NSDocument`, `NSPersistentDocument`, `BSManagedDocument`), we recommend splicing into the your document's subclass' override of `read(from:ofType:)`, just before calling super.  Note that this is before the document's Core Data Stack is created.  For "shoebox" stores, we recommend doing this just prior to creating your NSPersistentContainer or Core Data stack.

* Add all of the .swift files in this repo except CoreDataMigrationShepherd.swift to your Xcode target.  CoreDataMigrationShepherd is an example of a CoreDataMigrationDelegate which you may study in designing your own deletage, if desired.  It is dependont on symbols in my project and will not compile in yours. 

* If your chosen splice location is in Objective-C code, you will need to add a shim file.  (Sorry, see explanation in documentation > CoreDataProgressiveMigrator > Details.)  Add a Swift file named something like MyClass+MigrationShim.  In this file, define an extension to MyClass containing a function marked @objc, named something like `migrateIfNeeded`, which throws, and returns Void.  You may pass in parameters if needed.  It may be either a class or instance method.  Example:

    * `@objc class func migrateIfNeeded(url: URL, momdName: String) throws {.,,}
 
    The {...} code inside this function is now your *chosen splice location* referred to in the next step.

* At your chosen splice location, splice in these 2-3 lines of code:

  * Optional: If you want the delegate callback, init() your delegate conforming to CoreDataMigrationDelegate, or make self the delegate.
  
  * Create an instance of CoreDataProgressiveMigrator by calling its initializer `CoreDataProgressiveMigrator.init(storeUrl:storeType:momdName:delegate:)`.

  * Call the migrateStoreIfNeeded()` function on that instance.

* * *

## Footnote

1.  Yes, this reverse-engineering of that .plist file is unsupported; Apple may change it, blah, blah, but I've been doing this in my previous Objective-C code for over ten years and I think the convenience of having this "just work" with each new version is worth the small risk.  If you don't like this idea, replace CoreDataVersionHacker with your preferred solution.
