/*****************************************************************************
 * VLCMediaPlayer.h: VLCKit.framework VLCMediaPlayer header
 *****************************************************************************
 * Copyright (C) 2007-2009 Pierre d'Herbemont
 * Copyright (C) 2007-2015 VLC authors and VideoLAN
 * Copyright (C) 2009-2015 Felix Paul Kühne
 * $Id$
 *
 * Authors: Pierre d'Herbemont <pdherbemont # videolan.org>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Soomin Lee <TheHungryBu # gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
# import <CoreGraphics/CoreGraphics.h>
# import <UIKit/UIKit.h>
#endif
#import "VLCMedia.h"
#import "VLCTime.h"
#import "VLCAudio.h"

#if !TARGET_OS_IPHONE
@class VLCVideoView;
@class VLCVideoLayer;
#endif

@class VLCLibrary;
@class VLCRendererItem;

/* Notification Messages */
extern NSString *const VLCMediaPlayerTimeChanged;
extern NSString *const VLCMediaPlayerStateChanged;
extern NSString *const VLCMediaPlayerTitleChanged;
extern NSString *const VLCMediaPlayerChapterChanged;

/**
 * VLCMediaPlayerState describes the state of the media player.
 */
typedef NS_ENUM(NSInteger, VLCMediaPlayerState)
{
    VLCMediaPlayerStateStopped,        ///< Player has stopped
    VLCMediaPlayerStateOpening,        ///< Stream is opening
    VLCMediaPlayerStateBuffering,      ///< Stream is buffering
    VLCMediaPlayerStateEnded,          ///< Stream has ended
    VLCMediaPlayerStateError,          ///< Player has generated an error
    VLCMediaPlayerStatePlaying,        ///< Stream is playing
    VLCMediaPlayerStatePaused,         ///< Stream is paused
    VLCMediaPlayerStateESAdded         ///< Elementary Stream added
};

/**
 * VLCMediaPlaybackNavigationAction describes actions which can be performed to navigate an interactive title
 */
typedef NS_ENUM(unsigned, VLCMediaPlaybackNavigationAction)
{
    VLCMediaPlaybackNavigationActionActivate = 0,
    VLCMediaPlaybackNavigationActionUp,
    VLCMediaPlaybackNavigationActionDown,
    VLCMediaPlaybackNavigationActionLeft,
    VLCMediaPlaybackNavigationActionRight
};

/**
 * Returns the name of the player state as a string.
 * \param state The player state.
 * \return A string containing the name of state. If state is not a valid state, returns nil.
 */
extern NSString * VLCMediaPlayerStateToString(VLCMediaPlayerState state);

/**
 * Formal protocol declaration for playback delegates.  Allows playback messages
 * to be trapped by delegated objects.
 */
@protocol VLCMediaPlayerDelegate

@optional
/**
 * Sent by the default notification center whenever the player's state has changed.
 * \details Discussion The value of aNotification is always an VLCMediaPlayerStateChanged notification. You can retrieve
 * the VLCMediaPlayer object in question by sending object to aNotification.
 */
- (void)mediaPlayerStateChanged:(NSNotification *)aNotification;

/**
 * Sent by the default notification center whenever the player's time has changed.
 * \details Discussion The value of aNotification is always an VLCMediaPlayerTimeChanged notification. You can retrieve
 * the VLCMediaPlayer object in question by sending object to aNotification.
 */
- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification;

/**
 * Sent by the default notification center whenever the player's title has changed (if any).
 * \details Discussion The value of aNotification is always an VLCMediaPlayerTitleChanged notification. You can retrieve
 * the VLCMediaPlayer object in question by sending object to aNotification.
 * \note this is about a title in the navigation sense, not about metadata
 */
- (void)mediaPlayerTitleChanged:(NSNotification *)aNotification;

/**
 * Sent by the default notification center whenever the player's chapter has changed (if any).
 * \details Discussion The value of aNotification is always an VLCMediaPlayerChapterChanged notification. You can retrieve
 * the VLCMediaPlayer object in question by sending object to aNotification.
 */
- (void)mediaPlayerChapterChanged:(NSNotification *)aNotification;

#if TARGET_OS_PHONE
/**
 * Sent by the default notification center whenever a new snapshot is taken.
 * \details Discussion The value of aNotification is always an VLCMediaPlayerSnapshotTaken notification. You can retrieve
 * the VLCMediaPlayer object in question by sending object to aNotification.
 */
- (void)mediaPlayerSnapshot:(NSNotification *)aNotification;
#endif

@end


/**
 * The player base class needed to do any playback
 */
@interface VLCMediaPlayer : NSObject

/**
 * the library instance in use by the player instance
 */
@property (nonatomic, readonly) VLCLibrary *libraryInstance;
/**
 * the delegate object implementing the optional protocol
 */
@property (weak, nonatomic) id<VLCMediaPlayerDelegate> delegate;

#if !TARGET_OS_IPHONE
/* Initializers */
/**
 * initialize player with a given video view
 * \param aVideoView an instance of VLCVideoView
 * \note This initializer is for macOS only
 */
- (instancetype)initWithVideoView:(VLCVideoView *)aVideoView;
/**
 * initialize player with a given video layer
 * \param aVideoLayer an instance of VLCVideoLayer
 * \note This initializer is for macOS only
 */
- (instancetype)initWithVideoLayer:(VLCVideoLayer *)aVideoLayer;
#endif
/**
 * initialize player with a given set of options
 * \param options an array of private options
 * \note This will allocate a new libvlc and VLCLibrary instance, which will have a memory impact
 */
- (instancetype)initWithOptions:(NSArray *)options;
/**
 * initialize player with a certain libvlc instance and VLCLibrary
 * \param playerInstance the libvlc instance
 * \param library the library instance
 * \note This is an advanced initializer for very specialized environments
 */
- (instancetype)initWithLibVLCInstance:(void *)playerInstance andLibrary:(VLCLibrary *)library;

/* Video View Options */
// TODO: Should be it's own object?

#pragma mark -
#pragma mark video functionality

#if !TARGET_OS_IPHONE
/**
 * set a video view for rendering
 * \param aVideoView instance of VLCVideoView
 * \note This setter is macOS only
 */
- (void)setVideoView:(VLCVideoView *)aVideoView;
/**
 * set a video layer for rendering
 * \param aVideoLayer instance of VLCVideoLayer
 * \note This setter is macOS only
 */
- (void)setVideoLayer:(VLCVideoLayer *)aVideoLayer;
#endif

/**
 * set/retrieve a video view for rendering
 * This can be any UIView or NSView or instances of VLCVideoView / VLCVideoLayer if running on macOS
 */
@property (strong) id drawable; /* The videoView or videoLayer */

/**
 * Set/Get current video aspect ratio.
 *
 * param: psz_aspect new video aspect-ratio or NULL to reset to default
 * \note Invalid aspect ratios are ignored.
 * \return the video aspect ratio or NULL if unspecified
 * (the result must be released with free()).
 */
@property (NS_NONATOMIC_IOSONLY) char *videoAspectRatio;

/**
 * Set/Get current crop filter geometry.
 *
 * param: psz_geometry new crop filter geometry (NULL to unset)
 * \return the crop filter geometry or NULL if unset
 */
@property (NS_NONATOMIC_IOSONLY) char *videoCropGeometry;

/**
 * Set/Get the current video scaling factor.
 * That is the ratio of the number of pixels on
 * screen to the number of pixels in the original decoded video in each
 * dimension. Zero is a special value; it will adjust the video to the output
 * window/drawable (in windowed mode) or the entire screen.
 *
 * param: relative scale factor as float
 */
@property (nonatomic) float scaleFactor;

/**
 * Take a snapshot of the current video.
 *
 * If width AND height is 0, original size is used.
 * If width OR height is 0, original aspect-ratio is preserved.
 *
 * \param path the path where to save the screenshot to
 * \param width the snapshot's width
 * \param height the snapshot's height
 */
- (void)saveVideoSnapshotAt:(NSString *)path withWidth:(int)width andHeight:(int)height;

/**
 * Enable or disable deinterlace filter
 *
 * \param name of deinterlace filter to use (availability depends on underlying VLC version), NULL to disable.
 */
- (void)setDeinterlaceFilter: (NSString *)name;

/**
 * Enable or disable adjust video filter (contrast, brightness, hue, saturation, gamma)
 *
 * \return bool value
 */
@property (nonatomic) BOOL adjustFilterEnabled;
/**
 * Set/Get the adjust filter's contrast value
 *
 * \return float value (range: 0-2, default: 1.0)
 */
@property (nonatomic) float contrast;
/**
 * Set/Get the adjust filter's brightness value
 *
 * \return float value (range: 0-2, default: 1.0)
 */
@property (nonatomic) float brightness;
/**
 * Set/Get the adjust filter's hue value
 *
 * \return float value (range: -180-180, default: 0.)
 */
@property (nonatomic) float hue;
/**
 * Set/Get the adjust filter's saturation value
 *
 * \return float value (range: 0-3, default: 1.0)
 */
@property (nonatomic) float saturation;
/**
 * Set/Get the adjust filter's gamma value
 *
 * \return float value (range: 0-10, default: 1.0)
 */
@property (nonatomic) float gamma;

/**
 * Get the requested movie play rate.
 * @warning Depending on the underlying media, the requested rate may be
 * different from the real playback rate. Due to limitations of some protocols
 * this option may not be taken into account at all, if set.
 *
 * \return movie play rate
 */
@property (nonatomic) float rate;

/**
 * an audio controller object
 * \return instance of VLCAudio
 */
@property (nonatomic, readonly, weak) VLCAudio * audio;

/* Video Information */
/**
 * Get the current video size
 * \return video size as CGSize
 */
@property (NS_NONATOMIC_IOSONLY, readonly) CGSize videoSize;

/**
 * Does the current media have a video output?
 * \note a false return value doesn't mean that the video doesn't have any video
 * \note tracks. Those might just be disabled.
 * \return current video output status
 */
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasVideoOut;

/**
 * Frames per second
 * \deprecated provided for API compatibility only, to retrieve a media's FPS, use VLCMediaTracksInformationFrameRate.
 * \returns 0
 */
@property (NS_NONATOMIC_IOSONLY, readonly) float framesPerSecond __attribute__((deprecated));

#pragma mark -
#pragma mark time

/**
 * Sets the current position (or time) of the feed.
 * \param value New time to set the current position to.  If time is [VLCTime nullTime], 0 is assumed.
 */

/**
 * Returns the current position (or time) of the feed.
 * \return VLCTime object with current time.
 */
@property (NS_NONATOMIC_IOSONLY, strong) VLCTime *time;

/**
 * Returns the current position (or time) of the feed, inversed if a duration is available
 * \return VLCTime object with requested time
 * \note VLCTime will be a nullTime if no duration can be calculated for the current input
 */
@property (nonatomic, readonly, weak) VLCTime *remainingTime;

#pragma mark -
#pragma mark ES track handling

/**
 * Return the current video track index
 *
 * \return 0 if none is set.
 *
 * Pass -1 to disable.
 */
@property (readwrite) int currentVideoTrackIndex;

/**
 * Returns the video track names, usually a language name or a description
 * It includes the "Disabled" fake track at index 0.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *videoTrackNames;

/**
 * Returns the video track IDs
 * those are needed to set the video index
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *videoTrackIndexes;

/**
 * returns the number of video tracks available in the current media
 * \return number of tracks
 */
@property (NS_NONATOMIC_IOSONLY, readonly) int numberOfVideoTracks;

/**
 * Return the current video subtitle index
 *
 * \return 0 if none is set.
 *
 * Pass -1 to disable.
 */
@property (readwrite) int currentVideoSubTitleIndex;

/**
 * Returns the video subtitle track names, usually a language name or a description
 * It includes the "Disabled" fake track at index 0.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *videoSubTitlesNames;

/**
 * Returns the video subtitle track IDs
 * those are needed to set the video subtitle index
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *videoSubTitlesIndexes;

/**
 * returns the number of SPU tracks available in the current media
 * \return number of tracks
 */
@property (NS_NONATOMIC_IOSONLY, readonly) int numberOfSubtitlesTracks;

/**
 * Load and set a specific video subtitle, from a file.
 *
 * \deprecated use addPlaybackSlave:type:enforce: instead
 */
- (BOOL)openVideoSubTitlesFromFile:(NSString *)path __attribute__((deprecated));

/**
 * VLCMediaPlaybackNavigationAction describes actions which can be performed to navigate an interactive title
 */
typedef NS_ENUM(unsigned, VLCMediaPlaybackSlaveType)
{
    VLCMediaPlaybackSlaveTypeSubtitle = 0,
    VLCMediaPlaybackSlaveTypeAudio
};

/**
 * Add additional input sources to a playing media item
 * This way, you can add subtitles or audio files to an existing input stream
 * For the user, it will appear as if they were part of the existing stream
 * \param slaveURL of the content to be added
 * \param slaveType content type
 * \param enforceSelection switch to the added accessory content
 */
- (int)addPlaybackSlave:(NSURL *)slaveURL type:(VLCMediaPlaybackSlaveType)slaveType enforce:(BOOL)enforceSelection;

/**
 * Get the current subtitle delay. Positive values means subtitles are being
 * displayed later, negative values earlier.
 *
 * \return time (in microseconds) the display of subtitles is being delayed
 */
@property (readwrite) NSInteger currentVideoSubTitleDelay;

/**
 * Chapter selection and enumeration, it is bound
 * to a title option.
 */

/**
 * Return the current chapter index, or
 * \return NSNotFound if none is set.
 */
@property (readwrite) int currentChapterIndex;
/**
 * switch to the previous chapter
 */
- (void)previousChapter;
/**
 * switch to the next chapter
 */
- (void)nextChapter;
/**
 * returns the number of chapters for a given title
 * \param titleIndex the index of the title you are requesting the chapters for
 */
- (int)numberOfChaptersForTitle:(int)titleIndex;

/**
 * Chapters of a given title index
 * \deprecated Use chapterDescriptionsOfTitle instead
 */
- (NSArray *)chaptersForTitleIndex:(int)titleIndex __attribute__((deprecated));

/**
 * dictionary value for the user-facing chapter name
 */
extern NSString *const VLCChapterDescriptionName;
/**
 * dictionary value for the chapter's time offset
 */
extern NSString *const VLCChapterDescriptionTimeOffset;
/**
 * dictionary value for the chapter's duration
 */
extern NSString *const VLCChapterDescriptionDuration;

/**
 * chapter descriptions
 * an array of all chapters of the given title including information about
 * chapter name, time offset and duration
 * \note if no title value is provided, information about the chapters of the current title is returned
 * \return array describing the titles in details
 * \see VLCChapterDescriptionName
 * \see VLCChapterDescriptionTimeOffset
 * \see VLCChapterDescriptionDuration
 */
- (NSArray *)chapterDescriptionsOfTitle:(int)titleIndex;

/**
 * Title selection and enumeration
 * \return NSNotFound if none is set.
 */
@property (readwrite) int currentTitleIndex;
/**
 * number of titles available for the current media
 * \return the number of titles
 */
@property (readonly) int numberOfTitles;

/**
 * count of titles
 * \deprecated Use numberOfTitles instead
 */
@property (readonly) NSUInteger countOfTitles __attribute__((deprecated));
/**
 * array of available titles
 * \deprecated Use titleDescriptions instead
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *titles __attribute__((deprecated));

/**
 * dictionary value for the user-facing title name
 */
extern NSString *const VLCTitleDescriptionName;
/**
 * dictionary value for the title's duration
 */
extern NSString *const VLCTitleDescriptionDuration;
/**
 * dictionary value whether the title is a menu or not
 */
extern NSString *const VLCTitleDescriptionIsMenu;

/**
 * title descriptions
 * an array of all titles of the current media including information
 * of name, duration and potential menu state
 * \return array describing the titles in details
 * \see VLCTitleDescriptionName
 * \see VLCTitleDescriptionDuration
 * \see VLCTitleDescriptionIsMenu
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *titleDescriptions;

/**
 * the title with the longest duration
 * \return int matching the title index
 */
@property (readonly) int indexOfLongestTitle;

/* Audio Options */

/**
 * Return the current audio track index
 *
 * \return 0 if none is set.
 *
 * Pass -1 to disable.
 */
@property (readwrite) int currentAudioTrackIndex;

/**
 * Returns the audio track names, usually a language name or a description
 * It includes the "Disabled" fake track at index 0.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *audioTrackNames;

/**
 * Returns the audio track IDs
 * those are needed to set the video index
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *audioTrackIndexes;

/**
 * returns the number of audio tracks available in the current media
 * \return number of tracks
 */
@property (NS_NONATOMIC_IOSONLY, readonly) int numberOfAudioTracks;

#pragma mark -
#pragma mark audio functionality

/**
 * sets / returns the current audio channel
 * \return the currently set audio channel
 */
@property (NS_NONATOMIC_IOSONLY) int audioChannel;

/**
 * Get the current audio delay. Positive values means audio is delayed further,
 * negative values less.
 *
 * \return time (in microseconds) the audio playback is being delayed
 */
@property (readwrite) NSInteger currentAudioPlaybackDelay;

#pragma mark -
#pragma mark equalizer

/**
 * Get a list of available equalizer profiles
 * \note Current versions do not allow the addition of further profiles
 *       so you need to handle this in your app.
 *
 * \return array of equalizer profiles
 */
@property (weak, readonly) NSArray *equalizerProfiles;

/**
 * Re-set the equalizer to a profile retrieved from the list
 * \note This doesn't enable the Equalizer automagically
 */
- (void)resetEqualizerFromProfile:(unsigned)profile;

/**
 * Toggle equalizer state
 * param: bool value to enable/disable the equalizer
 * \return current state */
@property (readwrite) BOOL equalizerEnabled;

/**
 * Set amplification level
 * param: The supplied amplification value will be clamped to the -20.0 to +20.0 range.
 * \note this will create and enabled an Equalizer instance if not present
 * \return current amplification level */
@property (readwrite) CGFloat preAmplification;

/**
 * Number of equalizer bands
 * \return the number of equalizer bands available in the current release */
@property (readonly) unsigned numberOfBands;

/**
 * frequency of equalizer band
 * \param index the band index
 * \return frequency of the requested equalizer band */
- (CGFloat)frequencyOfBandAtIndex:(unsigned)index;

/**
 * set amplification for band
 * \param amplification value (clamped to the -20.0 to +20.0 range)
 * \param index of the respective band */
- (void)setAmplification:(CGFloat)amplification forBand:(unsigned)index;

/**
 * amplification of band
 * \param index of the band
 * \return current amplification value (clamped to the -20.0 to +20.0 range) */
- (CGFloat)amplificationOfBand:(unsigned)index;

#pragma mark -
#pragma mark media handling

/* Media Options */
/**
 * The currently media instance set to play
 */
@property (NS_NONATOMIC_IOSONLY, strong) VLCMedia *media;

#pragma mark -
#pragma mark playback operations
/**
 * Plays a media resource using the currently selected media controller (or
 * default controller. If feed was paused then the feed resumes at the position
 * it was paused in.
 */
- (void)play;

/**
 * Set the pause state of the feed. Do nothing if already paused.
 */
- (void)pause;

/**
 * Stop the playing.
 */
- (void)stop;

/**
 * Advance one frame.
 */
- (void)gotoNextFrame;

/**
 * Fast forwards through the feed at the standard 1x rate.
 */
- (void)fastForward;

/**
 * Fast forwards through the feed at the rate specified.
 * \param rate Rate at which the feed should be fast forwarded.
 */
- (void)fastForwardAtRate:(float)rate;

/**
 * Rewinds through the feed at the standard 1x rate.
 */
- (void)rewind;

/**
 * Rewinds through the feed at the rate specified.
 * \param rate Rate at which the feed should be fast rewound.
 */
- (void)rewindAtRate:(float)rate;

/**
 * Jumps shortly backward in current stream if seeking is supported.
 * \param interval to skip, in sec.
 */
- (void)jumpBackward:(int)interval;

/**
 * Jumps shortly forward in current stream if seeking is supported.
 * \param interval to skip, in sec.
 */
- (void)jumpForward:(int)interval;

/**
 * Jumps shortly backward in current stream if seeking is supported.
 */
- (void)extraShortJumpBackward;

/**
 * Jumps shortly forward in current stream if seeking is supported.
 */
- (void)extraShortJumpForward;

/**
 * Jumps shortly backward in current stream if seeking is supported.
 */
- (void)shortJumpBackward;

/**
 * Jumps shortly forward in current stream if seeking is supported.
 */
- (void)shortJumpForward;

/**
 * Jumps shortly backward in current stream if seeking is supported.
 */
- (void)mediumJumpBackward;

/**
 * Jumps shortly forward in current stream if seeking is supported.
 */
- (void)mediumJumpForward;

/**
 * Jumps shortly backward in current stream if seeking is supported.
 */
- (void)longJumpBackward;

/**
 * Jumps shortly forward in current stream if seeking is supported.
 */
- (void)longJumpForward;

/**
 * performs navigation actions on interactive titles
 */
- (void)performNavigationAction:(VLCMediaPlaybackNavigationAction)action;

/**
 * Updates viewpoint with given values.
 * \param yaw new yaw.
 * \param pitch new pitch.
 * \param roll new roll.
 * \param fov new field of view.
 * \param absolute if true replace the old viewpoint with the new one. If
 * false, increase/decrease it.
 * \note This will create a viewpoint instance if not present.
 */
- (BOOL)updateViewpoint:(CGFloat)yaw pitch:(CGFloat)pitch roll:(CGFloat)roll fov:(CGFloat)fov absolute:(BOOL)absolute;

#pragma mark -
#pragma mark playback information
/**
 * Playback state flag identifying that the stream is currently playing.
 * \return TRUE if the feed is playing, FALSE if otherwise.
 */
@property (NS_NONATOMIC_IOSONLY, getter=isPlaying, readonly) BOOL playing;

/**
 * Playback state flag identifying wheather the stream will play.
 * \return TRUE if the feed is ready for playback, FALSE if otherwise.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL willPlay;

/**
 * Playback's current state.
 * \see VLCMediaState
 */
@property (NS_NONATOMIC_IOSONLY, readonly) VLCMediaPlayerState state;

/**
 * Returns the receiver's position in the reading.
 * \return movie position as percentage between 0.0 and 1.0.
 */
@property (NS_NONATOMIC_IOSONLY) float position;

/**
 * Set movie position. This has no effect if playback is not enabled.
 * \note movie position as percentage between 0.0 and 1.0.
 */
@property (NS_NONATOMIC_IOSONLY, getter=isSeekable, readonly) BOOL seekable;

/**
 * property whether the currently playing media can be paused (or not)
 * \return BOOL value
 */
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL canPause;

#if TARGET_OS_IPHONE
/**
 * Array of taken snapshots of the current video output
 * \return a NSArray of UIImage instances
 * \note This property is not available to macOS
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *snapshots;

/**
 * Get last snapshot available.
 * \return an UIImage with the last snapshot available.
 * \note return value is nil if there is no snapshot
 * \note This property is not available to macOS
 */
@property (NS_NONATOMIC_IOSONLY, readonly) UIImage *lastSnapshot;
#endif

#pragma mark -
#pragma mark Renderer

/**
 * Sets a `VLCRendererItem` to the current media player
 * \param item `VLCRendererItem` discovered by `VLCRendererDiscoverer`
 * \return `YES` if successful, `NO` otherwise
 * \note Must be called before the first call of `play` to take effect
 * \see VLCRendererDiscoverer
 * \see VLCRendererItem
 */
- (BOOL)setRendererItem:(VLCRendererItem *)item;

@end
