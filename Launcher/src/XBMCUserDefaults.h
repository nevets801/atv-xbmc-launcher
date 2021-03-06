//	XBMCUserDefaults.h
//
//	based on:
//  BundleUserDefaults.h
//
//  Created by John Chang on 6/15/07.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import <Cocoa/Cocoa.h>

//define keys for lookup in preferences

extern NSString* const XBMC_USE_UNIVERSAL_REMOTE; //use Launcher in universal mode
extern NSString* const XBMC_EXPERT_MODE; //show additional settings
extern NSString* const XBMC_ADDITIONAL_DOWNLOAD_PLIST_URLS; //holds additional urls for download of updates

@interface XBMCUserDefaults : NSUserDefaults {
	NSString * _applicationID;
	NSDictionary * _registrationDictionary;
}

+ (NSUserDefaults* ) defaults;

@end


@interface NSUserDefaultsController (SetDefaults)
- (void) _setDefaults:(NSUserDefaults *)defaults;
@end
