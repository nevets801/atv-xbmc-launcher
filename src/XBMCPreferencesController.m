//
//  XBMCPreferencesController.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 25.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import "XBMCPreferencesController.h"
#import "XBMCUserDefaults.h"
#import "XBMCDebugHelpers.h"

@implementation XBMCPreferencesController

+ (BOOL) autoUpdateEnabled{
  PRINT_SIGNATURE();
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  NSTask* task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/grep" arguments:[NSArray arrayWithObjects:@"mesu.apple.com", @"/etc/hosts",nil]];
  [task waitUntilExit];
  int status = [task terminationStatus];
  [pool release];
  PRINT_SIGNATURE();
  return (status != 0);
}

+ (void) setAutoUpdate:(BOOL) f_enabled{
  PRINT_SIGNATURE();
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  NSString* argument; 
  if(f_enabled)
    argument = @"ON";
  else
    argument = @"OFF";
  NSString* helper_path = [[NSBundle bundleForClass:[self class]] pathForResource:@"setAutoUpdate" ofType:@"sh"];
  DLOG(@"%@",helper_path);
  NSTask* helper = [NSTask launchedTaskWithLaunchPath:@"/bin/bash" arguments: [NSArray arrayWithObjects:
                                                                               helper_path,
                                                                               argument,
                                                                               nil]];
    
  [helper waitUntilExit];
  [pool release];
}

- (float)heightForRow:(long)row				{	return 0.0f; }
- (BOOL)rowSelectable:(long)row				{	return YES;	}
- (long)itemCount							{	return (long) [mp_items count];}
- (id)itemForRow:(long)row					{	return [mp_items objectAtIndex:row]; }
- (long)rowForTitle:(id)title				{	return (long)[mp_items indexOfObject:title]; }
- (id)titleForRow:(long)row					{	return [[mp_items objectAtIndex:row] title]; }

- (id) init{
	PRINT_SIGNATURE();
	if( ! [super init])
		return nil;
	return self;
}

- (void) dealloc {
	PRINT_SIGNATURE();
	[mp_items release]; 
	[super dealloc];
}

- (void) wasPushed {	
	[super setListTitle: @"Launcher"];
	[super setPrimaryInfoText:@"Settings"];
	[self recreateMenuList];
	//set ourselves as datasource for the updater list
	[[self list] setDatasource: self];
	[super wasPushed];
}

- (void)itemSelected:(long)index {
	PRINT_SIGNATURE();
	//hack! TODO: if there are more items, do proper selection handling with index 
  switch(index){
    case 0:
    {
      int val = [[XBMCUserDefaults defaults] boolForKey:XBMC_USE_UNIVERSAL_REMOTE];
      [[XBMCUserDefaults defaults] setBool:!val forKey:XBMC_USE_UNIVERSAL_REMOTE];
      [[XBMCUserDefaults defaults] synchronize];
      [[self itemForRow:index] setRightJustifiedText:[[XBMCUserDefaults defaults] boolForKey:XBMC_USE_UNIVERSAL_REMOTE] ? @"Yes": @"No"];
      break;
    }
    case 1:
    {
      NSString* current = [[self itemForRow:index] rightJustifiedText];
      if( [current isEqualToString:@"Yes"] )
        [XBMCPreferencesController setAutoUpdate:FALSE];
      else if( [current isEqualToString:@"No"] )
        [XBMCPreferencesController setAutoUpdate:TRUE];
      else
        ELOG(@"Arg, can't be true! Translation issue?!");
      [[self itemForRow:index] setRightJustifiedText:[XBMCPreferencesController autoUpdateEnabled]? @"Yes": @"No"];
      break;
    }
    default:
      ELOG(@"Huh? Item is not in list :/");
      break;
	}
	[[self list] reload];
}

- (void) recreateMenuList
{
  PRINT_SIGNATURE();
	if(!mp_items){
		mp_items = [[NSMutableArray alloc] initWithObjects:nil]; 
	} else {
		[mp_items removeAllObjects];
	}
	id item = [BRTextMenuItemLayer menuItem];
  [item setTitle:@"Use Universal Mode"];
  [item setRightJustifiedText:[[XBMCUserDefaults defaults] boolForKey:XBMC_USE_UNIVERSAL_REMOTE] ? @"Yes": @"No"];
  [mp_items addObject:item];
	item = [BRTextMenuItemLayer menuItem];
  [item setTitle:@"ATV OS Update enabled"];
  [item setRightJustifiedText:[XBMCPreferencesController autoUpdateEnabled] ? @"Yes": @"No"];
  [mp_items addObject:item];
  
}

@end