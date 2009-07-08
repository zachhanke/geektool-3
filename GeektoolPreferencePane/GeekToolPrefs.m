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
#import "LogWindow.h"
#import "NTExposeBorder.h"
#import "CGSPrivate.h"

@implementation GeekToolPrefs

@synthesize groups;

- (id)init
{
    if (self = [super init])
    {
        groups = [[NSMutableArray alloc]init];
        exposeBorder = nil;
        windowController = nil;
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

- (void)dealloc
{
    if (exposeBorder) [exposeBorder release];
    if (windowController) [windowController release];
    [super dealloc];
}


#pragma mark -
#pragma mark UI management
- (IBAction)showExpose:(id)sender
{
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"expose"]) [self exposeBorder];
    else
    {
        if (exposeBorder)
        {
            [exposeBorder release];
            exposeBorder = nil;
        }
        
        if (windowController)
        {
            [windowController release];
            windowController = nil;
        }
    }
}

- (void)exposeBorder
{
    if (!exposeBorder)
    {
        NSRect visibleFrame = [[NSScreen mainScreen]frame];
        visibleFrame.size.height -= MENU_BAR_HEIGHT;
        
        exposeBorder = [[NSWindow alloc]initWithContentRect:visibleFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[NSScreen mainScreen]];
        [exposeBorder setDelegate:self];
        [exposeBorder setOpaque:NO];
        [exposeBorder setLevel:kCGDesktopWindowLevel];
        [exposeBorder setBackgroundColor:[NSColor clearColor]];
        
        CGSWindow wid = [exposeBorder windowNumber];
        CGSConnection cid = _CGSDefaultConnection();
        int tags[2] = {0,0};   
        
        if(!CGSGetWindowTags(cid,wid,tags,32))
        {
            tags[0] = tags[0] | 0x00000800;
            CGSSetWindowTags(cid,wid,tags,32);
        }    
        
        NTExposeBorder *view = [[NTExposeBorder alloc]initWithFrame:visibleFrame];
        [exposeBorder setContentView:view];
        [view setNeedsDisplay:YES];
        [view release];
    }
    
    if (!windowController)
    {
        windowController = [[NSWindowController alloc]initWithWindow:exposeBorder];
        [windowController setWindow:exposeBorder];
    }
    
    [windowController showWindow:self];
}

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
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:appSupportDir] == NO)
        [[NSFileManager defaultManager]createDirectoryAtPath:appSupportDir attributes:nil];
    
    return [appSupportDir stringByAppendingPathComponent:@"LogData.ntdata"];    
}

- (void)saveDataToDisk
{
    NSString *path = [self pathForDataFile];
    
    NSMutableDictionary *rootObject = [NSMutableDictionary dictionary];
    
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
    
    // to protect group 'active' property
    [self setGroups:(NSMutableArray*)groupArray];
    
    BOOL activeGroupFound = NO;
    for (NTGroup *tmp in groups)
        if ([[[tmp properties] objectForKey:@"active"]boolValue])
        {
            [groupController setSelectedObjects:[NSArray arrayWithObject:tmp]];
            activeGroupFound = YES;
            break;
        }
    if (!activeGroupFound) [groupController setSelectedObjects:[NSArray arrayWithObject:[groups objectAtIndex:0]]];
    
    // update groupController in case it hasn't awoken yet
    [groupController observeValueForKeyPath:@"selectedObjects" ofObject:self change:nil context:nil];
}

- (void)loadPreferences
{
    NSData *selectionColorData = [[NSUserDefaults standardUserDefaults]objectForKey:@"selectionColor"];
    if (!selectionColorData) selectionColorData = [NSArchiver archivedDataWithRootObject:[[NSColor alternateSelectedControlColor]colorWithAlphaComponent:0.3]];
    [[NSUserDefaults standardUserDefaults]setObject:selectionColorData forKey:@"selectionColor"];
}

#pragma mark -
#pragma mark Misc
- (NSRect)screenRect:(NSRect)oldRect
{
    NSRect screenSize = [[NSScreen mainScreen]frame];
    int screenY = screenSize.size.height - oldRect.origin.y - oldRect.size.height;
    return NSMakeRect(oldRect.origin.x,screenY,oldRect.size.width,oldRect.size.height);
}

@end
