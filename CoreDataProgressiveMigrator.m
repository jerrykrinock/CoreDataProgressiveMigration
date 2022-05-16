#import <Foundation/Foundation.h>
#import "CoreDataProgressiveMigrator.h"

@implementation CoreDataProgressiveMigrator (ObjC)

/*!
 @brief    Outer Objective-C wrapper around migrateStoreIfNeeded()
 */
- (BOOL)migrateIfNeededDidVersions:(NSArray**)didVersions_p
                             error:(NSError**)error_p {
    NSDictionary* results = [self migrateStoreIfNeededObjC];

    NSArray* didVersions = [results objectForKey:@"migratedVersions"];
    if (didVersions.count < 1) {
        didVersions = nil;
    }

    NSError* error = [results objectForKey:@"error"];
    if (![error isKindOfClass:[NSError class]]) {
        error = nil;
    }

    if (didVersions_p) {
        *didVersions_p = didVersions;
    }
    
    if (error && error_p) {
        *error_p = error;
    }
    
    return (error == nil);
}

@end

