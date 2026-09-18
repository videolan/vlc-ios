#!/bin/sh
# Author: Felix Paul Kühne <fkuehne # videolan.org>
# Copyright (C) 2026 VideoLAN
#
# Refer to the COPYING file of the official project for license.

set -e

usage()
{
cat << EOF
usage: $0 [options]

Captures the VLC-iOS-Screenshots UI test flows on simulators that already
contain sample content. The app is reinstalled over the existing one, so the
content prepared in the simulator is kept.

OPTIONS
   -d <device>      Simulator name or UDID, repeatable (default: all booted simulators)
   -l <lang[:loc]>  Language and optional locale, e.g. de or pt-BR:pt_BR, repeatable (default: en)
   -a <appearance>  light or dark, repeatable (default: light and dark)
   -t <test>        Only run the given test method, e.g. test15Radio, repeatable
   -o <directory>   Output directory (default: build/screenshots in the repository root)
   -s               Skip building and reuse the previous build products
   -h               Show this help
EOF
}

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/../../.." && pwd)

DEVICES=""
LANGUAGES=""
APPEARANCES=""
ONLY_TESTING=""
OUTPUT_DIR="$ROOT_DIR/build/screenshots"
SKIP_BUILD=no
DERIVED_DATA_DIR="$ROOT_DIR/build/screenshots-DerivedData"
TEST_BUNDLE="VLC-iOS-Screenshots"
TEST_CLASS="Screenshot"

while getopts "d:l:a:t:o:sh" OPTION
do
    case $OPTION in
        d)
            DEVICES="$DEVICES
$OPTARG"
            ;;
        l)
            LANGUAGES="$LANGUAGES $OPTARG"
            ;;
        a)
            APPEARANCES="$APPEARANCES $OPTARG"
            ;;
        t)
            ONLY_TESTING="$ONLY_TESTING -only-testing:$TEST_BUNDLE/$TEST_CLASS/$OPTARG"
            ;;
        o)
            OUTPUT_DIR="$OPTARG"
            ;;
        s)
            SKIP_BUILD=yes
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

[ -z "$LANGUAGES" ] && LANGUAGES="en"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)
[ -z "$APPEARANCES" ] && APPEARANCES="light dark"

info()
{
    printf '\033[1;32m[screenshots]\033[0m %s\n' "$1"
}

fail()
{
    printf '\033[1;31m[screenshots]\033[0m %s\n' "$1" >&2
    exit 1
}

simulator_line()
{
    MATCHES=$(xcrun simctl list devices available | grep -F -e "($1)" -e "    $1 (" || true)
    BOOTED=$(echo "$MATCHES" | grep -F "(Booted)" | head -n 1)
    if [ -n "$BOOTED" ]; then
        echo "$BOOTED"
    else
        echo "$MATCHES" | tail -n 1
    fi
}

if [ -z "$DEVICES" ]; then
    DEVICES=$(xcrun simctl list devices booted | grep -E '\([0-9A-F-]{36}\)' | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
    [ -z "$DEVICES" ] && fail "No booted simulator, pass one with -d"
fi

if [ "$SKIP_BUILD" = "no" ]; then
    info "Building $TEST_BUNDLE"
    xcodebuild build-for-testing \
        -workspace "$ROOT_DIR/VLC.xcworkspace" \
        -scheme "$TEST_BUNDLE" \
        -configuration Debug \
        -destination "generic/platform=iOS Simulator" \
        -derivedDataPath "$DERIVED_DATA_DIR" \
        -quiet
fi

XCTESTRUN=$(find "$DERIVED_DATA_DIR/Build/Products" -maxdepth 1 -name "${TEST_BUNDLE}_*.xctestrun" 2>/dev/null | head -n 1)
[ -z "$XCTESTRUN" ] && fail "No xctestrun file in $DERIVED_DATA_DIR, run without -s first"
RUN_XCTESTRUN="$(dirname "$XCTESTRUN")/screenshots-run.xctestrun"

XCODEBUILD_PID=""
trap '[ -n "$XCODEBUILD_PID" ] && kill "$XCODEBUILD_PID" 2>/dev/null; exit 130' INT TERM

DEFAULT_IFS=$IFS
IFS='
'
for DEVICE in $DEVICES
do
    IFS=$DEFAULT_IFS
    [ -z "$DEVICE" ] && continue

    LINE=$(simulator_line "$DEVICE")
    [ -z "$LINE" ] && fail "Unknown simulator $DEVICE"
    UDID=$(echo "$LINE" | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
    NAME=$(echo "$LINE" | sed -E 's/^ *(.*) \([0-9A-F-]{36}\).*/\1/')

    info "Preparing $NAME ($UDID)"
    xcrun simctl boot "$UDID" 2>/dev/null || true
    xcrun simctl bootstatus "$UDID" > /dev/null
    xcrun simctl status_bar "$UDID" override \
        --time "9:41" \
        --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --operatorName "" \
        --batteryState charged --batteryLevel 100

    for APPEARANCE in $APPEARANCES
    do
        xcrun simctl ui "$UDID" appearance "$APPEARANCE"

        for LANGUAGE_SPEC in $LANGUAGES
        do
            LANGUAGE=${LANGUAGE_SPEC%%:*}
            LOCALE=${LANGUAGE_SPEC#*:}
            [ "$LOCALE" = "$LANGUAGE_SPEC" ] && LOCALE=$(echo "$LANGUAGE" | tr '-' '_')

            DESTINATION_DIR="$OUTPUT_DIR/$NAME/$LANGUAGE/$APPEARANCE"
            RESULT_BUNDLE="$OUTPUT_DIR/results/$NAME-$LANGUAGE-$APPEARANCE.xcresult"
            mkdir -p "$DESTINATION_DIR" "$OUTPUT_DIR/results"
            [ -z "$ONLY_TESTING" ] && rm -f "$DESTINATION_DIR"/*.png
            rm -rf "$RESULT_BUNDLE"

            cp "$XCTESTRUN" "$RUN_XCTESTRUN"
            ENVIRONMENT="$TEST_BUNDLE.EnvironmentVariables"
            plutil -replace "$ENVIRONMENT.VLC_SCREENSHOTS_OUTPUT" -string "$DESTINATION_DIR" "$RUN_XCTESTRUN"
            plutil -replace "$ENVIRONMENT.VLC_SCREENSHOTS_LANGUAGE" -string "$LANGUAGE" "$RUN_XCTESTRUN"
            plutil -replace "$ENVIRONMENT.VLC_SCREENSHOTS_LOCALE" -string "$LOCALE" "$RUN_XCTESTRUN"

            info "Capturing $NAME, $LANGUAGE ($LOCALE), $APPEARANCE"
            # shellcheck disable=SC2086
            xcodebuild test-without-building \
                -xctestrun "$RUN_XCTESTRUN" \
                -destination "id=$UDID" \
                -resultBundlePath "$RESULT_BUNDLE" \
                -collect-test-diagnostics never \
                $ONLY_TESTING \
                -quiet &
            XCODEBUILD_PID=$!
            if ! wait "$XCODEBUILD_PID"; then
                printf '\033[1;33m[screenshots]\033[0m Some flows failed for %s, %s, %s, see %s\n' \
                    "$NAME" "$LANGUAGE" "$APPEARANCE" "$RESULT_BUNDLE" >&2
            fi
            XCODEBUILD_PID=""
        done
    done

    xcrun simctl status_bar "$UDID" clear
done

info "Screenshots are in $OUTPUT_DIR"
