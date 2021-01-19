#!/usr/bin/env bash

set -e

if which jq >/dev/null; then
    echo "jq is installed"
else
    echo "error: jq not installed.(brew install jq)"
fi

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'

#  ---- enable the following code after the new pod has been released. ----
# LATEST_PUBLIC_VERSION=$(pod spec cat AEPRulesEngine | jq '.version' | tr -d '"')
# echo "Latest public version is: ${BLUE}$LATEST_PUBLIC_VERSION${NC}"
# if [[ "$1" == "$LATEST_PUBLIC_VERSION" ]]; then
#     echo "${RED}[Error]${NC} $LATEST_PUBLIC_VERSION has been released!"
#     exit -1
# fi
echo "Target version - ${BLUE}$1${NC}"
echo "------------------AEPEdge-------------------"
PODSPEC_VERSION_IN_AEPEdge=$(pod ipc spec AEPEdge.podspec | jq '.version' | tr -d '"')
echo "Local podspec version - ${BLUE}${PODSPEC_VERSION_IN_AEPEdge}${NC}"
SOUCE_CODE_VERSION_IN_AEPEdge=$(cat ./Sources/EdgeConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')
echo "Souce code version - ${BLUE}${SOUCE_CODE_VERSION_IN_AEPEdge}${NC}"

if [[ "$1" == "$PODSPEC_VERSION_IN_AEPEdge" ]] && [[ "$1" == "$SOUCE_CODE_VERSION_IN_AEPEdge" ]]; then
    echo "${GREEN}Pass!${NC}"
else
    echo "${RED}[Error]${NC} Version do not match!"
    exit -1
fi
exit 0
