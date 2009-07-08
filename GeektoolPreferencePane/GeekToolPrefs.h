//
//  GeekToolPrefPref.h
//  GeekToolPref
//
//  Created by Yann Bizeul on Thu Nov 21 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <Cocoa/Cocoa.h>

@interface GeekToolPrefs : NSObject 
{        
    IBOutlet id groupController;

    NSWindowController *windowController;
    NSWindow *exposeBorder;    
    
    NSMutableArray *groups;
}
@property (retain) NSMutableArray *groups;

- (id)init;
- (void)awakeFromNib;
- (void)applicationWillTerminate:(NSNotification *)note;
#pragma mark -
#pragma mark UI management
- (IBAction)showExpose:(id)sender;
- (void)exposeBorder;
/*
- (IBAction)fileChoose:(id)sender;
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (IBAction)gChooseFont:(id)sender;
 */
#pragma mark Saving
- (NSString *)pathForDataFile;
- (void)saveDataToDisk;
- (void)loadDataFromDisk;
- (void)loadPreferences;
#pragma mark -
#pragma mark Misc
- (NSRect)screenRect:(NSRect)oldRect;
@end
