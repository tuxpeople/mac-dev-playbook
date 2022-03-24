#!/usr/bin/env bash

URL=$(curl -qL https://www.citrix.com/de-de/downloads/workspace-app/mac/workspace-app-for-mac-latest.html | grep CitrixWorkspaceApp.dmg | grep rel | awk '{ print $8}' | sed 's|rel="|https:|' | sed 's|"||')
DMG="/tmp/CitrixWorkspaceApp.dmg"

curl -L ${URL} -o ${DMG}

volume=$(hdiutil attach ${DMG} | grep /Volumes | sed 's/.*\/Volumes\//\/Volumes\//')

installer -pkg "${volume}/Install Citrix Workspace.pkg" -target /

hdiutil detach "${volume}"

rm -rf ${DMG}