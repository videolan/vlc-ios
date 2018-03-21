// **********************************************************************************
//
// BSD License.
// This file is part of upnpx.
//
// Copyright (c) 2010-2011, Bruno Keymolen, email: bruno.keymolen@gmail.com
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, 
// this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this 
// list of conditions and the following disclaimer in the documentation and/or other 
// materials provided with the distribution.
// Neither the name of "Bruno Keymolen" nor the names of its contributors may be 
// used to endorse or promote products derived from this software without specific 
// prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;LOSS OF USE, DATA, OR 
// PROFITS;OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
// POSSIBILITY OF SUCH DAMAGE.
//
// **********************************************************************************

#import "MediaServerBasicObjectParser.h"
#import "MediaServer1BasicObject.h"
#import "MediaServer1ContainerObject.h"
#import "MediaServer1ItemObject.h"
#import "NSString+UPnPExtentions.h"
#import "OrderedDictionary.h"
#import "MediaServer1ItemRes.h"

@interface MediaServerBasicObjectParser ()
@property (nonatomic, readwrite, retain) NSString *resourceURI;
@end

@implementation MediaServerBasicObjectParser

@synthesize mediaTitle;
@synthesize mediaClass;
@synthesize mediaID;
@synthesize parentID;
@synthesize childCount;
@synthesize artist;
@synthesize album;
@synthesize date;
@synthesize genre;
@synthesize originalTrackNumber;
@synthesize uri;
@synthesize protocolInfo;
@synthesize frequency;
@synthesize audioChannels;
@synthesize size;
@synthesize duration;
@synthesize icon;
@synthesize bitrate;
@synthesize albumArt;
@synthesize resourceURI;


/*
 <container id="7" parentID="0" restricted="1" childCount="6">
     <dc:title>Audio</dc:title>
     <upnp:class>object.container</upnp:class>
 </container>
 
 
 <item id="27934" parentID="27933" restricted="0">
     <dc:title>01-Mis-Shapes.mp3</dc:title>
     <upnp:class>object.item.audioItem.musicTrack</upnp:class>
     <upnp:artist>Pulp</upnp:artist>
     <upnp:album>Different Class</upnp:album>
     <dc:date>1995-01-01</dc:date>
     <upnp:genre>Rock</upnp:genre>
     <upnp:originalTrackNumber>1</upnp:originalTrackNumber>
     <res protocolInfo="http-get:*:audio/mpeg:*" sampleFrequency="48000" nrAudioChannels="2">http://192.168.123.15:49152/content/media/object_id=27934&amp;res_id=0&amp;ext=.mp3</res>
 </item>
 */


/**
 * All Objects;Items + Containers
 */
-(instancetype)initWithMediaObjectArray:(NSMutableArray*)mediaObjectsArray{
    return [self initWithMediaObjectArray:mediaObjectsArray itemsOnly:NO];
}


-(instancetype)initWithMediaObjectArray:(NSMutableArray*)mediaObjectsArray itemsOnly:(BOOL)onlyItems{
    self = [super initWithNamespaceSupport:YES];

    if (self) {
        /* TODO: mediaObjects -> retain property */
        mediaObjects = mediaObjectsArray;
        [mediaObjects retain];


        //Container
        if(onlyItems == NO){
            [self addAsset:@[@"DIDL-Lite", @"container"] callfunction:@selector(container:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
            [self addAsset:@[@"DIDL-Lite", @"container", @"title"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setMediaTitle:) setStringValueObject:self];
            [self addAsset:@[@"DIDL-Lite", @"container", @"class"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setMediaClass:) setStringValueObject:self];
            [self addAsset:@[@"DIDL-Lite", @"container", @"albumArtURI"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setAlbumArt:) setStringValueObject:self];
            [self addAsset:@[@"DIDL-Lite", @"container", @"artist"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setArtist:) setStringValueObject:self];
        }


        //Item
        [self addAsset:@[@"DIDL-Lite", @"item"] callfunction:@selector(item:) functionObject:self setStringValueFunction:nil setStringValueObject:nil];
        [self addAsset:@[@"DIDL-Lite", @"item", @"title"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setMediaTitle:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"class"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setMediaClass:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"artist"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setArtist:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"album"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setAlbum:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"date"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setDate:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"genre"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setGenre:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"originalTrackNumber"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setOriginalTrackNumber:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"albumArtURI"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setAlbumArt:) setStringValueObject:self];

        [self addAsset:@[@"DIDL-Lite", @"item", @"creator"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setCreator:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"author"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setAuthor:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"director"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setDirector:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"longDescription"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setLongDescription:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"lastPlaybackPosition"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setLastPlaybackPosition:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"lastPlaybackTime"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setLastPlaybacktime:) setStringValueObject:self];
        [self addAsset:@[@"DIDL-Lite", @"item", @"playbackCount"] callfunction:nil functionObject:nil setStringValueFunction:@selector(setPlaybackCount:) setStringValueObject:self];

        [self addAsset:@[@"DIDL-Lite", @"item", @"res"] callfunction:@selector(res:) functionObject:self setStringValueFunction:@selector(setResourceURI:) setStringValueObject:self];
    }

    return self;
}


-(void)dealloc{
    [mediaTitle release];
    [mediaClass release];
    [mediaID release];
    [parentID release];
    [childCount release];
    [artist release];
    [album release];
    [date release];
    [genre release];
    [originalTrackNumber release];
    [uri release];
    [protocolInfo release];
    [frequency release];
    [audioChannels release];
    [size release];
    [duration release];
    [icon release];
    [bitrate release];
    [albumArt release];

    [uriCollection release];
    [resources release];
    [mediaObjects release];
    
    [resourceURI release];
   
    [super dealloc];
}


-(void)empty{
    [self setMediaClass:@""];
    [self setMediaTitle:@""];
    [self setMediaID:@""];
    [self setArtist:@""];
    [self setAlbum:@""];
    [self setDate:nil];
    [self setGenre:@""];
    [self setAlbumArt:nil];
    [self setDuration:nil];

    [self setLongDescription:@""];
    [self setLastPlaybackPosition:@""];
    [self setLastPlaybacktime:@""];
    [self setPlaybackCount:@""];
    [self.creators removeAllObjects];
    [self.authors removeAllObjects];
    [self.directors removeAllObjects];

    [resources release];
    resources = [[NSMutableArray alloc] init];
    [uriCollection release];
    uriCollection = [[NSMutableDictionary alloc] init];

    _creators = [[NSMutableArray alloc] init];
    _authors = [[NSMutableArray alloc] init];
    _directors = [[NSMutableArray alloc] init];
}


//hh:mm:ss -> seconds
-(int)_HMS2Seconds:(NSString *)time
{
    int s = 0;

    NSArray *items = [time componentsSeparatedByString:@":"];
    if ([items count] == 3){
        //hh
        s = s + [(NSString*)items[0] intValue] * 60 * 60;
        //mm
        s = s + [(NSString*)items[1] intValue] * 60;
        //ss
        s = s + [(NSString*)items[2] intValue];
    }

    return s;
}


-(void)container:(NSString*)startStop{
    if([startStop isEqualToString:@"ElementStart"]){
        //Clear
        [self empty];

        //Get the attributes
        [self setMediaID:elementAttributeDict[@"id"]];
        [self setParentID:elementAttributeDict[@"parentID"]];
        [self setChildCount:elementAttributeDict[@"childCount"]];

    }else{
        MediaServer1ContainerObject *media = [[MediaServer1ContainerObject alloc] init];

        [media setIsContainer:YES];
 
        [media setObjectID:mediaID];
        [media setParentID:parentID];
        [media setTitle:mediaTitle];
        [media setObjectClass:mediaClass];
        [media setChildCount:childCount];
        [media setAlbumArt:albumArt];
        [media setArtist:artist];

        [media setLongDescription:self.longDescription];
        [media setLastPlaybackPosition:self.lastPlaybackPosition];
        [media setLastPlaybacktime:self.lastPlaybacktime];
        [media setPlaybackCount:self.playbackCount];
        [media setCreators:self.creators];
        [media setAuthors:self.authors];
        [media setDirectors:self.directors];

        [mediaObjects addObject:media];

        [media release];

    }
}


-(void)item:(NSString*)startStop{
    if([startStop isEqualToString:@"ElementStart"]){
        //Clear
        [self empty];

        //Get the attributes
        [self setMediaID:elementAttributeDict[@"id"]];
        [self setParentID:elementAttributeDict[@"parentID"]];
    }else{
        MediaServer1ItemObject *media = [[MediaServer1ItemObject alloc] init];

        [media setIsContainer:NO];

        [media setObjectID:mediaID];
        [media setParentID:parentID];
        [media setTitle:mediaTitle];
        [media setObjectClass:mediaClass];
        [media setArtist:artist];
        [media setAlbum:album];
        [media setDate:date];
        [media setGenre:genre];
        [media setOriginalTrackNumber:originalTrackNumber];
        [media setUri:uri];
        [media setProtocolInfo:protocolInfo];
        [media setFrequency:frequency];
        [media setAudioChannels:audioChannels];
        [media setSize:size];
        [media setDuration:duration];
        [media setDurationInSeconds:[self _HMS2Seconds:duration]];
        [media setBitrate:bitrate];
        [media setIcon:icon];//REMOVE THIS ?
        [media setAlbumArt:albumArt];
        [media setUriCollection:[NSDictionary dictionaryWithDictionary:uriCollection]];

        MediaServer1ItemRes *resource = nil;
        NSEnumerator *e = [resources objectEnumerator];
        while((resource = [e nextObject])){
            [media addRes:resource];
        }
        [resources removeAllObjects];

        [mediaObjects addObject:media];

        [media release];
    }
}


-(void)res:(NSString*)startStop{
    if([startStop isEqualToString:@"ElementStop"]){
        
        NSString *resProtocolInfo = elementAttributeDict[@"protocolInfo"];
        NSString *resFrequency = elementAttributeDict[@"sampleFrequency"];
        NSString *resAudioChannels = elementAttributeDict[@"nrAudioChannels"];
        NSString *resSize = elementAttributeDict[@"size"];
        NSString *resDuration = elementAttributeDict[@"duration"];
        NSString *resBitrate = elementAttributeDict[@"bitrate"];
        NSString *resIcon = elementAttributeDict[@"icon"];
        
        //Add to the recource connection, there can be multiple resources per media item
        MediaServer1ItemRes *r = [[MediaServer1ItemRes alloc] init];
        [r setBitrate: [resBitrate intValue]];
        [r setDuration: resDuration];
        [r setNrAudioChannels: [resAudioChannels intValue]];
        [r setProtocolInfo: resProtocolInfo];
        [r setSize: [resSize longLongValue]];
        [r setDurationInSeconds:[self _HMS2Seconds:resDuration]];
        [r setFrequency:[resFrequency floatValue]];
        [r setIconPath:icon];
        [r setUri:[NSURL URLWithString:resourceURI]];
        [resources addObject:r];
        [r release];
        
        
        // Set the attributes for any non-image asset
        if ([resProtocolInfo rangeOfString:@"image/"].location == NSNotFound) {
            [self setProtocolInfo:resProtocolInfo];
            [self setFrequency:resFrequency];
            [self setAudioChannels:resAudioChannels];

            [self setSize:resSize];
            [self setDuration:resDuration];
            [self setBitrate:resBitrate];

            [self setIcon:resIcon];
        }

        NSString *protocolInfoString = elementAttributeDict[@"protocolInfo"];
        uriCollection[protocolInfoString] = resourceURI;//@todo: we overwrite uri's with same protocol info
        [self setUri:resourceURI];
        resourceURI = nil;
    }
}

-(void)setUri:(NSString*)s{
    [uri release];
    uri = s;
    [uri retain];
}

- (void)setResourceURI:(NSString *)r
{
    [resourceURI release];
    resourceURI = r;
    [resourceURI retain];
}

- (void)setCreator: (NSString *)value
{
    [self.creators addObject:value];
}

- (void)setAuthor: (NSString *)value
{
    [self.authors addObject:value];
}

- (void)setDirector: (NSString *)value
{
    [self.directors addObject:value];
}

@end
