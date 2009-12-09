#!/bin/sh

DISKIMAGE=$1

echo "Installing from diskimage $DISKIMAGE"
# check that disk-image exists
if [ -e $DISKIMAGE ]; then
  PW="frontrow"

  # check and store OSBoot read/write settings
  REMOUNT=0
  # Check if / is mounted read only
  if mount | grep ' on / '  | grep -q 'read-only'; then
    REMOUNT=1
    echo $PW | sudo -S /sbin/mount -uw /
  fi

  # install xbmc app
  echo $PW | sudo -S hdiutil attach $DISKIMAGE 
  #remove old app
  echo $PW | sudo -S rm -r /Applications/XBMC.app
  echo $PW | sudo -S rm -r /Users/frontrow/Applications/XBMC.app
  #copy new one
  mkdir -p /Users/frontrow/Applications
  cp -r /Volumes/XBMC/XBMC.app /Users/frontrow/Applications/
  echo $PW | sudo -S hdiutil detach /Volumes/XBMC
  #symlink to /Applications
  echo $PW | sudo -S ln -s /Users/frontrow/Applications/XBMC.app /Applications/

  # handle any post-install items here
  # perl to bash convertion of postflight script pending
  if [ ! -d /Users/frontrow/Movies ]; then
    echo $PW | sudo -S mkdir /Users/frontrow/Movies
    echo $PW | sudo -S chown frontrow:frontrow /Users/frontrow/Movies
  fi
  if [ ! -d "/Users/frontrow/Video Playlists" ]; then
    echo $PW | sudo -S mkdir "/Users/frontrow/Video Playlists"
    echo $PW | sudo -S chown frontrow:frontrow "/Users/frontrow/Video Playlists"
  fi
  if [ ! -d /Users/frontrow/Music ]; then
    echo $PW | sudo -S mkdir /Users/frontrow/Music
    echo $PW | sudo -S chown frontrow:frontrow /Users/frontrow/Music
  fi
  if [ ! -d "/Users/frontrow/Music Playlists" ]; then
    echo $PW | sudo -S mkdir "/Users/frontrow/Music Playlists"
    echo $PW | sudo -S chown frontrow:frontrow "/Users/frontrow/Music Playlists"
  fi
  if [ ! -d /Users/frontrow/Pictures ]; then
    echo $PW | sudo -S mkdir /Users/frontrow/Pictures
    echo $PW | sudo -S chown frontrow:frontrow /Users/frontrow/Pictures
  fi
  
  if [ ! -d /Users/frontrow/Library/Logs ]; then
    echo $PW | sudo -S mkdir -p /Users/frontrow/Library/Logs
    echo $PW | sudo -S chown frontrow:frontrow /Users/frontrow/Library/Logs
  fi

  if [ ! -d "/Users/frontrow/Library/Application Support/XBMC/userdata/" ]; then
  	mkdir -p "/Users/frontrow/Library/Application Support/XBMC/userdata/"
  fi

  #add advancedsettings for better h.264 experience
  AVDSETTINGS_PATH="/Users/frontrow/Library/Application Support/XBMC/userdata/advancedsettings.xml"
  if [ ! -e "$AVDSETTINGS_PATH" ]; then
  	echo "<advancedsettings><skiploopfilter>8</skiploopfilter></advancedsettings>" >> "$AVDSETTINGS_PATH"
  else
  	#fix typo that was present up to r212
	sed -e s/sliploopfilter/skiploopfilter/g -i "" "$AVDSETTINGS_PATH"
  fi

  #d4rk said this is already done in installer; do it anyway, can't hurt
  echo $PW | sudo -S chown -R frontrow "/Users/frontrow/Library/Application Support/XBMC"
  if [ -e "/Users/frontrow/Library/Application Support/Remote Buddy" ]; then
    echo $PW | sudo -S chown -R frontrow "/Users/frontrow/Library/Application Support/Remote Buddy"
  fi
  
  #delete xbmchelper it's not used on ATV
  if [ -e /Users/frontrow/Applications/XBMC.app/Contents/Resources/XBMC/tools/osx/XBMCHelper ]; then
  	echo $PW | sudo -S rm /Users/frontrow/Applications/XBMC.app/Contents/Resources/XBMC/tools/osx/XBMCHelper
  fi
  # clean up
  if [ -h /Users/frontrow/Movies/XBMC ]; then
  	# something makes this symlink during install so zap it.
  	echo $PW | sudo -S rm /Users/frontrow/Movies/XBMC
  fi
  
  #sync to disk, just in case...
  /bin/sync

  # restore OSBoot read/write settings
  if [ "$REMOUNT" = "1" ]; then
    echo $PW | sudo -S /sbin/mount -ur /
  fi

  exit 0
fi

echo "Failed to find diskimage $DISKIMAGE"
exit -1