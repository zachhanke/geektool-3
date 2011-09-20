//
//  GeekToolPrefPref.h
//  GeekToolPref
//
//  Created by Yann Bizeul on Thu Nov 21 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GeekToolPrefs : NSObject 
{        
    IBOutlet id groupController;
    IBOutlet id logController;
    IBOutlet id mainConfigWindow;
    
    BOOL hitROProcess;
    IBOutlet id NTEnable;
    IBOutlet id loginItem;
    
    NSMutableArray *windowControllerArray;
    NSMutableArray *exposeBorderWindowArray;    
    
    NSMutableArray *groups;
}
@property (retain) NSMutableArray *groups;

#pragma mark -
- (IBAction)trackROProcess:(id)sender;
#pragma mark UI management
- (IBAction)addAsLoginItem:(id)sender;
- (IBAction)logImport:(id)sender;
- (IBAction)revertDefaultSelectionColor:(id)sender;
- (IBAction)showExpose:(id)sender;
- (void)exposeBorder;
- (IBAction)donate:(id)sender;
- (IBAction)openReadme:(id)sender;
- (IBAction)refreshGroupSelection:(id)sender;
#pragma mark Saving
- (NSString *)pathForDataFile;
- (void)saveDataToDisk;
- (void)loadDataFromDisk;
- (void)loadPreferences;
#pragma mark -
#pragma mark Misc
- (NSRect)screenRect:(NSRect)oldRect;
@end
