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
UNSTABLEVLCKIT=no

TESTEDVLCKITHASH=766c3b7fa
TESTEDMEDIALIBRARYKITHASH=00f96afc8
TESTEDQUINCYKITHASH=f1d93b96b

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
   -u       Compile unstable version of MobileVLCKit
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
         u)
             UNSTABLEVLCKIT=yes
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
if [ "$UNSTABLEVLCKIT" = "no" ]; then
if ! [ -e VLCKit ]; then
git clone git://git.videolan.org/vlc-bindings/VLCKit.git
cd VLCKit
git checkout 2.1-stable
git reset --hard ${TESTEDVLCKITHASH}
cd ..
else
cd VLCKit
git reset --hard ${TESTEDVLCKITHASH}
cd ..
fi
else
if ! [ -e VLCKit ]; then
git clone git://git.videolan.org/vlc-bindings/VLCKit.git
else
git pull --rebase
fi
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
if ! [ -e PLCrashReporter ]; then
git clone https://opensource.plausible.coop/stash/scm/plcr/plcrashreporter.git PLCrashReporter
cd PLCrashReporter
git am ../../patches/plcrashreporter/*.patch
if [ $? -ne 0 ]; then
git am --abort
info "Applying the patches failed, aborting git-am"
exit 1
fi
cd ..
fi
if ! [ -e QuincyKit ]; then
git clone git://github.com/TheRealKerni/QuincyKit.git
cd QuincyKit
git checkout -B localAspenBranch ${TESTEDQUINCYKITHASH}
git branch --set-upstream-to=origin/master localAspenBranch
git am ../../patches/quincykit/*.patch
if [ $? -ne 0 ]; then
git am --abort
info "Applying the patches failed, aborting git-am"
exit 1
fi
cd ..
fi
if ! [ -e GDrive ]; then
svn checkout http://google-api-objectivec-client.googlecode.com/svn/trunk/Source GDrive
cd GDrive && patch -p0 < ../../patches/gdrive/upgrade-default-target.patch && cd ..
else
cd GDrive && svn up && cd ..
fi
if ! [ -e GHSidebarNav ]; then
git clone git://github.com/gresrun/GHSidebarNav.git
else
cd GHSidebarNav && git pull --rebase && cd ..
fi
if ! [ -e LXReorderableCollectionViewFlowLayout ]; then
git clone git://github.com/lxcid/LXReorderableCollectionViewFlowLayout.git
cd LXReorderableCollectionViewFlowLayout
git am ../../patches/lxreorderablecollectionviewflowlayout/*.patch
if [ $? -ne 0 ]; then
git am --abort
info "Applying the patches failed, aborting git-am"
exit 1
fi
cd ..
else
cd LXReorderableCollectionViewFlowLayout && git pull --rebase && cd ..
fi
if ! [ -e upnpx ]; then
git clone git://github.com/fkuehne/upnpx.git
else
cd upnpx && git pull --rebase && cd ..
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
plcrashreporter_build="${aspen_root_dir}/ImportedSources/PLCrashReporter/${xcbuilddir}"
quincykit_build="${aspen_root_dir}/ImportedSources/QuincyKit/client/iOS/QuincyLib/${xcbuilddir}"

spopd #ImportedSources

ln -sf ${framework_build} External/MobileVLCKit
ln -sf ${mlkit_build} External/MediaLibraryKit
ln -sf ${upnpx_build} External/upnpx
ln -sf ${gtl_build} External/gtl
ln -sf ${plcrashreporter_build} External/PLCrashReporter
ln -sf ${quincykit_build} External/QuincyKit

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

spushd upnpx/projects/xcode4/upnpx
buildxcodeproj upnpx
spopd

spushd GDrive
buildxcodeproj GTL "GTLTouchStaticLib"
spopd

spushd PLCrashReporter
if [ "$PLATFORM" = "iphonesimulator" ]; then
    buildxcodeproj CrashReporter "CrashReporter-iOS-Simulator"
else
    buildxcodeproj CrashReporter "CrashReporter-iOS-Device"
fi
spopd

spushd QuincyKit/client/iOS/QuincyLib
buildxcodeproj QuincyLib
spopd

spopd # ImportedSources


# Build the Aspen Project now
buildxcodeproj "VLC for iOS" "vlc-ios"

info "Build completed"
