#!/bin/sh
# Copyright (C) Pierre d'Herbemont, 2010
# Copyright (C) Felix Paul Kühne, 2012-2013

set -e

PLATFORM=OS
SDK=iphoneos6.1
SDK_MIN=5.1
VERBOSE=no
CONFIGURATION="Release"

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
               -sdk $SDK \
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
             PLATFORM=Simulator
             SDK=iphonesimulator6.1
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

spushd ImportedSources

if ! [ -e vlc ]; then
git clone git://git.videolan.org/vlc.git
info "Applying patches to vlc.git"
cd vlc
git am ../../patches/*.patch
if [ $? -ne 0 ]; then
git am --abort
info "Applying the patches failed, aborting git-am"
exit 1
fi
cd ..
fi
if ! [ -e MediaLibraryKit ]; then
git clone -b Aspen --single-branch git://git.videolan.org/MediaLibraryKit.git
fi
if ! [ -e VLCKit ]; then
git clone git://git.videolan.org/vlc-bindings/VLCKit.git
info "Applying patches to VLCKit.git"
cd VLCKit
git am ../../patches/vlckit/*.patch
if [ $? -ne 0 ]; then
git am --abort
info "Applying the patches failed, aborting git-am"
exit 1
fi
cd ..
fi
if ! [ -e OBSlider ]; then
git clone git://github.com/sylverb/OBSlider.git
info "Applying patches to OBSlider.git"
cd OBSlider
git am ../../patches/obslider/*.patch
if [ $? -ne 0 ]; then
git am --abort
info "Applying the patches failed, aborting git-am"
exit 1
fi
cd ..
fi
if ! [ -e AQGridView ]; then
git clone git://github.com/AlanQuatermain/AQGridView.git
cd AQGridView
git am ../../patches/aqgridview/*.patch
if [ $? -ne 0 ]; then
git am --abort
info "Applying the patches failed, aborting git-am"
exit 1
fi
cd ..
fi

info "Setup 'External' folders"

if [ "$PLATFORM" = "Simulator" ]; then
    xcbuilddir="build/Release-iphonesimulator"
else
    xcbuilddir="build/Release-iphoneos"
fi
framework_build="${aspen_root_dir}/ImportedSources/VLCKit/${xcbuilddir}"
mlkit_build="${aspen_root_dir}/ImportedSources/MediaLibraryKit/${xcbuilddir}"

spushd MediaLibraryKit
rm -f External/MobileVLCKit
ln -sf ${framework_build} External/MobileVLCKit
spopd

spopd #ImportedSources

rm -f External/MobileVLCKit
rm -f External/MediaLibraryKit
ln -sf ${framework_build} External/MobileVLCKit
ln -sf ${mlkit_build} External/MediaLibraryKit

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
if [ "$PLATFORM" = "Simulator" ]; then
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

spopd # ImportedSources


# Build the Aspen Project now
buildxcodeproj AspenProject

info "Build completed"
