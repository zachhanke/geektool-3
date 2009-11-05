//
//  GeekToolPrefPref.m
//  GeekToolPref
//
//  Created by Yann Bizeul on Thu Nov 21 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "GeekToolPrefs.h"
#import "NTExposeBorder.h"
#import "NTGroup.h"
#import "NTLog.h"
#import "NTShell.h"
#import "NTFile.h"
#import "NTImage.h"
#import "NTUtility.h"

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
        hitROProcess = NO;
    }
    return self;
}

- (void)awakeFromNib
{
    [self loadDataFromDisk];
    [self loadPreferences];
    
    // register for wake notifications
    [[[NSWorkspace sharedWorkspace]notificationCenter]addObserver:self selector:@selector(receiveWakeNote) name: NSWorkspaceDidWakeNotification object:NULL];
    
    [[NSColorPanel sharedColorPanel]setShowsAlpha:YES];
}

- (void)receiveWakeNote
{
    // refresh everything on wake
    [groupController observeValueForKeyPath:@"selectedObjects" ofObject:nil change:nil context:nil];
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    [self saveDataToDisk];
    
    // we just want to get rid of logs that could still be running (like tail -F). The controller holds a lot of retains, and we have one.
    [groupController release];
    self.groups = nil;
    
    if (!hitROProcess) return;
    NSString *resourcePath = [[NSBundle mainBundle]resourcePath];
    NSString *ROPath = [resourcePath stringByAppendingPathComponent:@"NerdToolRO.app"];
    [[NSWorkspace sharedWorkspace]launchApplication:ROPath];    
}  

- (void)windowWillClose:(NSNotification *)notification
{
    if ([logController content]) [logController setSelectedObjects:nil];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    if (![mainConfigWindow isVisible]) [mainConfigWindow makeKeyAndOrderFront:nil];
    return NO;
}

// if the resolution is changed, reload the active group
- (void)applicationDidChangeScreenParameters:(NSNotification *)aNotification
{
    [groupController observeValueForKeyPath:@"selectedObjects" ofObject:nil change:nil context:nil];
}

#pragma mark -
#pragma mark NerdToolRO
- (IBAction)trackROProcess:(id)sender
{
    NSString *resourcePath = [[NSBundle mainBundle]resourcePath];
    NSString *shellCommand = [resourcePath stringByAppendingPathComponent:@"killROProcess.sh"];
    NSTask *task = [[NSTask alloc]init];
    [task setLaunchPath:@"/bin/sh"];
    // needed to keep xcode's console working
    [task setStandardInput:[NSPipe pipe]];
    [task setArguments:[NSArray arrayWithObjects:shellCommand,@"-k",nil]];
    [task launch];
    [task waitUntilExit];
    
    if (!sender) [NTEnable setState:[task terminationStatus]];
    hitROProcess = [NTEnable state];
    
    [task release];
}

#pragma mark UI management
- (IBAction)addAsLoginItem:(id)sender
{
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems,NULL);
    NSString *roPath = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:@"NerdToolRO.app"];
    CFURLRef ROURL = (CFURLRef)[NSURL fileURLWithPath:roPath];
    
    if ([sender state])
    {
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,kLSSharedFileListItemLast,NULL,NULL,ROURL,NULL,NULL);		
        if (item) CFRelease(item);    
    }
    else
    {
        UInt32 seedValue;
        
        NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
        for (id item in loginItemsArray)
        {		
            if (LSSharedFileListItemResolve((LSSharedFileListItemRef)item,0,(CFURLRef*)&ROURL,NULL) == noErr && [[(NSURL *)ROURL path]hasPrefix:roPath])
                LSSharedFileListItemRemove(loginItems,(LSSharedFileListItemRef)item); // Remove startup item
        }
        
        [loginItemsArray release];        
    }
}

- (IBAction)revertDefaultSelectionColor:(id)sender
{
    NSData *selectionColorData = [NSArchiver archivedDataWithRootObject:[[NSColor alternateSelectedControlColor]colorWithAlphaComponent:0.3]];
    [[NSUserDefaults standardUserDefaults]setObject:selectionColorData forKey:@"selectionColor"];    
}

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

- (IBAction)donate:(id)sender
{
	[[NSWorkspace sharedWorkspace]openURL:[NSURL URLWithString:@"http://balthamos.darkraver.net/donate.php"]];
}

- (IBAction)openReadme:(id)sender
{
    [[NSWorkspace sharedWorkspace]openFile:[[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:@"readme.txt"]];        
}

#pragma mark Log Import
- (IBAction)logImport:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:YES];
    
    NSString *prefsDirectory = [[NSSearchPathForDirectoriesInDomains(NSAllLibrariesDirectory,NSUserDomainMask,YES) objectAtIndex:0]stringByAppendingPathComponent:@"Preferences"];
    
    [openPanel beginSheetForDirectory:prefsDirectory file:@"org.tynsoe.geektool.plist" types:nil modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [NSApp endSheet:sheet];
    if (returnCode == NSOKButton)
    {
        if (![[sheet filenames]count]) return;
        NSString *fileToOpen = [[sheet filenames]objectAtIndex:0];
        
        NTGroup *importedGroup = [[NTGroup alloc]init];
        [[importedGroup properties]setObject:@"Imported Logs" forKey:@"name"];
        
        NSArray *oldPreferences = [[NSMutableDictionary dictionaryWithContentsOfFile:fileToOpen]objectForKey:@"logs"];
        
        for (NSMutableDictionary *importDict in oldPreferences)
        {
            int type = [[importDict objectForKey:@"type"]intValue];
            // 0 : file
            // 1 : shell
            // 2 : image
            NTLog *newLog = nil;
            if (type == 0) newLog = [[NTFile alloc]init];
            else if (type == 1) newLog = [[NTShell alloc]init];
            else if (type == 2) newLog = [[NTImage alloc]init];            
                        
            [[newLog properties]setObject:[importDict objectForKey:@"name"] forKey:@"name"];
            [[newLog properties]setObject:[importDict objectForKey:@"enabled"] forKey:@"enabled"];
            
            [[newLog properties]setObject:[[importDict objectForKey:@"rect"]objectForKey:@"x"] forKey:@"x"];
            [[newLog properties]setObject:[[importDict objectForKey:@"rect"]objectForKey:@"y"] forKey:@"y"];
            [[newLog properties]setObject:[[importDict objectForKey:@"rect"]objectForKey:@"w"] forKey:@"w"];
            [[newLog properties]setObject:[[importDict objectForKey:@"rect"]objectForKey:@"h"] forKey:@"h"];            
            
            if (type == 0) [[newLog properties]setObject:[importDict objectForKey:@"file"] forKey:@"file"];
            else if (type == 1) [[newLog properties]setObject:[importDict objectForKey:@"command"] forKey:@"command"];
            else if (type == 2) [[newLog properties]setObject:[importDict objectForKey:@"imageURL"] forKey:@"imageURL"];
            
            if (type != 0) [[newLog properties]setObject:[importDict objectForKey:@"refresh"] forKey:@"refresh"];
            
            if (type != 2)
            {
                [[newLog properties]setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:[[[importDict objectForKey:@"backgroundColor"]objectForKey:@"red"]floatValue] green:[[[importDict objectForKey:@"backgroundColor"]objectForKey:@"green"]floatValue] blue:[[[importDict objectForKey:@"backgroundColor"]objectForKey:@"blue"]floatValue] alpha:[[[importDict objectForKey:@"backgroundColor"]objectForKey:@"alpha"]floatValue]]] forKey:@"backgroundColor"];
                [[newLog properties]setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:[[[importDict objectForKey:@"textColor"]objectForKey:@"red"]floatValue] green:[[[importDict objectForKey:@"textColor"]objectForKey:@"green"]floatValue] blue:[[[importDict objectForKey:@"textColor"]objectForKey:@"blue"]floatValue] alpha:[[[importDict objectForKey:@"textColor"]objectForKey:@"alpha"]floatValue]]] forKey:@"textColor"];
                [[newLog properties]setObject:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:[importDict objectForKey:@"fontName"] size:[[importDict objectForKey:@"fontSize"]floatValue]]] forKey:@"font"];
                [[newLog properties]setObject:[importDict objectForKey:@"shadowText"] forKey:@"shadowText"];
                [[newLog properties]setObject:[importDict objectForKey:@"shadowWindow"] forKey:@"shadowWindow"];
            }
            
            [[importedGroup logs]addObject:newLog];
            [newLog release];
        }
        [groupController addObject:importedGroup];
        [groupController setSelectedObjects:[NSArray arrayWithObject:importedGroup]];
        [importedGroup release];
    }
}
                
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn) [sheet close];
}

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
     
    NTGroup *groupToSelect = nil;
    
    if (![groupArray count])
    {
        NTGroup *defaultGroup = [[NTGroup alloc]init];
        [groupArray addObject:defaultGroup];
        groupToSelect = defaultGroup;
        
        [defaultGroup release];
    }
    
    for (NTGroup *tmp in groupArray)
        if ([[[tmp properties]objectForKey:@"active"]boolValue])
        {
            groupToSelect = tmp;
            break;
        }
    
    [self setGroups:[NSMutableArray arrayWithArray:groupArray]];
    [groupController setSelectedObjects:[NSArray arrayWithObject:groupToSelect?groupToSelect:[groupArray objectAtIndex:0]]];
}

- (void)loadPreferences
{
    NSData *selectionColorData = [[NSUserDefaults standardUserDefaults]objectForKey:@"selectionColor"];
    if (!selectionColorData) selectionColorData = [NSArchiver archivedDataWithRootObject:[[NSColor alternateSelectedControlColor]colorWithAlphaComponent:0.3]];
    [[NSUserDefaults standardUserDefaults]setObject:selectionColorData forKey:@"selectionColor"];
    
    NSData *defaultFgColor = [[NSUserDefaults standardUserDefaults]objectForKey:@"defaultFgColor"];
    if (!defaultFgColor) defaultFgColor = [NSArchiver archivedDataWithRootObject:[NSColor blackColor]];
    [[NSUserDefaults standardUserDefaults]setObject:defaultFgColor forKey:@"defaultFgColor"];    
    
    NSData *defaultBgColor = [[NSUserDefaults standardUserDefaults]objectForKey:@"defaultBgColor"];
    if (!defaultBgColor) defaultBgColor = [NSArchiver archivedDataWithRootObject:[NSColor clearColor]];
    [[NSUserDefaults standardUserDefaults]setObject:defaultBgColor forKey:@"defaultBgColor"];    
    
    [self showExpose:nil];
    [self trackROProcess:nil];
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems,NULL);
    NSString *roPath = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:@"NerdToolRO.app"];
    CFURLRef ROURL = (CFURLRef)[NSURL fileURLWithPath:roPath];    
    UInt32 seedValue;
    NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
    for (id item in loginItemsArray)
        if (LSSharedFileListItemResolve((LSSharedFileListItemRef)item,0,(CFURLRef*)&ROURL,NULL) == noErr && [[(NSURL *)ROURL path]hasPrefix:roPath])[loginItem setState:1];
    [loginItemsArray release];            
}

#pragma mark -
#pragma mark Misc
- (NSRect)screenRect:(NSRect)oldRect
{
    NSRect screenSize = [[[NSScreen screens]objectAtIndex:0]frame];
    int screenY = screenSize.size.height - oldRect.origin.y - oldRect.size.height;
    return NSMakeRect(oldRect.origin.x,screenY,oldRect.size.width,oldRect.size.height);
}

@end
