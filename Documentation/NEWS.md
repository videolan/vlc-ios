# Changelog

## iOS [3.5.0]
· Add new playback history feature
· Remember playback position and state for media on network servers and external devices
· Cache generated artwork for external media
· Add Siri integration to control playback in VLC and access locally stored media
· Allow folders on remote shares to be marked as favorites
· Add support for external subtitles and audio tracks
· Improve playback speed configuration for the audio player
· Allow deleting local media during search
· Show playlist durations in list view
· Add options for more flexible gesture controls during playback
· Add missing mka support declaration

## tvOS [3.5.0]
· Fix the display of media's artworks for audio playback.

## iOS [3.4.9]
· Noticable stability improvements
· Fix distortion when playing MP3 media
· VLC core update to version 3.0.19
· Fix issue where the last frame remained visible on playback end
· Playback starts with the selected media even in shuffle mode
· Playback is no longer continued from the last position in loop mode
· New translation to Georgian and updated to Korean and Slovenian

## tvOS [3.4.9]
· Noticable stability improvements
· Fix distortion when playing MP3 media
· VLC core update to version 3.0.19
· Fix issue where the last frame remained visible on playback end
· New translation to Georgian and updated to Korean and Slovenian

## iOS [3.4.8]
· Second attempt to fix the heating problem
· Fix shuffle behavior
· Fix playback continuation for audio content
· Fix failed start of audio content chosen from a list
· Fix bookmark appearance on iOS 12 and earlier
· Audio player: add support for device rotation
· Player: add swipe gestures to minimize more easily
· Improved accessibility for the audio player

## tvOS [3.4.8]
· Second attempt to fix the heating problem

## iOS [3.4.7]
· Attempt to fix the heating problem
· Updates to the audio player UI

## tvOS [3.4.7]
· Attempt to fix the heating problem

## iOS [3.4.6]
· Preserve repeat mode
· Restore chapter support for audio-only media
· Hide status bar in fullscreen mode with the dark UI appearance
· Further UI improvements

## iOS [3.4.5]
· Fix playing multiple items in a row in the requested order
· Fix minor layout issues

## tvOS [3.4.5]
· Fix playing multiple items in a row in the requested order

## iOS [3.4.4]
· Fix opening media from third party apps on iOS 13 and later
· Fix audio player performance and layout issues
· Fix rotation lock feature
· Logic and stability improvements, notably for the CarPlay integration

## tvOS [3.4.4]
· Logic and stability improvements

## iOS [3.4.3]
· Fix playback of audio-only media on iOS 9 and 10

## iOS [3.4.2]
· Fix playback on external displays including AirPlay on iOS 13 to 15
· Fix audio playback quality regression for mp3, ALAC and Apple Core Audio Format
· Last playback position is now retained when the app is killed
· Memory optimizations for audio playback
· Equalizer and pre-amp behavior improvements
    · if sounds is too low for you now, enable the pre-amp in settings
· Fix performance issue within UPnP discovery
· Improve CarPlay layouts

## tvOS [3.4.2]
· Fix audio playback quality regression for mp3, ALAC and Apple Core Audio Format
· Equalizer and pre-amp behavior improvements
    · if sounds is too low for you now, enable the pre-amp in settings
· Fix performance issue within UPnP discovery

## iOS [3.4.1]
· Fix playback on external displays including AirPlay
· Fix crash when searching within the audio section of the media library
· Fix intermittent black screens during video playback, especially lists
· Fix playback of playlists and certain radio / TV streams
· Fix login to and download from OneDrive
· Improve behavior of the close button during playback
· Fix crash when exporting media to other apps

## tvOS [3.4.1]
· Add ability to rename previously played network streams
· Fix multiple alignment issues in the playback interface
· Fix playback of playlists and certain radio / TV streams

## iOS [3.4.0]
· Add new audio playback UI
· Add support for CarPlay
· Add views for artists, albums and episodes to the media library
· Add more options to sort the media library
· Add support for bookmarks
· Add a way to contact us through the About dialog
· Improve shuffle algorithm for playback
· Indicate currently playing media in library
· Major update to internal event handling
· Performance improvements
· Add Handoff and Ethernet support for WiFi Sharing
· Add option to configure seek duration
· Rewritten OneDrive support
· Updated UPnP support
· Add information screens for complex settings
· Remove the 'variable jump duration' feature
· Add custom seek duration options
· Show media dimensions in library screen
· Add optional display of album track numbers to library screen
· Videos can be played as audio only now
· Improve login experience to box.com
· Major adaptive streaming update, notably for multiple timelies and webvtt
· Add support for DVBSub inside MKV
· Fix flac audio quality regression
· Fix some flac files that could not be played
· Improve seeking in Ogg and fragmented MP4 files
· Fix styling issues with subs tx3g (mp4) tracks
· Fix playback of live AV1 streams
· Fix crashes with VP9 streams

## tvOS [3.4.0]
· Add support for network streams distributed using MDM
· Improve remote gestures during playback
· Improve support for single click mode of the Apple Remote
· Multiple UI improvements for playback, browsing and networking
· Major update to internal event handling
· Performance improvements
· Add Handoff and Ethernet support for WiFi Sharing
· Updated UPnP support
· Major adaptive streaming update, notably for multiple timelies and webvtt
· Add support for DVBSub inside MKV
· Fix flac audio quality regression
· Fix some flac files that could not be played
· Improve seeking in Ogg and fragmented MP4 files
· Fix styling issues with subs tx3g (mp4) tracks
· Fix playback of live AV1 streams
· Fix crashes with VP9 streams

## iOS [3.3.12]
· Fix playback of certain network streams
· Stability improvements

## tvOS [3.3.12]
· Fix playback of certain network streams
· Stability improvements

## iOS [3.3.11]
· Fix browsing of Google Drive shares
· Update libvlc to version 3.0.18
· Major adaptive streaming update
· Many updates of third party libraries
· Minor UI and accessbility improvements
· Stability improvements

## tvOS [3.3.11]
· Update libvlc to version 3.0.18
· Major adaptive streaming update
· Many updates of third party libraries
· Stability improvements

## iOS [3.3.10]
· Add option to configure pre-amp level
· Improve accessibility of playback speed buttons
· Stability improvements

## tvOS [3.3.10]
· Add option to configure pre-amp level
· Stability improvements

## iOS [3.3.9]
· Fix UPnP discovery on iOS 16 and later

## tvOS [3.3.9]
· Fix UPnP discovery on tvOS 16 and later

## iOS [3.3.8]
· Fix PLEX server discovery using Bonjour
· Fix progress reporting for http downloads
· Fix x-callback-url issue displaying the wrong subtitles
· Set default pre-amp level to 0 to render full dynamic range
· Improve volume and brightness gestures sensibility especially on iPad
· Migrate Google Drive login flow to continue to work after October 3rd

## tvOS [3.3.8]
· Fix PLEX server discovery using Bonjour
· Fix x-callback-url issue displaying the wrong subtitles
· Set default pre-amp level to 0 to render full dynamic range

## iOS [3.3.7]
· layout improvements for playback subpanels
· stability and speed improvements

## tvOS [3.3.7]
· stability and speed improvements

## iOS [3.3.6]
· fix minor regression from previous update

## iOS [3.3.5]
· add shuffle / repeat actions to the playback screen's more button
· list recently downloaded media
· fix playback of media larger than 2 GB on some SMB2 shares
· fix crash when accessing SMB2 shares without a password set
· minor performance and appearance improvements

## tvOS [3.3.5]
· fix playback of media larger than 2 GB on some SMB2 shares
· fix crash when accessing SMB2 shares without a password set
· minor performance and appearance improvements

## iOS [3.3.4]
· fix display of the Chinese (simplified) translation in Settings when in mainland China
· fix default playback speed option
· improve appearance of cloud sharing services
· update SMB2 stack
· fix subtitles storage for media imported from other apps or stored outside the app

## tvOS [3.3.4]
· fix playback from SMB when playing a singular file
· add downloads from Apple TV using the web interface
· update SMB2 stack

## iOS [3.3.3]
· allow delaying subtitles and audio up to 30s instead of 5s
· fix integration with OpenSubtitles.org
· fix opening certain streams from third party apps via x-callback-url
· remember shuffle/loop states across playback sessions
· various minor UI improvements

## tvOS [3.3.3]
· various minor UI improvements
· fix integration with OpenSubtitles.org

## iOS [3.3.2]
· Fix colorspace handling error introduced in the last update

## tvOS [3.3.2]
· Fix colorspace handling error introduced in the last update

## iOS [3.3.1]
· Fix UPnP server browsing issue on IPv4/IPv6 dual stack networks
· Improve SMB compatiblity
· Fix frequent crashes when SMBv1 shares are discovered on the local network
· Prevent automatic renaming of files downloaded from Dropbox
· Fix display of 'Now Playing' metadata
· Show individual UPnP server icons
· Web interface preferably runs on IPv4 instead of IPv6 interfaces
· Fix renaming stored network streams
· Improve network stream opening UI for small devices
· Fix issues listing downloable subtitles
· Fix listing more than 200 items on OneDrive shares

## tvOS [3.3.1]
· Fix UPnP server browsing issue on IPv4/IPv6 dual stack networks
· Improve SMB compatiblity
· Fix frequent crashes when SMBv1 shares are discovered on the local network
· Fix playback of URLs shared through the web interface
· Fix playback of the first file received through the web interface
· Web interface preferably runs on IPv4 instead of IPv6 interfaces
· Add option to run the web interface on IPv6 interfaces
· Show individual UPnP server icons

## iOS [3.3.0]

· Add new video player interface
· Add support to browse NFS and SFTP shares
· Replace previous UPnP integration with VLC's native support based on libupnp
  · this improves compatibility with off-standard UPnP servers
· Replace previous FTP integration with VLC's native support
  · this improves compatibility with servers using non-western text encodings
    and allows connections to servers with off-standard port configurations
· Add downloads from SMB servers
· Add support for http(s) downloads from servers requiring authentication
· Add grid layout for Audio library
· Major speed and performance improvements avoiding heating issues
· Fix storing user credentials for network shares
· Retain downloaded subtitles for locally stored media
· Automatic video deinterlacing (by default)
· Retain last opened media category
· Add support for Files.app as a source to open media without importing to VLC
  · This allows playback from external devices, too!
· Add a queue view controller to switch between scheduled media items and for TV channel listings
· Add a full black theme for OLED devices
· Add rtsp-tcp option
· Add support for spatial audio with AirPods Pro and Max
· library: allow sorting tracks and albums by insertion date
· playback: allow up to 8x playback speed
· video: modify white point adaptation mode on modern iOS devices
· Add support for SAT>IP including custom channel lists
· Clicking previous during playback now resets the playback position instead of directly going
  to the previous item in list
· Add Select-All feature to media library screens
· Fix listing large number of media in Google Drive and Dropbox folders
· Major UI speed improvements for older iOS devices
· VLC still supports all devices running iOS 9.0 or later!

## tvOS [3.3.0]

· Major speed and performance improvements avoiding heating issues
· Add support to browse NFS and SFTP shares
· Replace previous UPnP integration with VLC's native support based on libupnp
  · this improves compatibility with off-standard UPnP servers
· Replace previous FTP integration with VLC's native support
  · this improves compatibility with servers using non-western text encodings
    and allows connections to servers with off-standard port configurations
· Fix storing user credentials for network shares, notably SMB
· Retain downloaded subtitles for locally stored media
· Automatic video deinterlacing (by default)
· Add rtsp-tcp option
· Add support for spatial audio with AirPods Pro and Max
· Add support for SAT>IP including custom channel lists
· Clicking previous during playback now resets the playback position instead of directly going
  to the previous item in list

## iOS [3.2.13]

· Add support for SMBv3
· Fix authentication regression with SMBv2 servers
· Fix DNS lookup regression with SMBv2 servers on IPv6-capable networks
· Fix login to Box.com

## tvOS [3.0.12]

· Add support for SMBv3
· Fix authentication regression with SMBv2 servers
· Fix DNS lookup regression with SMBv2 servers on IPv6-capable networks

## iOS [3.2.12]

· Fix playback of 10bit and 12bit content encoded in HEVC or AVC on iOS 14 and later

## tvOS [3.0.11]

· Fix playback of 10bit and 12bit content encoded in HEVC or AVC on tvOS 14 and later

## iOS [3.2.11]

· Fix adding new item to playlists
· Update Dutch translation

## tvOS [3.0.10]

· Fix subtitle display for tracks embedded in MKV files

## iOS [3.2.10]

· Fix subtitle display for tracks embedded in MKV files
· Minor UI fix

## tvOS [3.0.9]

· Fix repeat button appearance on tvOS 13 and later
· Fix Remote Playback on IPv6-only networks
· Prevent screensaver from appearing during Remote Playback sessions
· Greatly improve AV1 decoding performance by updating dav1d
· Improve adaptive streaming behavior
· Improve seeking accuracy for certain mp4 media
· Fix silence after pausing video playback

## iOS [3.2.9]

· Add option to enable Chromecast audio passthrough
· Fix adding media to existing playlists
· Fix WiFi sharing on IPv6-only networks
· Greatly improve AV1 decoding performance by updating dav1d
· Improve adaptive streaming behavior
· Improve seeking accuracy for certain mp4 media
· Fix silence after pausing video playback

## iOS [3.2.8]

· Add support to create media groups manually
· Port subtitles support from tvOS
· Fix potential Files app hiding issue
· Improve application startup time
· Improve sharing of the library on the local network between multiple VLCs
· Minor UI improvements and fixes

## tvOS [3.0.7]

· Fix artwork display
· Fix crashes when navigating network shares
· Minor UI improvements and fixes

## iOS [3.2.7]

This is a bug fix release, we are actively working on media groups.

· Fix streaming content on Google Drive
· Add passcode protection for WiFi Sharing
· Re-add more granular playback speed control
· Display file size information in Edit mode
· Fix repeating media when shuffle is disabled
· Fix uploads of media larger than 10 GB via WiFi
· Fix storage of recent network streams without iCloud
· Fix random playback control through lock screen
· Fix progress display for downloads via FTP
· Fix missing Share sheet on iPad
· Fix Chromecast button not to show in some cases
· Minor UI improvements and fixes

## tvOS [3.0.7]

· Update codecs and networking libraries
· Fix audio playback delay with external accessories
· Minor UI improvements by deploying the current SDK

## iOS [3.2.6]

· Fix media title display
· Fix Box session storage

## iOS [3.2.5]

· Add setting to enable/disable media library iCloud backup
· Add snap to playback speed with haptic feedback
· Improve overall iOS 9 stability
· Update media thumbnail after playback
· Fix UPnP CPU usage issue
· Fix potential crash with Plex
· Fix repeat all mode in playback
· Fix thumbnail generation on iOS 9
· Fix media library backup on iCloud
· Fix cloud services connected account count
· Fix launch of media playback during a playback
· Fix unknown and various artists addition and deletion
· Fix potential crash while deleting an audio collection

## iOS [3.2.4]

· Fix iOS 9 audio playback issues
· Improve the edit mode toolbar, following user feedback
· Add import for all supported files from iCloud
· Add album title inside a audio track description label
· Fix wrong colors in network views
· Fix Chromecast background playback
· Fix default sort for audio collections

## iOS [3.2.3]

· Add sorting into media collections
· Add settings to hide thumbnails and artwork
· Add "Quick actions" on media files and collections
· Fix shuffle mode
· Fix right to left experience for media players
· Fix optimize name setting
· Fix Fritzbox UPnP listing
· Fix cell height in settings
· Fix progress bar being shown for media collections
· Fix undefined media names when importing through Wi-Fi
· Fix crash with "Open in" activity for iPads
· Fix potential crash after media deletion
· Fix potential crash with external and Chromecast devices
· Rework overall edit mode layout and behaviour
· Various SMB improvements
· Various media library stability improvements

## iOS [3.2.2]

· Add automatic video grouping by name
· Add deletion to audio collections such as artist and albums
· Add setting to force rescan of the media library
· Fix HTTP download if file already exist
· Fix swipe gesture settings affecting double tap to seek
· Fix meta data for external media
· Fix Box cloud service overall usage
· Fix download progress
· Fix download enqueuing
· Fix download speed calculation
· Remove network login automatic capitalization and completion
· Rework download view according to new design
· Update translations

## iOS [3.2.1]

· Add automatic appearance setting for iOS 13
· Add indicator inside a playlist for reordering
· Adapt empty view for current context
· Fix SMB 2 credential storage
· Fix local network navigation
· Fix local network infinite reloading
· Fix local network connection dialog
· Fix external screen, AirPlay mirroring black screen
· Fix opening media from other applications using x-callback-url
· Fix artwork being shown after backgrounding the application during playback
· Fix cancel button not being shown on the local network connect screen on iPads
· Fix minor stability and interface issues
· Video Grouping will be back soon in a new version of VLC-iOS

## iOS [3.2.0]
· This releases introduces a completely new interface, more intuitive, easier to use and features an up-to-date look. This is a first step for future releases that will improve this interface even more.
· It also introduces a completely new media library backend, that allows a much easier management of Music and Audio files.
One can now browse per Album, Genre, Artist and Songs.
· Sorting, a feature that many asked for, also ships with this new version.
· The folders feature was revamped into proper playlist management and playlists have their own dedicated tab now.
· This version of VLC has now both a light and dark mode. Just choose your favorite in the settings
· Finally, in the media backend, numerous things were improved, including bluetooth Audio delay and drop, and better support for SMB shares

## tvOS [3.0.6]

· Fix SMB 2 issue
· Fix thumbnails for media
· Add thumbnail for video in remote playback
· Add manual connection to SMB/FTP/Plex
· Bugfixes and stability improvements

## tvOS [3.0.5]

· Fix SMB 2 issue
· Add thumbnail for video in remote playback
· Add manual connection to SMB/FTP/Plex
· Bugfixes and stability improvements

## iOS [3.1.8]

· Improve action sheet animation
· Fix SMB 2 issue
· Fix Chromecast no video issue
· Bugfixes and stability improvements

## tvOS [3.0.4]

· Added support for SMB 2
· Added support for AV1 video playback by shipping dav1d decoder
· Fixed cut off text in Network Stream tab
· Bugfixes and stability improvements

## iOS [3.1.7]

· Added support for SMB 2
· Added support for external keyboard shortcuts
· Fixed Chromecast showing a black screen for certain files
· Fixed an issue where a user couldn't navigate out of a OneDrive folder
· Bugfixes and stability improvements

## iOS [3.1.6]

· Fixed OneDrive integration by adopting newer Api
· Fixed common crashes with Chromecast and display of black videos
· Fixed crashes when backgrounding the App
· Added better support for AV1 video playback by shipping dav1d decoder
· Fixed playback problems with certain HEVC streams

## iOS [3.1.5]

· Fixed an issue with mkv videos crashing on iOS 12
· Adjusted the filterview and timer to not be hidden by the playback controls on newer iPhones
· Addressed CVE-2018-19937 a user was able to bypass the Passcode screen by opening a URL and turning the phone
· Bugfixes and stability improvements

## iOS [3.1.4]

· We adapted VLC for the new iPad Pro by adjusting the App and bringing external screen support and FaceID to our iPad Pro users
· We brought the double tap to fullscreen feature to all devices, while still letting you double tap to jump back or forward on the sides of the screen
· Multiple files selection is now possible with iCloud Drive
· Fixed an issue where you couldn't log into the app if you killed it while setting a passcode

## tvOS [3.0.3]

· Fixed black screen when playing back Audio files
· List of chapters isn't shown when the info pane is first opened
· Fixed a bug where all chapters show the name of the first chapter
· Improved audio passthrough behavior
· Audio / Subtitles track selector now appears without pausing first
· Greatly improved hardware decoding performance for H.264 and H.265 (Apple TV 4K only)
· Fix playback issues with certain AVI, MP4 and MKV files
· Improved display of subtitles

## iOS [3.1.3]

· Added Corsican language
· Fixed a crash when reordering files outside of folders
· The Media title is now always visible when streaming to an external display
· Various Stability improvements and bug fixes

## iOS [3.1.2]

· Added an activity indicator for buffering
· The background setting to continue playback is ignored when external screens are used
· Sorting in folders gets saved correctly
· Fixed playback pausing once external output devices like bluetooth headphones are disconnected
· Deinterlacing is disabled by default now modern devices no longer support this, which led to high battery usage
· Stability improvements for the H264 and H265 decoder and Chromecasting

## iOS [3.1.1]

· Fixed the swiping Gestures to change brightness and Volume
· Chromecasting is not stopping anymore when locking the device
· Fixed Video not being displayed over an external Screen via HDMI
· Fixed Audio not working after pausing and leaving the App
· Fixed opening external files in VLC or from the Files app
· Fixed an issue where songs where skipped when playing albums or playlists
· Better 360 video behavior when panning

## iOS [3.1.0]

· We added a feature many of you waited for: Chromecast support
· We fixed a bug where files on your phone were not displayed in VLC
· 360 videos can be viewed by moving your phone now
· Stability and performance improvements when decoding H.264/H.265 in hardware
· Improved audio playback quality
· Fixed a regression preventing the download of certain media files via http
· Fixed a regression where downloaded files might disappear

## tvOS [3.0.2]

· Fixes issues with not being able to resume playback
· Fixes issues with no subtitles after selection

## iOS [3.0.3]

· Hitting play after backgrounding VLC is finally fixed
· Opening a txt file on iOS won't jump into VLC anymore (we obviously still support this subtitle format)
· Instead of a black screen, when opening certain HEVC files, we now have a playing video
· Fixes an issue were users were prompted to enter a passcode without ever setting one
· We also fixed multiple crashes
· Scrubbing in the lock screen was added

## iOS [3.0.2]

· Fixes issues with TouchID and FaceID
· Fixes a crash when opening a Folder

## tvOS [3.0.1]

· Fixes a crash browsing files on local file servers

## iOS [3.0.1]

· Fixes a crash browsing files on local file servers
· the "use TouchID setting" is now respected
· Fixes a crash when locking your UI on iPhone X

## iOS [3.0.0]

· Added support for Drag and Drop
· Added Files integration
· Added FaceID support

## tvOS [3.0.0]

· Crash fixes when browsing or searching the local network

## iOS [2.9.0]

· Stability improvements and bug fixes

## iOS [2.8.9]

· .srt subtitles are being displayed again

## tvOS [1.1.3]

· .srt subtitles are being displayed again

## tvOS [1.1.2]

· Fix a crash on start when there are two devices with the same name in the network

## iOS [2.8.8]

· This version will not reboot your iPhone X when playing HEVC files
· We stopped the madness of doubling files!
· When passcode is enabled Touch Id won't pop up multiple times when you enter the background
· SMB Servers will show up again and are accessible
· Sharing your Media with other Services and saving to Camera Roll works again
· And as always · Stability improvements and bug fixes

## iOS [2.8.7]

· Audio resumes after getting calls or playing content from other media apps again
· Fixes an issue were SSA subtitles were not displayed
· Google Drive login works again

## tvOS [1.1.1]

· Stability improvements and bug fixes

## iOS [2.8.6]

· Adjusted the UI for iPhone X
· Fixes the app termination on devices for iOS 7 and iOS 8
· Adds Full support for HEVC 4k videos
· General bug fixes

## tvOS [1.1.0]

· Full support for tvOS 11 and Apple TV 4K
· Hardware decoding of H.264
· Greatly improved playback engine
· Added support for dark user interface style
· Improved support for pass-through audio playback and multi-channel audio
· Fixes an unexpected app termination when uploading specifically crafted files through Remote Playback

## iOS [2.8.5]

· Fixes an unexpected app termination when uploading specifically crafted files through WiFi Upload
· iOS 7 stability improvements, notably when browsing servers via UPnP or deleting locally stored media

## iOS [2.8.4]

· Fixes a not responsive UI after scrubbing the Video
· Fixes iOS 11 issues with deinterlaced videos 
· Fixes instances where the Video would be black
· General stability improvements and bug fixes

## iOS [2.8.3]

· Hardware accelerated video filtering reducing CPU load by 30% to the previous software filters (iOS 9 or later only)
· Fixes FTP playback
· Fixes crash when playback of a H.264 encoded video ends whose dimensions are not multiples of 16
· General stability improvements and bug fixes

## iOS [2.8.2]

· Fixes an unexpected playback termination of H.264 content after a few minutes
· Fixes playback of 10bit H.264 content
· Fixes a crash when discovering UPnP devices on the local network
· Restored playback on iOS 7
· Dropbox support is no longer an option on iOS 7 and iOS 8
· File listings in Dropbox are now alphabetically sorted (again)
· More options for default playback speed matching the tvOS version
· Fixed aspect ratio switch and crop
· General stability improvements and bug fixes

## iOS [2.8.1]

· General stability improvements and bug fixes
· Fixes a crash for Local Network for versions < iOS 10
· Fixes issues with .mov playback
· Fixes aspect ratio not being applied

## iOS [2.8.0]

· A new Network Login view
· Hardware decoding of H.264/HEVC
· Added support for NFS shares
· Added Bonjour discovery for SMB shares
· Improved search bar discovery method
· Improved sleep timer
· Edit "Select All"
· Double tap to seek in videos
· Shuffle functionality

## iOS [2.7.8]

· Fixed listing of playlist files on remote shares
· Fixed downloading some media from http servers
· Fixed start index of multiple media playback in OneDrive
· Fixed playback of XDCAM media files (requires a 64bit iOS device)

## tvOS [1.0.7]

· Fix listing of playlist files on remote shares
· Fixed playback of XDCAM media files

## iOS [2.7.7]

· Updated decoders
· Added ability to rename network streams

## tvOS [1.0.6]

· Updated decoders
· Added repeat mode for playback

## iOS [2.7.6]

· General stability improvements and bug fixes
· Fix hue video filter
· Improved stability when unlocking app using Touch ID
· Improved Dropbox stability
· Prevent ghosting of media downloaded from UPnP servers
· Prevent playing the wrong file on some UPnP, PLEX or FTP shares

## tvOS [1.0.5]

· General stability improvements and bug fixes
· Prevent ghosting of media downloaded from UPnP servers
· Prevent playing the wrong file on some UPnP, PLEX or FTP shares

## iOS [2.7.5]

· Improved SMB reliability
· Stability improvements for iOS 7

## tvOS [1.0.4]

· Improved SMB reliability

## iOS [2.7.3]

· General stability improvements and bug fixes
· Added 3D Touch Quick Actions for iPhone 6S
· Added 'Play all' feature to OneDrive
· Added 'Play all' feature to local network shares
· Added automatic finding of external subtitles on HTTP, FTP, PLEX and UPnP
  - Note that SMB shares are not supported yet.
· Added filtering of files found on FTP servers to only show playable media
· Improved SMB reliability
· Fixed contrast video filter
· Fixed downloads from certain UPnP, PLEX and ftp servers
· Fixed switching library display modes on iPad

## tvOS [1.0.3]

· General stability improvements and bug fixes
· Added S/PDIF pass-through option
· Added option to disable artwork retrieval
· Added automatic finding of external subtitles on HTTP, FTP, PLEX and UPnP
  - Note that SMB shares are not supported yet.
· Added filtering of files found on FTP servers to only show playable media

## tvOS [1.0.2]

· General stability improvements and bug fixe
· Improved SMB reliability

## tvOS [1.0.1]

· General stability improvements and bug fixes
· Improved UPnP reliability, notably with Twonky, KooRaRoo, PlayOn

## tvOS [1.0.0]

· Initial release

## iOS [2.7.2]

· Stability improvements
· Improved HTTP connectivity
· Improved UPnP reliability, notably with Twonky
· Fixed issues unlocking the app when a passcode was never set
· Fixed custom subtitles font sizes
· Fixed UPnP playback on iOS 7
· Note: when installing this update, a potentially configured passcode is reset.

## iOS [2.7.1]

· Stability improvements
· Fixed issues unlocking the app when a passcode was never set
· Fixed repeat one / repeat list
· Fixed saving playback progress for files whose names contain spaces or umlauts
· Fixed multiplying music album listings
· Show music albums with 1 track correctly in the music album's list
· Improved SMB compatibility
· UPnP reliability improvements, notably with Kodi

## iOS [2.7.0]

· Added new app for the 4th gen. Apple TV
· Dropped support for iOS 6.1. VLC requires iOS 7.0 now
· Added support for SMB file sharing (#8879)
· Added support for music albums with more than 1 disk (#14650)
· Re-wrote Apple Watch extension for watchOS 2
· Media stored in folders on remote servers is now played as a list
· Reworked networking UI
· Added support for system-wide search "CoreSpotlight"
· Added improved UI support for Right-to-Left languages
· Added support for the split-screen appearance in iOS 9 (#14840)
· Added support for Touch ID to unlock app (#13378)
· Added support for WiFi sharing using a personal hotspot (#14865)
· Added option to configure playback continuation (#14340, #14590)
· Added option to configure gestures (#15449) 
· Added support for music albums with more than 1 disk (#14650)
· Display chapter duration in playback UI (#14718)
· Recently played network stream URL are now shared across all devices
· Stored login information is now shared across all devices
· Cloud login credentials are now shared across all devices

## iOS [2.6.6]

· Desktop quality SSA subtitles rendering (finally!, #11297, #13365, #14112)
· Stability improvements
· New translations to Lao and Kabyle

## iOS [2.6.5]

· Fixed playback of streams opened through the legacy vlc:// pseudo protocol
· Minor improvements (#14080, #14836, #14881, #15118)
· New translation to Norwegian Bokmål
· Updated translations to Afrikaans, Arabic, Bosnian, Czech, Danish, English (GB),
  Spanish (Mexico), Persian, Hungarian, Korean, Latvian, Malay, Polish, Portuguese (Brazil),
  Portuguese (Portugal), Slovenian, Turkish and Traditional Chinese

## iOS [2.6.4]

· Fixed playback of UPnP streams broken in previous update

## iOS [2.6.3]

· Stability improvements and minor bug fixes (#13601, #14154, #14611, #14852, #14860, #14864)
· Fixed video playback for URLs open via third party apps (#15075)

## iOS [2.6.2]

· Improved playback reliability (#15000 et al)
· Added minimize button to fullscreen playback so 'Done' stops playback again
· Added option to always play video in fullscreen, on by default (#14985)
· Fixed subtitles rendering which produced incorrect umlauts or pixelated fonts (#14978 et al.,
  #14883, #14919, #14929)
· Fixed major playback issue on iOS 7 on iPad (#14977)
· Fixed remove control events on iOS 6 (#14996)
· Fixed x-callback-url on playback close (#14984)
· Improved accessibility (#15012)

## iOS [2.6.1]

· Reduced Apple Watch extension file size by 90%
· Minor bug fix (#14942)

## iOS [2.6.0]

· Added support for Apple Watch · control VLC from your watch!
  - playback control
  - media info
  - library browsing
· Added mini-player to browse the library during playback (#13367)
· Added support for looping playlists
· New ingest mechanism for audio files
· Improved remote command support
· Improved thumbnail generation
· Improved thumbnail and web interface performance on devices with A5 CPU and above
· Fixed crash when playing media from a folder or music album on iPad (#14394, #14706)
· Fixed crash when app goes to background while a video is playing (#14643)
· Fixed privacy leak when using a passcode to protect the library (#14159, #14615)
· Removed stray popup announcing VLC's crash all the time while it actually
  didn't crash before, but terminated by the user (#13194)
· Added support for the PLEX Web API
· Thumbnails displayed in the media library are updated to the last playback position (#14462)
· Improved reliability when sharing media library on the local network
· Improved media library search delivering more accurate results (#14593)
· Fixed 'crop to fill screen' on iPad (#14575)
· Fixed issue which prevented downloading of a few files via UPnP (#11123)
· Fixed crash when screen is being locked during playback (#14610)
· A large number of bug fixes affecting most parts of the app (#13194, #14056,
  #14270, #14284, #14355, #14477, #14588, #14589, #14609, #14623, #14624,
  #14628, #14629, #14635, #14638, #14641, #14642, #14654, #14663, #14687,
  #14688, #14713, #14715, #14716, #14733, #14736, #14795, #14800, #14801, #14829)

## iOS [2.5.1]

· Fixed playback on iOS 6.1

## iOS [2.5]

· Added support for iCloud Drive (#8688)
· Added support for box.com (#11301)
· Added support for OneDrive (#13413)
· Added a lock button to the playback view, supporting both orientation and
  controls (#11293, #11292)
· Added 10-band equalizer (#9032)
· Added sharing of the media library between multiple iOS devices
  on the local network
· Added support for chapters and titles to the playback dialog (#11560)
· Cleaned-up playback view appearance with more features and less clutter
· Added enhanced media information to the library view (#13564)
· Added notifications about missing storage space when syncing media (#11474)
· Added timer to automatically stop playback (#8640)
· Improved WiFi sharing reliability with web browsers on Linux (#14083)
· Improved Plex support with optional direct connections if detection fails
· x-callback-url: added support for the x-error parameter (#14092)
· A few minor UI improvements (#13892)
· New translations to Portuguese (Portugal), Portuguese (Brazil), Khmer,
  Faroese, Belarusian, Serbian (Latin), Tamil and Afrikaans

## iOS [2.4.1]

· Fixed subtitles downloading in some corner cases
· Appearance fixes for playback speed selector and download view on iPhone
· Improved WiFi Sharing reliability by disabling IPv6 support by default
· Improved UPnP reliability and speed
· Various minor UI improvements
· Fixed regression leading to incomplete library listings on iPad
· Improved decoding reliability by deploying FFmpeg instead of libav

## iOS [2.4]

· Added support for iPhone 6 and 6+
· Download of currently stored media via WiFi in addition to upload (#11289)
· Detection of external subtitles when streaming media via http or ftp (#10668)
· Folder support for GDrive (#11019)
· Support for streaming from GDrive
· Native support for Plex media servers
· Support for file sharing with further apps installed on device (#11302)
· Option to download media from http/ftp/https instead of direct playback when
  requested through third-party app (#11147)
· Folders synced through iTunes are correctly parsed now (#9158)
· Option to set text encoding used for FTP connections (#10611)
· Option to set default playback speed (#10595)
· Media library search (#11303)
· Improved reliability when a call comes in during playback
· Improved subtitles playback reliability (#11225)
· Support for redirected downloads via HTTP (#10639)
· Support for audio playback and subtitles delay for manual sync (#11236)
· Added improved interaction with third party apps through a x-callback-url
  based mechanism
  URL scheme: vlc-x-callback://x-callback-url/stream?url=...&x-success=...
  The 'stream' path component overwrites the "Download or Stream?" dialog
  displayed when third party URLs are being opened.
· Media Library is no longer reset on upgrade (#11330)
  - no further thumbnail mismatch (#9158 et al)
  - playback states are retained
  - improved first launch after upgrade reliability
· Fix browsing of a number of UPnP devices such as HDHomeRun without sorting
  capabilities (#11667)
· Fix pseudo-random playback starts (#11993)
· Improved passcode lock appearance (#13166)
· Minor UI improvements (#11296, #11637, #13165, #13169)
· Network stream history allows copying URLs
· Improved reliability when syncing media via WiFi or iTunes (#13128)
· Stability improvements for iOS 6.1
· New translation to Traditional Chinese

## iOS [2.3]

· New ability to organize media in folders (#9043)
· Support for password protected HTTP streams (#9028)
· WiFi uploads and HTTP downloads continue in the background
  (2 min on iOS 7, 10 min on iOS 6)
· Added option to disable playback control gestures (#10592)
· Added option to use bold subtitles (#10882)
· Modified behavior: when passcode lock is enabled, playback will be stopped
  when VLC enters the background state (#10630, #10747)
· Fixed serial ftp downloads
· Fixed downloads from Twonky UPnP servers (#10631)
· Fixed playback control through lock screen, headphones or multi-tasking view
  (#10932)
· Playback is paused when headphones are unplugged (#11041)
· Improved UPnP discovery speed with some servers (#10811)
· Improved memory consumption (#9505)
· Added support for m4b, caf, oma, w64 audio and mxg video files
· Caches for WiFi upload and HTTP downloads are emptied more often to
  keep storage impact reasonable
· Stability improvements and UX tweaks (amongst others #10601, #10518)
· New translations to Latvian, Romanian and British English

## iOS [2.2.2]

· Fixed audio playback regression introduced in previous update (#10597)
· Updated translations to Arabic, Chinese (Hans), Dutch, Galician, Hungarian,
  Portuguese

## iOS [2.2.1]

· Added initial support for ARM64 aka AArch64 aka ARMv8
· Improved reliability for Dropbox streaming (#10489)
· Added option to adapt network caching (#10388)
· Compatibility fixes for multiple UPnP servers (notably Twonky 7, Serviio 1.4,
  XBMC 12)
· Fixed an issue where always the same file in a UPnP folder was played (#10441)
· Fixed a ftp streaming issue from connected servers if file name contains
  non-ASCII characters or the path contains spaces (#10469)
· Improved meta data readability within the iPad library view (#10471)
· Improved stability on iOS 6
· Improved Thumbnails
· Misc stability improvements (#10490)

## iOS [2.2.0]

NB: This release removes support for iOS 5 and therefore the first generation
iPad. iOS 6 and the iPhone 3GS remain supported.

Interface:
· New Interface for iOS 7
· Add tutorial to introduce the user to the app
· Improved feedback for media download progress including data bitrate,
  procentual progress and estimated remaining download time
· Opening network streams no longer leads to a collapsed file system hierachy
  on the remote system. After playback, you can continue where you left off.
· Added bookmarks for FTP servers
· Added support for multi-touch gestures based upon the VLC Gestures haxie
  - horizontal swipe for playback position
  - tap with 2 fingers to play/pause
  - vertical swipe in the right half of the video to adapt volume
  - vertical swipe in the left half of the video to adapt screen brightness
· Previously removed episodes and tracks no longer show up in the respective
  group listings (#9705)
· Improved privacy by requesting the passcode immediately after leaving the
  app and by obfuscating playback metadata if passcode lock is enabled
· Added support to endlessly repeat the currently playing item (#9793)
· Added option to disable file name display optimizations (#10050)
· TV Shows are sorted by Season number / Episode number and Music Albums
  respectively by track number
· Added ability to rename any media item in the library view
· Added deletion of multiple media items in one step
· If your media was recognized as part of a music album, the next track
  will automatically start playing afterwards
· New translations to Czech, Malay, Persian, Spanish (Mexico)

Cloud interaction:
· Added support for downloads from Google Drive (#8690)
· Added support for streaming files from Dropbox in addition to download
  to device (#9784)

Local network:
· Added support for downloading from UPnP multimedia servers
· Added cover-art and duration to UPnP server item lists
· UPnP stability improvements
· Fix incorrect displayed size for files stored on UPnP multimedia servers
  larger than 2147.48 MB (#9641)
· Improved WiFi Upload reliability, especially when uploading multiple
  items at the same time

Global networks:
· Added support for HTTP Live Streaming (HLS) (#9174)
· Added support for https playback
· Added support for system-wide HTTP proxy settings
· Added support for m3u streams

Misc:
· Improved audio playback performance and reliability
· Improved metadata detection
· Improved vlc:// handling (#9542)
· Improved TV show handling for shows with more than 100 episodes

## iOS [2.1.3]

· Fixed crashes with files whose names are less than 6 characters long after
  removing the file extension

## iOS [2.1.2]

· Stability improvements (#9393, #9431, #9432, #9433, #9434, #9435, #9556)
· Improved Closed Caption rendering (#9369)
· Minor UI fixes (#9454)
· New translations to Hungarian and Swedish

## iOS [2.1.1]

· Stability improvements
· Improved UPnP handling
· Improved interaction with third party apps
· Improved visual appearance on iPad
· Added support for Teletext-based DVB subtitles
· New translations to Arabic, Polish, and Korean

## iOS [2.1]

· Improved overall stability (#8989, #9031, #9048, #9089, #9092)
· Add support for subtitles in non-western languages (#8991)
· Improved Subtitles support with options to choose font, size, and color
· Add UPnP discovery and streaming (#8880)
· Add FTP server discovery, streaming and downloading (#9064)
· Add Bonjour announcements for the WiFi Uploader's website (#8741)
· Add playback of audio-only media (#9044)
· Newly implemented menu and application flow (#9045)
· Improved VoiceOver and accessibility support (#9017)
· Add Deinterlace option (off by default, #8813)
· Device no longer goes to sleep during media downloads (#9062)
· Improved video output on external screens (#9055, #9079)
· Improved Passcode Lock behavior (#9252)
· Minor usability improvements (#9122, #9125, #9225)
· New translations to Bosnian, Catalan, Galician, Greek, Marathi, Portuguese,
  Slovenian

## iOS [2.0.2]

· Fix MP2 and MP3 decoding (#8986)
· Add vlc:// protocol handler (#8988)
  - vlc://anyprotocol:// allows you to force any URL to open in VLC
  - vlc://server/path will assume http://
· Fix Dropbox hierarchy navigation (#8993)
· Fix major leak of data when opening files in VLC from other apps (#9011)
· Retain last audio and subtitles tracks when for played media (#8987)
· Fix CSS rendering issue in the WiFi Uploader's web interface
· Switch Default Subtitles Font from SourceSans-Pro to Open Sans
  to support Greek, Cyrillic and Vietnamese (#8991)
· Shake device to create a bug report (#7788)
· Export meta data about current playback item to multitasking view (#8883)
· Fix crash when opening network streams from within third party apps while
  playing content local to VLC (#9013)
· Fix VoiceOver support for Dropbox login (#8997)
· Fix dialog rotation on iOS 5 (#8992)
· New translations to Chinese, Danish, Dutch, Hebrew, Slovak, Turkish,
  Ukrainian, Vietnamese

## iOS [2.0.1]

· Update of Russian and Spanish translations.
· Minor crash fix (#8739) and interface fix for iPhone 4.
· Add option for skipping loop filtering (#8814)

## iOS [2.0.0]

First project release.
