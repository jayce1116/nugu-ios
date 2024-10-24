#!/bin/sh

PWD="$( cd "$( dirname "$0" )" && pwd -P )"
PROJECT_PATH="${PWD}/.."

VERSION=${1}
regex="^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(\\-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"


if [[ ! $VERSION =~ $regex ]]; then
    echo "Invalid version string."
    echo "usage: versionUpdate.sh X.X.X"
    return
fi

echo "update version to $VERSION";

############# xcconfig update

VERSION_NAME="VERSION ="
XCCONFIG_NAME="shared.xcconfig"
XCCONFIG_PATH="${PROJECT_PATH}/SupportingFiles/${XCCONFIG_NAME}"

sed -i '' "s/${VERSION_NAME} .*/${VERSION_NAME} ${VERSION}/" $XCCONFIG_PATH

############# nuguCore version

NUGU_SDK_VERSION_NAME="public let nuguSDKVersion ="
NUGU_CORE_FILE_NAME="NuguCore.swift"
NUGU_CORE_PATH="${PROJECT_PATH}/NuguCore/Sources/${NUGU_CORE_FILE_NAME}"

sed -i '' "s/${NUGU_SDK_VERSION_NAME} \".*\"/${NUGU_SDK_VERSION_NAME} \"${VERSION}\"/" $NUGU_CORE_PATH


