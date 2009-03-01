//
//  XBMCUpdateController.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 20.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//
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

#import "XBMCUpdateController.h"
#import "XBMCDebugHelpers.h"
#import "XBMCUpdateBlockingController.h"
#import "XBMCSimpleDownloader.h"

@class BRLayerController;
@implementation XBMCUpdateController


- (id) init {
	[self dealloc];
	@throw [NSException exceptionWithName:@"BNRBadInitCall" reason:@"Init XBMCUpdateController with initWithURL" userInfo:nil];
	return nil;
}


- (id) initWithURL:(NSURL*) fp_url {
	PRINT_SIGNATURE();
	if( ! [super init])
		return nil;
	mp_url = [fp_url retain];
    mp_downloads = [[NSMutableArray alloc] init];
    mp_downloader = nil;
    mp_blocking_updater = nil;
	return self;
}

- (void) dealloc {
	PRINT_SIGNATURE();
	[mp_url release];
	[mp_updates release];
	[mp_items release]; 
    [mp_downloads release]; 
	[super dealloc];
}

- (void) wasPushed {	
	[super setListTitle: @"Launcher"];
	[super setPrimaryInfoText: @"Downloads"];
	[super setSecondaryInfoText: @"Available Downloads:"];
	NSString *error;
	NSPropertyListFormat format;
	NSData* plistdata = [NSData dataWithContentsOfURL: mp_url];
	mp_updates = [[NSPropertyListSerialization propertyListFromData:plistdata
                                                   mutabilityOption:NSPropertyListImmutable
                                                             format:&format
                                                   errorDescription:&error] retain];
	if(!mp_updates)
	{
        NSLog(error);
        [error release];
		[[self stack] swapController: [BRAlertController alertOfType:0 titled:nil primaryText:@"Update URLs not found or corrupt!" 
                                                       secondaryText:[NSString stringWithFormat:@" %@", mp_url]]];
	} 
	mp_items = [[NSMutableArray alloc] initWithObjects:nil]; 
	unsigned int i;
	for(i=0; i < [mp_updates count]; ++i){
		id item = [BRTextMenuItemLayer menuItem];
		NSDictionary* dict = [mp_updates objectAtIndex:i];
		[item setTitle:[dict valueForKey:@"Name"]];
		[item setRightJustifiedText:[dict valueForKey:@"Type"]];
		[mp_items addObject:item];
	}
	//set ourselves as datasource for the updater list
	[[self list] setDatasource: self];
	[super wasPushed];
}

- (void)itemSelected:(long)index {
	PRINT_SIGNATURE();
	m_update_item = index;
	//get the dict for this update
	NSDictionary* dict = [mp_updates objectAtIndex:index];
	//first download the script. this should be easy
	NSString* scriptURL =  [dict valueForKey:@"UpdateScript"];
	NSData* script_data = [NSData dataWithContentsOfURL: [NSURL URLWithString:scriptURL]];
	if(! script_data ){
		ELOG(@"Could not download update script from %@", [dict valueForKey:@"UpdateScript"]);
		return;
	}
	//store it where XBMCDownloader stores stuff, too
	NSString* script_path = [XBMCSimpleDownloader outputPathForURLString:[dict valueForKey:@"UpdateScript"]];
	[[NSFileManager defaultManager] createDirectoryAtPath: [script_path stringByDeletingLastPathComponent]
                                               attributes: nil];
	if( ! [script_data writeToFile:script_path atomically:YES] ) {
		ELOG(@"Could not save update script to %@", script_path);
		return;
	}
	DLOG(@"Downloaded update script to %@. Starting download of update...", script_path);
    [mp_downloads removeAllObjects];
	//now start the real download, optionally check for md5 when finished
    [mp_downloads addObject:[XBMCSimpleDownloader outputPathForURLString:[dict valueForKey:@"URL"]]];
	mp_downloader = [[XBMCSimpleDownloader alloc] initWithDownloadPath:[dict valueForKey:@"URL"] MD5:[dict objectForKey:@"MD5"]];
	[mp_downloader setTitle:[NSString stringWithFormat:@"Downloading: %@",[dict valueForKey:@"Name"]]];
	[[self stack] pushController: mp_downloader];
}

- (BOOL) isNetworkDependent{
	return TRUE;
}

- (float)heightForRow:(long)row				{	return 0.0f; }
- (BOOL)rowSelectable:(long)row				{	return YES;}
- (long)itemCount							{	return (long) [mp_items count];}
- (id)itemForRow:(long)row					{	return [mp_items objectAtIndex:row]; }
- (long)rowForTitle:(id)title				{	return (long)[mp_items indexOfObject:title]; }
- (id)titleForRow:(long)row					{	return [[mp_items objectAtIndex:row] title]; }

- (void)controlWasActivated{
    PRINT_SIGNATURE();
    
	//if the download controller popped us check if download was properly finished
	if(mp_downloader){
		if ( [mp_downloader downloadComplete] ){
            DLOG(@"Download finished");
            if ( [ mp_downloader MD5SumMismatch] ){
                [[self stack] pushController: [BRAlertController alertOfType:0 
                                                                      titled:@"Error" 
                                                                 primaryText:@"MD5 sums don't match. Please try to redownload."
                                                               secondaryText:@"If this message still appears after redownload, updates have changed.This should be corrected automatically in a few hours, if not please file an issue at http://atv-xbmc-launcher.googlecode.com. Thanks!" 
                                               ]];
                [mp_downloader release];
                mp_downloader = nil;
                [super controlWasActivated];
                return;
            } else {     
                NSDictionary* dict = [mp_updates objectAtIndex:m_update_item];
                //check if there is another download we want to start
                NSString* next_url_lookup = [NSString stringWithFormat:@"URL_%i",[mp_downloads count]];
                DLOG(@"checking for next URL with %@", next_url_lookup);
                NSString* l_url = [dict valueForKey:next_url_lookup];
                if(l_url){
                    DLOG(@"found new url: %@", l_url);
                    //there' another download. start that one first
                    NSString* next_md5_lookup = [NSString stringWithFormat:@"MD5_%i",[mp_downloads count]];
                    [mp_downloader release]; 
                    mp_downloader = nil;
                    [mp_downloads addObject:[XBMCSimpleDownloader outputPathForURLString:l_url]];
                    mp_downloader = [[XBMCSimpleDownloader alloc] initWithDownloadPath:l_url 
                                                                                   MD5:[dict objectForKey:next_md5_lookup]];
                    [mp_downloader setTitle:[NSString stringWithFormat:@"Downloading update: %@",[dict valueForKey:@"Name"]]];
                    [[self stack] pushController: mp_downloader];
                    [super controlWasActivated];
                    return;
                }
                //start the update script with path to downloaded file(s) 
                NSString* script_path = [XBMCSimpleDownloader outputPathForURLString:[dict valueForKey:@"UpdateScript"]];
                DLOG(@"Running update %@ with argument %@", script_path, mp_downloads);
                mp_blocking_updater = [[XBMCUpdateBlockingController alloc] 
                                       initWithScript: script_path downloads:mp_downloads];
                [[self stack] pushController: mp_blocking_updater];
            }
		}else {
			DLOG(@"Download not yet completed");
		}
		//release the downloader, it gets recreated on new selection
		[mp_downloader release];
		mp_downloader = nil;
	} else if(mp_blocking_updater) {
		//clear downloaded files
		DLOG(@"Update finished. Clearing download cache");
		NSDictionary* dict = [mp_updates objectAtIndex:m_update_item];
		NSString* script_folder = [[XBMCSimpleDownloader outputPathForURLString:[dict valueForKey:@"UpdateScript"]] stringByDeletingLastPathComponent];
		NSString* download_folder =  [[XBMCSimpleDownloader outputPathForURLString:[dict valueForKey:@"URL"]] stringByDeletingLastPathComponent];
		DLOG("removing %@ and %@:", script_folder, download_folder);
		[[NSFileManager defaultManager] removeFileAtPath: script_folder
                                                 handler: nil];
		[[NSFileManager defaultManager] removeFileAtPath: download_folder
                                                 handler: nil];
        [mp_blocking_updater release];
        mp_blocking_updater = nil;
	} else {
        DLOG(@"We were just activated, nothing todo yet");
    }
    [super controlWasActivated];
}

- (void)controlWasDeactivated{
    PRINT_SIGNATURE();
    [super controlWasDeactivated];
}

- (void) wasPopped{
    PRINT_SIGNATURE();
    [super wasPopped];
}

@end
