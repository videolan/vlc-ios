#!/bin/sh
# Copyright (C) Pierre d'Herbemont, 2010
# Copyright (C) Felix Paul Kühne, 2012-2013

set -e

PLATFORM=iphoneos
SDK=7.0
SDK_MIN=6.1
VERBOSE=no
CONFIGURATION="Release"
NONETWORK=no
SKIPLIBVLCCOMPILATION=no

TESTEDHASH=2791a97f2
TESTEDVLCKITHASH=b343a201d
TESTEDMEDIALIBRARYKITHASH=973a5eb38

usage()
{
cat << EOF
usage: $0 [-s] [-v] [-k sdk]

OPTIONS
   -k       Specify which sdk to use (see 'xcodebuild -showsdks', current: ${SDK})
   -v       Be more verbose
   -s       Build for simulator
   -d       Enable Debug
   -n       Skip script steps requiring network interaction
   -l       Skip libvlc compilation
EOF
}

spushd()
{
     pushd "$1" 2>&1> /dev/null
}

spopd()
{
     popd 2>&1> /dev/null
}

info()
{
     local green="\033[1;32m"
     local normal="\033[0m"
     echo "[${green}info${normal}] $1"
}

buildxcodeproj()
{
    local target="$2"
    if [ "x$target" = "x" ]; then
        target="$1"
    fi

    info "Building $1 ($target, ${CONFIGURATION})"

    local extra=""
    if [ "$PLATFORM" = "Simulator" ]; then
        extra="ARCHS=i386"
    fi

    xcodebuild -project "$1.xcodeproj" \
               -target "$target" \
               -sdk $PLATFORM$SDK \
               -configuration ${CONFIGURATION} ${extra} \
               IPHONEOS_DEPLOYMENT_TARGET=${SDK_MIN} > ${out}
}

while getopts "hvsdnlk:" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         v)
             VERBOSE=yes
             ;;
         s)
             PLATFORM=iphonesimulator
             ;;
         d)  CONFIGURATION="Debug"
             ;;
         n)
             NONETWORK=yes
             ;;
         l)
             SKIPLIBVLCCOMPILATION=yes
             ;;
         k)
             SDK=$OPTARG
             ;;
         ?)
             usage
             exit 1
             ;;
     esac
done
shift $(($OPTIND - 1))

out="/dev/null"
if [ "$VERBOSE" = "yes" ]; then
   out="/dev/stdout"
fi

if [ "x$1" != "x" ]; then
    usage
    exit 1
fi

# Get root dir
spushd .
aspen_root_dir=`pwd`
spopd

info "Preparing build dirs"

mkdir -p ImportedSources

rm -rf External
mkdir -p External

spushd ImportedSources

if [ "$NONETWORK" != "yes" ]; then
if ! [ -e vlc ]; then
git clone git://git.videolan.org/vlc/vlc-2.1.git vlc
info "Applying patches to vlc.git"
cd vlc
#git checkout -B localAspenBranch ${TESTEDHASH}
git am ../../patches/*.patch
if [ $? -ne 0 ]; then
git am --abort
info "Applying the patches failed, aborting git-am"
exit 1
fi
cd ..
else
cd vlc
git pull --rebase
cd ..
fi
if ! [ -e MediaLibraryKit ]; then
git clone git://git.videolan.org/MediaLibraryKit.git
cd MediaLibraryKit
git checkout -B localAspenBranch ${TESTEDMEDIALIBRARYKITHASH}
git branch --set-upstream-to=origin/master localAspenBranch
cd ..
else
cd MediaLibraryKit
git pull --rebase
git reset --hard ${TESTEDMEDIALIBRARYKITHASH}
cd ..
fi
if ! [ -e VLCKit ]; then
git clone git://git.videolan.org/vlc-bindings/VLCKit.git
cd VLCKit
git checkout -B localAspenBranch ${TESTEDVLCKITHASH}
git branch --set-upstream-to=origin/master localAspenBranch
cd ..
else
cd VLCKit
git pull --rebase
git reset --hard ${TESTEDVLCKITHASH}
cd ..
fi
if ! [ -e OBSlider ]; then
git clone git://github.com/ole/OBSlider.git
else
cd OBSlider && git pull --rebase && cd ..
fi
if ! [ -e DAVKit ]; then
git clone git://github.com/mattrajca/DAVKit.git
else
cd DAVKit && git pull --rebase && cd ..
fi
if ! [ -e GDrive ]; then
svn checkout http://google-api-objectivec-client.googlecode.com/svn/trunk/Source GDrive
else
cd GDrive && svn up && cd ..
fi
if ! [ -e GHSidebarNav ]; then
git clone git://github.com/gresrun/GHSidebarNav.git
else
cd GHSidebarNav && git pull --rebase && cd ..
fi
if ! [ -e upnpx ]; then
UPNPXVERSION=1.2.4
curl -O http://upnpx.googlecode.com/files/upnpx-${UPNPXVERSION}.tar.gz
tar xf upnpx-${UPNPXVERSION}.tar.gz
mv upnpx-${UPNPXVERSION} upnpx
cd upnpx
for file in ../../patches/upnpx/*; do
patch -p1 < ../../patches/upnpx/"$file"
done
cd ..
fi
if ! [ -e WhiteRaccoon ]; then
git clone git://github.com/fkuehne/WhiteRaccoon.git
else
cd WhiteRaccoon && git pull --rebase && cd ..
fi
if ! [ -e CocoaHTTPServer ]; then
git clone git://github.com/robbiehanson/CocoaHTTPServer.git
cd CocoaHTTPServer
git am ../../patches/cocoahttpserver/*.patch
if [ $? -ne 0 ]; then
git am --abort
info "Applying the patches failed, aborting git-am"
exit 1
fi
cd ..
else
cd CocoaHTTPServer && git pull --rebase && cd ..
fi
if ! [ -e Dropbox ]; then
DROPBOXSDKVERSION=1.3.9
curl -O https://www.dropbox.com/static/developers/dropbox-ios-sdk-${DROPBOXSDKVERSION}.zip
unzip -q dropbox-ios-sdk-${DROPBOXSDKVERSION}.zip
mv dropbox-ios-sdk-${DROPBOXSDKVERSION} Dropbox
rm dropbox-ios-sdk-${DROPBOXSDKVERSION}.zip
rm -rf __MACOSX
fi
if ! [ -e InAppSettingsKit ]; then
git clone git://github.com/futuretap/InAppSettingsKit.git
cd InAppSettingsKit
git am ../../patches/inappsettingskit/*.patch
if [ $? -ne 0 ]; then
git am --abort
info "Applying the patches failed, aborting git-am"
exit 1
fi
cd ..
else
cd InAppSettingsKit && git pull --rebase && cd ..
fi
fi

info "Setup 'External' folders"

if [ "$PLATFORM" = "iphonesimulator" ]; then
    xcbuilddir="build/${CONFIGURATION}-iphonesimulator"
else
    xcbuilddir="build/${CONFIGURATION}-iphoneos"
fi
framework_build="${aspen_root_dir}/ImportedSources/VLCKit/${xcbuilddir}"
mlkit_build="${aspen_root_dir}/ImportedSources/MediaLibraryKit/${xcbuilddir}"
upnpx_build="${aspen_root_dir}/ImportedSources/upnpx/projects/xcode4/upnpx/${xcbuilddir}"
gtl_build="${aspen_root_dir}/ImportedSources/GDrive/${xcbuilddir}"

spushd MediaLibraryKit
rm -f External/MobileVLCKit
ln -sf ${framework_build} External/MobileVLCKit
spopd

spopd #ImportedSources

ln -sf ${framework_build} External/MobileVLCKit
ln -sf ${mlkit_build} External/MediaLibraryKit
ln -sf ${upnpx_build} External/upnpx
ln -sf ${gtl_build} External/gtl

#
# Build time
#

info "Building"

spushd ImportedSources

if [ "$SKIPLIBVLCCOMPILATION" != "yes" ]; then
spushd vlc/extras/package/ios
info "Building vlc"
args=""
if [ "$VERBOSE" = "yes" ]; then
    args="${args} -v"
fi
if [ "$PLATFORM" = "iphonesimulator" ]; then
    args="${args} -s"
    ./build.sh ${args} -k "${SDK}"
else
    ./build.sh -a armv7 ${args} -k "${SDK}" && ./build.sh -a armv7s ${args} -k "${SDK}"
fi

spopd
fi

spushd VLCKit
buildxcodeproj MobileVLCKit "Aggregate static plugins"
buildxcodeproj MobileVLCKit "MobileVLCKit"
spopd

spushd MediaLibraryKit
buildxcodeproj MediaLibraryKit
spopd

spushd upnpx/projects/xcode4/upnpx
buildxcodeproj upnpx
spopd

spushd GDrive
buildxcodeproj GTL "GTLTouchStaticLib"
spopd

spopd # ImportedSources


# Build the Aspen Project now
buildxcodeproj "VLC for iOS" "vlc-ios"

info "Build completed"
