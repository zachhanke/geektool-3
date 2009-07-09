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
#import "LogWindow.h"
#import "NTExposeBorder.h"

#import "defines.h"
#import "CGSPrivate.h"

@implementation GeekToolPrefs

@synthesize groups;

- (id)init
{
    if (self = [super init])
    {
        groups = [[NSMutableArray alloc]init];
        exposeBorderWindowArray = [[NSMutableArray alloc]init];
        windowControllerArray = [[NSMutableArray alloc]init];
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
    [groups release];
    [exposeBorderWindowArray release];
    [windowControllerArray release];
    [super dealloc];
}

#pragma mark -
#pragma mark UI management
- (IBAction)showExpose:(id)sender
{
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"expose"]) [self exposeBorder];
    else 
    {
        [exposeBorderWindowArray removeAllObjects];
        [windowControllerArray removeAllObjects];
    }
}

- (void)exposeBorder
{
    if ([exposeBorderWindowArray count]) [exposeBorderWindowArray removeAllObjects];
    if ([windowControllerArray count]) [windowControllerArray removeAllObjects];
    
    NSMutableArray *screens = [NSMutableArray arrayWithArray:[NSScreen screens]];
    
    for (int i = 0; i < [screens count]; i++)
    {
        NSRect visibleFrame = [[screens objectAtIndex:i]frame];
        
        if (i == 0) visibleFrame.size.height -= [NSMenuView menuBarHeight];
        
        NSWindow *exposeBorderWindow = [[NSWindow alloc]initWithContentRect:visibleFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[screens objectAtIndex:0]];
        [exposeBorderWindow setDelegate:self];
        [exposeBorderWindow setOpaque:NO];
        [exposeBorderWindow setLevel:kCGDesktopWindowLevel];
        [exposeBorderWindow setBackgroundColor:[NSColor clearColor]];
        
        CGSWindow wid = [exposeBorderWindow windowNumber];
        CGSConnection cid = _CGSDefaultConnection();
        int tags[2] = {0,0};   
        
        if(!CGSGetWindowTags(cid,wid,tags,32))
        {
            tags[0] = tags[0] | 0x00000800;
            CGSSetWindowTags(cid,wid,tags,32);
        }    
        
        NTExposeBorder *view = [[NTExposeBorder alloc]initWithFrame:visibleFrame];
        [exposeBorderWindow setContentView:view];
        [view setNeedsDisplay:YES];
        [view release];
        
        NSWindowController *windowController = [[NSWindowController alloc]initWithWindow:exposeBorderWindow];
        [windowController setWindow:exposeBorderWindow];
        [windowController showWindow:self];
        
        [exposeBorderWindowArray addObject:exposeBorderWindow];
        [windowControllerArray addObject:windowController];
        
        [exposeBorderWindow release];
        [windowController release];
    }    
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
    NSMutableArray *groupArray = [NSMutableArray arrayWithArray:[rootObject valueForKey:@"groups"]];
        
    if (![groupArray count])
    {
        NTGroup *defaultGroup = [[NTGroup alloc]init];
        [groupArray addObject:defaultGroup];
    }

    [self setGroups:[NSMutableArray arrayWithArray:groupArray]];
    
    for (NTGroup *tmp in groupArray)
        if ([[[tmp properties]objectForKey:@"active"]boolValue])
        {
            [groupController setSelectedObjects:[NSArray arrayWithObject:tmp]];
            /*
            [groupArray removeObject:tmp];
            [groupArray insertObject:tmp atIndex:0];
             */
            break;
        }
    
    //[self setGroups:[NSMutableArray arrayWithArray:groupArray]];
}

- (void)loadPreferences
{
    NSData *selectionColorData = [[NSUserDefaults standardUserDefaults]objectForKey:@"selectionColor"];
    if (!selectionColorData) selectionColorData = [NSArchiver archivedDataWithRootObject:[[NSColor alternateSelectedControlColor]colorWithAlphaComponent:0.3]];
    [[NSUserDefaults standardUserDefaults]setObject:selectionColorData forKey:@"selectionColor"];
    
    [self showExpose:nil];
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
