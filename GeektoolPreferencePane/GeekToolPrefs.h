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

    NSMutableArray *windowControllerArray;
    NSMutableArray *exposeBorderWindowArray;    
    
    NSMutableArray *groups;
}
@property (retain) NSMutableArray *groups;

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
