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


#import <Foundation/Foundation.h>
#import "MediaServer1Device.h"
//#import "MediaRenderer1Device.h"
#import "MediaServer1ContainerObject.h"
#import "MediaServer1ItemObject.h"


@class MediaPlaylistObserver, MediaPlaylist;

typedef enum MediaPlaylistState{
    MediaPlaylistState_NotInitialized = 0,
    MediaPlaylistState_Stopped,
    MediaPlaylistState_Playing
}MediaPlaylistState;

/**
 * Observer
 */
@protocol MediaPlaylistObserver
-(NSInteger)NewTrack:(MediaServer1ItemObject*)track;
-(void)StateChanged:(MediaPlaylistState)state;
@end


/**
 * Class
 */
@interface MediaPlaylist : NSObject {
    NSMutableArray *playList;//MediaServer1ItemObject[]
    int currentTrack;
    MediaServer1Device* mediaServer;
//    MediaRenderer1Device* mediaRenderer;
    MediaServer1ContainerObject* container;
    NSMutableArray *mObservers;//MediaPlaylistObserver[]
    MediaPlaylistState state;
}

-(NSInteger)addObserver:(id<MediaPlaylistObserver>)obs;
-(NSInteger)removeObserver:(id<MediaPlaylistObserver>)obs;

-(NSInteger)loadWithMediaServer:(MediaServer1Device*)server forContainer:(MediaServer1ContainerObject*)selectedContainer;

@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger stop;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger play;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger nextTrack;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger prevTrack;
-(NSInteger)setTrackByNumber:(int)track;
-(NSInteger)setTrackByID:(NSString*)objectID;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) MediaServer1ItemObject *GetCurrentTrackItem;

@property(readonly) NSMutableArray *playList;
@property(readonly) int currentTrack;
@property(readonly) MediaServer1Device* mediaServer;
@property(readonly) MediaServer1ContainerObject* container;
@property(readonly) MediaPlaylistState state;
//@property(readwrite, retain) MediaRenderer1Device* mediaRenderer;

@end
