//
//  GeekToolPrefPref.m
//  GeekToolPref
//
//  Created by Yann Bizeul on Thu Nov 21 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "GeekToolPrefs.h"
#import "LogController.h"
#import "NTGroup.h"
#import "defines.h"

@implementation GeekToolPrefs

- (id)init
{
    if (self = [super init])
    {
        groups = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)awakeFromNib
{
    [self loadDataFromDisk];
    [self loadPreferences];
    
    // Yes, we need transparency
    [[NSColorPanel sharedColorPanel] setShowsAlpha: YES];
    
    NSNumber *en = [[NSUserDefaults standardUserDefaults] objectForKey: @"enableMenu"];
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
        groups = [[NSMutableArray alloc] initWithArray:newGroups];
    }
}

- (NSMutableArray *)groups
{
    return groups;
}

- (void)setSelectionColor:(NSData *)var
{
    if(selectionColor != var)
    {
        [selectionColor release];
        selectionColor = [var copy];
    }
}

- (NSData*)selectionColor
{
    return selectionColor;
}

#pragma mark -
#pragma mark UI management

- (IBAction)fileChoose:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection: NO];
    [openPanel setCanChooseFiles: YES];
    [openPanel beginSheetForDirectory: @"/var/log/"
                                 file: @"system.log"
                                types: nil
                       modalForWindow: [[self mainView] window]
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
    /*
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
     */
}

#pragma mark -
#pragma mark Daemon interaction
- (void)didSelect
{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName: @"GTPrefsLaunched"
                                                                   object: @"GeekToolPrefs"
                                                                 userInfo: nil
                                                       deliverImmediately: YES];
    
}

- (void)didUnselect
{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName: @"GTPrefsQuit"
                                                                   object: @"GeekToolPrefs"
                                                                 userInfo: nil
                                                       deliverImmediately: YES];
    [[[NSFontManager sharedFontManager] fontPanel: NO] close];
}

- (void)geekToolLaunched:(NSNotification*)aNotification
{
    /*
     [gEnable setState: YES];
     */
     [self notifyHighlight];

}

#pragma mark Saving
- (NSString *)pathForDataFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *folder = @"~/Library/Application Support/NerdTool/";
    folder = [folder stringByExpandingTildeInPath];
    
    if ([fileManager fileExistsAtPath:folder] == NO)
    {
        [fileManager createDirectoryAtPath:folder attributes:nil];
    }
    
    NSString *fileName = @"LogData.ntdata";
    return [folder stringByAppendingPathComponent:fileName];    
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
    NSDictionary *rootObject;
    
    rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    NSArray *groupArray = [rootObject valueForKey:@"groups"];
    
    if (!groupArray)
    {
        [groupArray release];
        NTGroup *defaultGroup = [[NTGroup alloc]init];
        groupArray = [NSArray arrayWithObject:defaultGroup];
    }

    [self setGroups:groupArray];
}

- (void)loadPreferences
{
    // load selection color data
    NSData *selectionColorData = [[NSUserDefaults standardUserDefaults] objectForKey: @"selectionColor"];
    if (!selectionColorData) selectionColorData = [NSArchiver archivedDataWithRootObject:[[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.3]];
    [self setSelectionColor:selectionColorData];
    
    NSString *activeGroup = [[NSUserDefaults standardUserDefaults] objectForKey:@"activeGroup"];
    if (activeGroup)
    {
        NSMutableArray *groupsList = [NSMutableArray array];
        NSEnumerator *e = [groups objectEnumerator];
        NTGroup *tmp = nil;
        while (tmp = [e nextObject]) [groupsList addObject:
                                      [[tmp properties] objectForKey:@"name"]];
        
        if (![groupsList containsObject:activeGroup]) activeGroup = nil;
    }
    if (!activeGroup) activeGroup = [[[groups lastObject] properties] objectForKey:@"name"];
    [[NSUserDefaults standardUserDefaults] setObject:activeGroup forKey:@"activeGroup"];
    
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
