//
//  GeekToolPrefPref.h
//  GeekToolPref
//
//  Created by Yann Bizeul on Thu Nov 21 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <Cocoa/Cocoa.h>

#import "GTLog.h"
#import "NTGroup.h"

//NSMutableDictionary *g_logs;
@interface GeekToolPrefs : NSObject 
{    
    IBOutlet id activeGroupButton;

    NSMutableArray *groups;
    NTGroup *activeGroup;
    NSData *selectionColor;    
}
- (id)init;
- (void)awakeFromNib;
- (void)applicationWillTerminate:(NSNotification *)note;
#pragma mark KVC
- (void)setGroups:(NSArray *)newGroups;
- (NSMutableArray *)groups;
- (void)setSelectionColor:(NSData *)var;
- (NSData*)selectionColor;
- (void)setActiveGroup:(NTGroup *)newActiveGroup;
- (NTGroup *)activeGroup;
#pragma mark -
#pragma mark UI management
- (IBAction)fileChoose:(id)sender;
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (IBAction)gChooseFont:(id)sender;
#pragma mark -
#pragma mark Daemon interaction
- (void)didSelect;
- (void)didUnselect;
- (void)geekToolLaunched:(NSNotification*)aNotification;
#pragma mark Saving
- (NSString *)pathForDataFile;
- (void)saveDataToDisk;
- (void)loadDataFromDisk;
- (void)loadPreferences;
#pragma mark -
#pragma mark Misc
- (NSRect)screenRect:(NSRect)oldRect;
@end
