
# Before the Release

## A week before the release 

upload the following files to transifex (https://www.transifex.com/yaron/vlc-trans/content/).
Christoph Miebach can give you access if you don't have access yet.

* Root.strings from the en.lproj folder (transifex:ios-settings-2.0)
* infoPlist.strings (English) (transifex:ios-infoplist)
* Localizable.strings (transifex:ios-2.0)

Get Testers for Testflight with this document :

https://docs.google.com/forms/d/e/1FAIpQLSfHQFm4O6t2Bn2zqbFv_nVh4H1XtdDjlI1RS1pGdHlTWR85jg/viewform

## Test different video file formats with video files from here:

https://www.dropbox.com/sh/mv5go8hwd5mx2c8/AADIvKTwHiBBYpd6mlAl2wkDa?dl=0

## Manual Testing until we have Unit- and UI-Tests ;) 
Apply the magical patch with all the private keys and client secrets so that you can test cloud integration. Ask J-b or Felix

Make sure that at least the following works:
* The main video controls
* Subtitles
* Chapter and track selection
* Timer and the filters
* Aspect ratio changes
* The cloud integrations, especially login, log out, streaming and downloading
* Wifi up and download
* Local network (twonky server for example)
* Deleting, renaming of files
* Creating, moving in and out of folders

Look at the memory and performance while playing a video

# On Testflight/Release submission day:

* Add testers for Testflight on itunes connect
* Update all Localizable files from transifex
* Update the about screen
* Get the details from NEWS or update News for the new version

# After submission

* Upload the binary and dsym to Hockeyapp so that we get crashreporting
* Tag the version



