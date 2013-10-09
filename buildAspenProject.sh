#!/bin/sh
# Copyright (C) Pierre d'Herbemont, 2010
# Copyright (C) Felix Paul Kühne, 2012-2013

set -e

PLATFORM=iphoneos
SDK=7.0
SDK_MIN=6.1
VERBOSE=no
CONFIGURATION="Release"
TESTEDHASH=2791a97f2
TESTEDVLCKITHASH=eda8237e6
TESTEDMEDIALIBRARYKITHASH=82a2f20c8

usage()
{
cat << EOF
usage: $0 [-s] [-v] [-k sdk]

OPTIONS
   -k       Specify which sdk to use (see 'xcodebuild -showsdks', current: ${SDK})
   -v       Be more verbose
   -s       Build for simulator
   -d       Enable Debug
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

while getopts "hvsdk:" OPTION
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
fi
if ! [ -e MediaLibraryKit ]; then
git clone git://git.videolan.org/MediaLibraryKit.git
cd MediaLibraryKit
git checkout -B localAspenBranch ${TESTEDMEDIALIBRARYKITHASH}
cd ..
fi
if ! [ -e VLCKit ]; then
git clone git://git.videolan.org/vlc-bindings/VLCKit.git
cd VLCKit
git checkout -B localAspenBranch ${TESTEDVLCKITHASH}
cd ..
fi
if ! [ -e OBSlider ]; then
git clone git://github.com/ole/OBSlider.git
fi
if ! [ -e DAVKit ]; then
git clone git://github.com/mattrajca/DAVKit.git
fi
if ! [ -e GHSidebarNav ]; then
git clone git://github.com/gresrun/GHSidebarNav.git
fi
if ! [ -e upnpx ]; then
UPNPXVERSION=1.2.4
curl -O http://upnpx.googlecode.com/files/upnpx-${UPNPXVERSION}.tar.gz
tar xf upnpx-${UPNPXVERSION}.tar.gz
mv upnpx-${UPNPXVERSION} upnpx
cd upnpx && patch -p1 < ${aspen_root_dir}/patches/upnpx/duration-selector-failure.patch
cd ..
fi
if ! [ -e WhiteRaccoon ]; then
git clone git://github.com/fkuehne/WhiteRaccoon.git
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
fi
if ! [ -e Dropbox ]; then
DROPBOXSDKVERSION=1.3.4
curl -O https://www.dropbox.com/static/developers/dropbox-ios-sdk-${DROPBOXSDKVERSION}.zip
unzip -q dropbox-ios-sdk-${DROPBOXSDKVERSION}.zip
mv dropbox-ios-sdk-${DROPBOXSDKVERSION} Dropbox
rm dropbox-ios-sdk-${DROPBOXSDKVERSION}.zip
rm -rf __MACOSX
fi
if ! [ -e InAppSettingsKit ]; then
git clone git://github.com/futuretap/InAppSettingsKit.git
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

spushd MediaLibraryKit
rm -f External/MobileVLCKit
ln -sf ${framework_build} External/MobileVLCKit
spopd

spopd #ImportedSources

ln -sf ${framework_build} External/MobileVLCKit
ln -sf ${mlkit_build} External/MediaLibraryKit
ln -sf ${upnpx_build} External/upnpx

#
# Build time
#

info "Building"

spushd ImportedSources

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

spopd # ImportedSources


# Build the Aspen Project now
buildxcodeproj "VLC for iOS" "vlc-ios"

info "Build completed"
