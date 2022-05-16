#import <Bkmxwork/Bkmxwork-Swift.h>

@interface CoreDataProgressiveMigrator ()

/*!
 @brief    Designated initializer for CoreDataProgressiveMigrator
 
 @details  This function is implemented in CoreDataProgresiveMigrator.swift
 with @objc.  This declaration is just for clarity
 */
- (instancetype)initWithStoreUrl:(NSURL*)storeUrl
                       storeType:(NSString*)storeType
                        momdName:(NSString*)momdName;

@end

@interface CoreDataProgressiveMigrator (ObjC)

/*!
 @brief  Migrates the store to which the receiver has been initialized
 
 @details  Instead of this method, you could use the Swift func
 CoreDataProgressiveMigrator.migrateStoreIfNeededObjC() since it is @objc,
 if you con't mind unpacking a dictionary.  This method is a just a wrapper
 around that one, to provide a more normal Objective-C interface.

 @param    didVersions_p  Pointer which will, upon return, if migration was
 oerfirned and said pointer is not NULL, point to an array of names of the
 versions through which the store has been migrated.  If migration was not
 necessary, points to nil.
 @param    error_p  Pointer which will, upon return, if an error
 occurred and said pointer is not NULL, point to an NSError
 describing said error.
 
 @result   YES if the migration succeeded or was not necessary, NO if an
 error occurred.
 */
- (BOOL)migrateIfNeededDidVersions:(NSArray**)result
                             error:(NSError**)error;

@end


