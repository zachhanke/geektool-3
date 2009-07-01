//
//  GeekToolPrefPref.m
//  GeekToolPref
//
//  Created by Yann Bizeul on Thu Nov 21 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "GeekToolPrefs.h"
#import "NTGroup.h"
#import "defines.h"

@implementation GeekToolPrefs

- (id)init
{
    if (self = [super init])
    {
        groups = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)awakeFromNib
{
    [self loadDataFromDisk];
    [self loadPreferences];
    
    [[NSColorPanel sharedColorPanel]setShowsAlpha:YES];
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    [self saveDataToDisk];
}  

#pragma mark KVC
- (void)setGroups:(NSArray *)newGroups
{
    if (groups != newGroups)
    {
        [groups autorelease];
        groups = [[NSMutableArray alloc]initWithArray:newGroups];
    }
}

- (NSMutableArray *)groups
{
    return groups;
}

#pragma mark -
#pragma mark UI management
/*
- (IBAction)fileChoose:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection: NO];
    [openPanel setCanChooseFiles: YES];
    [openPanel beginSheetForDirectory: @"/var/log/"
                                 file: @"system.log"
                                types: nil
                       modalForWindow: [NSApp mainWindow]
                        modalDelegate: self
                       didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo: nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [NSApp endSheet: sheet];
    if (returnCode == NSOKButton) {
        NSArray *filesToOpen = [sheet filenames];
        // TODO: write to path dictionary directly. bindings should take care of
        // this 
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn)
        [sheet close];
}

-(IBAction)gChooseFont:(id)sender
{
    // TODO: bindings maybe?
     switch ([self logType])
     {
     case 0:
     [[[self mainView] window] makeFirstResponder: cf1FontTextField];
     break;
     case 1:
     [[[self mainView] window] makeFirstResponder: cf2FontTextField];
     break;
     }
     [[NSFontManager sharedFontManager] orderFrontFontPanel: self];
}
*/

#pragma mark Saving
- (NSString *)pathForDataFile
{
    NSString *appSupportDir = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES) objectAtIndex:0]stringByAppendingPathComponent:[[NSProcessInfo processInfo]processName]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:appSupportDir] == NO)
        [[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir attributes:nil];
    
    return [appSupportDir stringByAppendingPathComponent:@"LogData.ntdata"];    
}

- (void)saveDataToDisk
{
    NSString *path = [self pathForDataFile];
    
    NSMutableDictionary *rootObject;
    rootObject = [NSMutableDictionary dictionary];
    
    [rootObject setValue:[self groups] forKey:@"groups"];
    [NSKeyedArchiver archiveRootObject:rootObject toFile:path];
}

- (void)loadDataFromDisk
{
    NSString *path = [self pathForDataFile];
    
    NSDictionary *rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    NSArray *groupArray = [rootObject valueForKey:@"groups"];
    
    if (!groupArray)
    {
        [groupArray release];
        NTGroup *defaultGroup = [[NTGroup alloc]init];
        groupArray = [NSArray arrayWithObject:defaultGroup];
    }
    
    [self setGroups:groupArray];
    
    for (NTGroup *tmp in groups)
        if ([[tmp properties] objectForKey:@"active"]) [groupController setSelectedObjects:[NSArray arrayWithObject:tmp]];  
}

- (void)loadPreferences
{
    NSData *selectionColorData = [[NSUserDefaults standardUserDefaults] objectForKey: @"selectionColor"];
    if (!selectionColorData) selectionColorData = [NSArchiver archivedDataWithRootObject:[[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.3]];
    [[NSUserDefaults standardUserDefaults] setObject:selectionColorData forKey:@"selectionColor"];
}


#pragma mark -
#pragma mark Misc

- (NSRect)screenRect:(NSRect)oldRect
{
    NSRect screenSize = [[NSScreen mainScreen] frame];
    int screenY = screenSize.size.height - oldRect.origin.y - oldRect.size.height;
    return NSMakeRect(oldRect.origin.x, screenY, oldRect.size.width, oldRect.size.height);
}

@end
