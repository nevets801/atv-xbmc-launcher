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

  # handle any pre-install items here
  echo $PW | sudo -S rm -rf "/Applications/Boxee.app/Contents/Resources/Boxee/skin"

  # install xbmc app
  echo $PW | sudo -S hdiutil attach $DISKIMAGE 
  echo $PW | sudo -S installer -pkg /Volumes/boxee-0.9.7/boxee-0.9.7.4825-atv.mpkg -target /
  echo $PW | sudo -S hdiutil detach /Volumes/boxee-0.9.7

  # handle any post-install items here
  echo $PW | sudo -S chown -R frontrow:frontrow "/Applications/Boxee.app"
  echo $PW | sudo -S chown -R frontrow:frontrow "/Users/frontrow/Library/Application Support/BOXEE"

  # remove old keymap
  echo $PW | /bin/rm -f "/Users/frontrow/Library/Application\ Support/BOXEE/UserData/Keymap.xml"

  # Update sources
  echo $PW | /Applications/Boxee.app/Contents/MacOS/Boxee -usf

  echo $PW | sed -i"" -e 's/port>9770/port>9777/g' "/Users/frontrow/Library/Application\ Support/BOXEE/UserData/guisettings.xml"

  #sync to disk, just in case...
  /bin/sync

  # clean up
  #if [ -e /Users/Frontrow/Movies/boxee-0.9.7.4825 ]; then
  # something makes this symlink during install so zap it.
  echo $PW | sudo -S rm /Users/Frontrow/Movies/boxee-0.9.7.4825
  echo $PW | sudo -S rm /Users/Frontrow/Movies/boxee-0.9.7.4825-atv
  #fi

  # restore OSBoot read/write settings
  if [ "$REMOUNT" = "1" ]; then
    echo $PW | sudo -S /sbin/mount -ur /
  fi

  exit 0
fi
echo "Failed to find diskimage $DISKIMAGE"
exit -1
