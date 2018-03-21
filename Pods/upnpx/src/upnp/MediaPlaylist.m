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


/*
 * States:
 * Stopped <-> Playing
 *
 */

#import "MediaPlaylist.h"
#import "MediaServerBasicObjectParser.h"
#import "NSString+UPnPExtentions.h"


@interface MediaPlaylist()
-(NSInteger)changeState:(MediaPlaylistState)newState;
@end



@implementation MediaPlaylist

@synthesize playList;
@synthesize currentTrack;
@synthesize mediaServer;
//@synthesize mediaRenderer;
@synthesize container;
@synthesize state;


-(instancetype)init{
    self = [super init];

    if (self) {
        state = MediaPlaylistState_NotInitialized;
        mObservers = [[NSMutableArray alloc] init];
        currentTrack = 0;
        playList = [[NSMutableArray alloc] init];
        mediaServer = nil;
        container = nil;
    }

    return self;
}


-(void)dealloc{
    [mObservers removeAllObjects];
    [mObservers release];
    [playList removeAllObjects];
    [playList release];
    [mediaServer release];
    [container release];
//    [mediaRenderer release];

    [super dealloc];
}


-(NSInteger)addObserver:(MediaPlaylistObserver*)obs{
    NSInteger ret = 0;

    [mObservers addObject:obs];
    ret = [mObservers count];

    return ret;
}


-(NSInteger)removeObserver:(MediaPlaylistObserver*)obs{
    NSInteger ret = 0;

    [mObservers removeObject:obs];
    ret = [mObservers count];

    return ret;
}


-(NSInteger)loadWithMediaServer:(MediaServer1Device*)server forContainer:(MediaServer1ContainerObject*)selectedContainer{
    NSInteger ret = 0;

    //Sanity
    if(server == nil || selectedContainer == nil){
        return -1;
    }

    //Re-init
    [playList removeAllObjects];

    [mediaServer release];
    mediaServer = server;
    [mediaServer retain];

    [container release];
    container = selectedContainer;
    [container retain];



    //Browse the container & create the objects
    NSMutableString *outResult = [[NSMutableString alloc] init];
    NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
    NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
    NSMutableString *outUpdateID = [[NSMutableString alloc] init];


    ret = [[server contentDirectory] BrowseWithObjectID:[selectedContainer objectID] BrowseFlag:@"BrowseDirectChildren" Filter:@"*" StartingIndex:@"0" RequestedCount:@"0" SortCriteria:@"+dc:title" OutResult:outResult OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];
    if(ret == 0){
        @autoreleasepool {
            //Fill mediaObjects
            //Parse the return DIDL and store all entries as objects in the 'mediaObjects' array
            NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding];// NSASCIIStringEncoding
            MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:playList itemsOnly:YES];
            [parser parseFromData:didl];
            [parser release];
        }
    }


    [outResult release];
    [outNumberReturned release];
    [outTotalMatches release];
    [outUpdateID release];

    currentTrack = 0;

    state = MediaPlaylistState_Stopped;

    return ret;

}


-(NSInteger)setTrackByNumber:(int)track{
    if([playList count] > track){
        currentTrack = track;
    }else{
        return -1;
    }
    return currentTrack;
}

-(NSInteger)setTrackByID:(NSString*)objectID{
    MediaServer1ItemObject* lobj = nil;

    //Set the current track
    for(int t=0;t<[playList count];t++){
        lobj = playList[t];
        if( [[lobj objectID] isEqualToString:objectID]){
            currentTrack = t;
            break;
        }
    }

    return currentTrack;
}

-(NSInteger)nextTrack{
    if(state == MediaPlaylistState_Playing && [playList count] > currentTrack + 1){
        currentTrack++;
    }else{
        return -1;
    }
    return currentTrack;
}

-(NSInteger)prevTrack{
    if(state == MediaPlaylistState_Playing && [playList count] > currentTrack - 1){
        if(currentTrack > 0){
            currentTrack--;
        }
    }else{
        return -1;
    }
    return currentTrack;
}


-(NSInteger)stop{
    return [self changeState:MediaPlaylistState_Stopped];
}


-(NSInteger)play{
    return [self changeState:MediaPlaylistState_Playing];
}


-(NSInteger)changeState:(MediaPlaylistState)newState{
    NSInteger ret = 0;

    MediaPlaylistState oldState = state;

    switch(state){
        //Stop - > Play
        case MediaPlaylistState_Stopped:
            if(newState == MediaPlaylistState_Playing){
                state = newState;
            }
            break;
        //Play -> Stop
        case MediaPlaylistState_Playing:
            if(newState == MediaPlaylistState_Stopped){
                state = newState;
            }
            break;
        case MediaPlaylistState_NotInitialized:
        default:
            ret = -1;
            break;
    }

    if(oldState != state){
        MediaPlaylistObserver *obs = nil;
        NSEnumerator *listeners = [mObservers objectEnumerator];
        while((obs = [listeners nextObject])){
            [obs StateChanged:state];
        }
    }
    return ret;
}

-(MediaServer1ItemObject*)GetCurrentTrackItem{
    MediaServer1ItemObject *ret  = nil;

    if([playList count] > currentTrack){
        ret = playList[currentTrack];
    }

    return ret;
}

@end
