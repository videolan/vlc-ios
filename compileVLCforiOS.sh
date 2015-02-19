#!/bin/sh
# Copyright (C) Pierre d'Herbemont, 2010
# Copyright (C) Felix Paul Kühne, 2012-2014

set -e

PLATFORM=iphoneos
SDK=`xcrun --sdk iphoneos --show-sdk-version`
SDK_MIN=6.1
VERBOSE=no
CONFIGURATION="Release"
NONETWORK=no
SKIPLIBVLCCOMPILATION=no

TESTEDVLCKITHASH=754265a32
TESTEDMEDIALIBRARYKITHASH=a2aa36265

usage()
{
cat << EOF
usage: $0 [-s] [-v] [-k sdk] [-d] [-n] [-l] [-u]

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

    local architectures=""
    if [ "$PLATFORM" = "iphonesimulator" ]; then
        architectures="i386 x86_64"
    else
        architectures="armv7 armv7s arm64"
    fi

    xcodebuild -project "$1.xcodeproj" \
               -target "$target" \
               -sdk $PLATFORM$SDK \
               -configuration ${CONFIGURATION} \
               ARCHS="${architectures}" \
               IPHONEOS_DEPLOYMENT_TARGET=${SDK_MIN} > ${out}
}

buildxcworkspace()
{
    local target="$2"
    if [ "x$target" = "x" ]; then
    target="$1"
    fi

    info "Building the workspace $1 ($target, ${CONFIGURATION})"

    local architectures=""
    if [ "$PLATFORM" = "iphonesimulator" ]; then
        architectures="i386 x86_64"
    else
        architectures="armv7 armv7s arm64"
    fi

    xcodebuild -workspace "$1.xcworkspace" \
    -scheme "Pods-vlc-ios" \
    -sdk $PLATFORM$SDK \
    -configuration ${CONFIGURATION} \
    ARCHS="${architectures}" \
    IPHONEOS_DEPLOYMENT_TARGET=${SDK_MIN} > ${out}
}

while getopts "hvsdnluk:" OPTION
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
if ! [ -e MediaLibraryKit ]; then
git clone git://git.videolan.org/MediaLibraryKit.git
cd MediaLibraryKit
git checkout -B localAspenBranch ${TESTEDMEDIALIBRARYKITHASH}
git branch --set-upstream-to=origin/master localAspenBranch
cd ..
else
cd MediaLibraryKit
git reset --hard ${TESTEDMEDIALIBRARYKITHASH}
cd ..
fi
if ! [ -e VLCKit ]; then
git clone git://git.videolan.org/vlc-bindings/VLCKit.git
cd VLCKit
git reset --hard ${TESTEDVLCKITHASH}
cd ..
else
cd VLCKit
git reset --hard ${TESTEDVLCKITHASH}
cd ..
fi
if ! [ -e GDrive ]; then
svn checkout http://google-api-objectivec-client.googlecode.com/svn/trunk/Source GDrive
cd GDrive && patch -p0 < ../../patches/gdrive/upgrade-default-target.patch && cd ..
else
cd GDrive && svn up && cd ..
fi
if ! [ -e LXReorderableCollectionViewFlowLayout ]; then
git clone git://github.com/fkuehne/LXReorderableCollectionViewFlowLayout.git
else
cd LXReorderableCollectionViewFlowLayout && git pull --rebase && cd ..
fi
if ! [ -e WhiteRaccoon ]; then
git clone git://github.com/fkuehne/WhiteRaccoon.git
else
cd WhiteRaccoon && git pull --rebase && cd ..
fi
if ! [ -e CocoaHTTPServer ]; then
git clone git://github.com/fkuehne/CocoaHTTPServer.git
else
cd CocoaHTTPServer && git pull --rebase && cd ..
fi
if ! [ -e Dropbox ]; then
DROPBOXSDKVERSION=1.3.13
curl -O https://www.dropbox.com/static/developers/dropbox-ios-sdk-${DROPBOXSDKVERSION}.zip
unzip -q dropbox-ios-sdk-${DROPBOXSDKVERSION}.zip
mv dropbox-ios-sdk-${DROPBOXSDKVERSION} Dropbox
rm dropbox-ios-sdk-${DROPBOXSDKVERSION}.zip
rm -rf __MACOSX
fi
if ! [ -e OneDrive ]; then
git clone git://github.com/liveservices/LiveSDK-for-iOS.git OneDrive
cd OneDrive && git am ../../patches/onedrive/0001-Compile-ARMv7s-slice.patch && cd ..
else
cd OneDrive && git pull --rebase && cd ..
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
gtl_build="${aspen_root_dir}/ImportedSources/GDrive/${xcbuilddir}"
onedrive_build="${aspen_root_dir}/ImportedSources/OneDrive/src/${xcbuilddir}"

spopd #ImportedSources

ln -sf ${framework_build} External/MobileVLCKit
ln -sf ${mlkit_build} External/MediaLibraryKit
ln -sf ${gtl_build} External/gtl
ln -sf ${onedrive_build} External/OneDrive

#
# Build time
#

info "Building"

spushd ImportedSources

spushd VLCKit
echo `pwd`
args=""
if [ "$VERBOSE" = "yes" ]; then
    args="${args} -v"
fi
if [ "$PLATFORM" = "iphonesimulator" ]; then
    args="${args} -s"
fi
if [ "$NONETWORK" = "yes" ]; then
    args="${args} -n"
fi
if [ "$SKIPLIBVLCCOMPILATION" = "yes" ]; then
    args="${args} -l"
fi
./buildMobileVLCKit.sh ${args} -k "${SDK}"
buildxcodeproj MobileVLCKit "Aggregate static plugins"
buildxcodeproj MobileVLCKit "MobileVLCKit"
spopd

spushd MediaLibraryKit
rm -f External/MobileVLCKit
ln -sf ${framework_build} External/MobileVLCKit
buildxcodeproj MediaLibraryKit
spopd

spushd GDrive
buildxcodeproj GTL "GTLTouchStaticLib"
spopd

spushd OneDrive/src
buildxcodeproj LiveSDK "LiveSDK"
spopd

spopd # ImportedSources

#install pods
info "installing pods"
pod install

# Build the Aspen Project now
buildxcworkspace "VLC for iOS" "VLC for iOS"

info "Build completed"
