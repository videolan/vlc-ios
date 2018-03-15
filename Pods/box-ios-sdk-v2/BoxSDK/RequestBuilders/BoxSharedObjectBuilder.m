//
//  BoxSharedObjectBuilder.m
//  BoxSDK
//
//  Created on 3/12/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxSharedObjectBuilder.h"

#import "BoxLog.h"

BoxAPISharedObjectAccess *const BoxAPISharedObjectAccessOpen = @"open";
BoxAPISharedObjectAccess *const BoxAPISharedObjectAccessCompany = @"company";
BoxAPISharedObjectAccess *const BoxAPISharedObjectAccessCollaborators = @"collaborators";

@interface BoxSharedObjectBuilder ()

@property (nonatomic, readonly, strong) NSDictionary *JSONLookup;

@end

@implementation BoxSharedObjectBuilder

@synthesize access = _access;
@synthesize unsharedAt = _unsharedAt;
@synthesize canDownload = _canDownload;
@synthesize canPreview = _canPreview;
@synthesize JSONLookup = _JSONLookup;

- (id)init
{
    static dispatch_once_t pred;
    static NSDictionary *JSONStructures;

    self = [super init];
    if (self != nil)
    {
        _access = nil;
        _unsharedAt = nil;
        _canDownload = BoxAPISharedObjectPermissionStateUnset;
        _canPreview = BoxAPISharedObjectPermissionStateUnset;

        dispatch_once(&pred, ^{
            // structure: dict["permissions"][canDownloadValue][canPreviewValue] = permissions dictionary
            // this dictionary stores the configuration of the permissions JSON object that needs to be
            // sent over the wire to the Box API for all combinations of the two permissions flags
            // canDownload and canPreview
            //
            // For example, if canDownload = Disabled and canPreview = Enabled, the resulting JSON object
            // will look like this:
            // { "can_download" : false, "can_preview" : true }
            JSONStructures = @{
                    [NSNumber numberWithInt:BoxAPISharedObjectPermissionStateDisabled] : @{ // canDownload
                        [NSNumber numberWithInt:BoxAPISharedObjectPermissionStateDisabled] : @{ // canPreview
                            @"can_download": [NSNumber numberWithBool:NO],
                            @"can_preview" : [NSNumber numberWithBool:NO],
                        },
                        [NSNumber numberWithInt:BoxAPISharedObjectPermissionStateEnabled] : @{ // canPreview
                            @"can_download": [NSNumber numberWithBool:NO],
                            @"can_preview" : [NSNumber numberWithBool:YES],
                        },
                        [NSNumber numberWithInt:BoxAPISharedObjectPermissionStateUnset] : @{ // canPreview
                            @"can_download": [NSNumber numberWithBool:NO],
                        },
                    },
                    [NSNumber numberWithInt:BoxAPISharedObjectPermissionStateEnabled] : @{ // canDownload
                        [NSNumber numberWithInt:BoxAPISharedObjectPermissionStateDisabled] : @{ // canPreview
                            @"can_download": [NSNumber numberWithBool:YES],
                            @"can_preview" : [NSNumber numberWithBool:NO],
                        },
                        [NSNumber numberWithInt:BoxAPISharedObjectPermissionStateEnabled] : @{ // canPreview
                            @"can_download": [NSNumber numberWithBool:YES],
                            @"can_preview" : [NSNumber numberWithBool:YES],
                        },
                        [NSNumber numberWithInt:BoxAPISharedObjectPermissionStateUnset] : @{ // canPreview
                            @"can_download": [NSNumber numberWithBool:YES],
                        },
                    },
                    [NSNumber numberWithInt:BoxAPISharedObjectPermissionStateUnset] : @{ // canDownload
                        [NSNumber numberWithInt:BoxAPISharedObjectPermissionStateDisabled] : @{ // canPreview
                            @"can_preview" : [NSNumber numberWithBool:NO],
                        },
                        [NSNumber numberWithInt:BoxAPISharedObjectPermissionStateEnabled] : @{ // canPreview
                            @"can_preview" : [NSNumber numberWithBool:YES],
                        },
                    },
            };
        });
        _JSONLookup = JSONStructures;
    }

    return self;
}

- (NSDictionary *)bodyParameters
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:4];
    BOXAssert(self.access != nil, @"access is a required parameter for the shared link object");
    [dictionary setObject:self.access forKey:@"access"];

    if (self.unsharedAt != nil)
    {
        [dictionary setObject:[self ISO8601StringWithDate:self.unsharedAt] forKey:@"unshared_at"];
    }

    if (self.canDownload != BoxAPISharedObjectPermissionStateUnset || self.canPreview != BoxAPISharedObjectPermissionStateUnset)
    {
        NSNumber *boxedCanDownload = [NSNumber numberWithInt:self.canDownload];
        NSNumber *boxedCanPreview = [NSNumber numberWithInt:self.canPreview];
        id permissionsDictionary = [[self.JSONLookup objectForKey:boxedCanDownload] objectForKey:boxedCanPreview];
        BOXAssert(permissionsDictionary != nil, @"Invalid value for canDownload or canPreview");

        [dictionary setObject:permissionsDictionary forKey:@"permissions"];
    }

    return dictionary;
}

@end
