/*
 *  xbmcclient.cpp
 *  xbmclauncher
 *
 *  Created by Stephan Diederich on 17.09.08.
 *  Copyright 2008 Stephan Diederich. All rights reserved.
 *
 */
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
#import <Cocoa/Cocoa.h>
typedef enum{
  ATV_BUTTON_DONT_USE_THIS = 0, //don't use zero, as those enums get converted to strings later
	ATV_BUTTON_PLAY=1,
	ATV_BUTTON_PLAY_H, //present on ATV>=2.2
	ATV_BUTTON_RIGHT,
	ATV_BUTTON_RIGHT_RELEASE,
	ATV_BUTTON_RIGHT_H, //present on ATV<=2.1
	ATV_BUTTON_LEFT,
	ATV_BUTTON_LEFT_RELEASE,
	ATV_BUTTON_LEFT_H, //present on ATV<=2.1
	ATV_BUTTON_UP,
	ATV_BUTTON_UP_RELEASE,
	ATV_BUTTON_DOWN,
	ATV_BUTTON_DOWN_RELEASE,
	ATV_BUTTON_MENU,
	ATV_BUTTON_MENU_H,
	ATV_INVALID_BUTTON
} eATVClientEvent;

@interface XBMCClientWrapper : NSObject{
	struct XBMCClientWrapperImpl* mp_impl;
}
- (id) initWithUniversalMode:(bool) f_yes_no serverAddress:(NSString*) fp_server;
- (void) setUniversalModeTimeout:(double) f_timeout;

-(void) handleEvent:(eATVClientEvent) f_event;

@end