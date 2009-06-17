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

//NSMutableDictionary *g_logs;
@interface GeekToolPrefs : NSObject 
{
    CFStringRef appID;
    
    IBOutlet id logManager;
    IBOutlet id groupManager;
    IBOutlet id currentGroup;
    IBOutlet id groupSelection;
    IBOutlet id groupsSheet;
    
    NSMutableDictionary *g_logs;
    NSMutableArray *groups;
    NSString *editingGroup;
        
    BOOL isAddingLog;
    NSString *guiPool;
    NSData *selectionColor;

    int numberOfItemsInPoolMenu;
    
}
- (id)init;
- (void)awakeFromNib;
- (void)applicationWillTerminate:(NSNotification *)note;
#pragma mark KVC
- (void)setGroups:(NSArray *)newGroups;
- (NSMutableArray *)groups;
- (void)setSelectionColor:(NSData *)var;
- (NSData*)selectionColor;
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
