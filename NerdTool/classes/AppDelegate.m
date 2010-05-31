/*
 * AppDelegate.m
 * NerdTool
 * Created by Kevin Nygaard on 3/18/09.
 * Copyright 2009 AllocInit. All rights reserved.
 *
 * Original file name: GeekToolPrefs.m
 * Based on code by Yann Bizeul from Thu Nov 21 2002.
 *
 * This file is part of NerdTool.
 * 
 * NerdTool is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * NerdTool is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with NerdTool.  If not, see <http://www.gnu.org/licenses/>.
 */


#import "AppDelegate.h"
#import "defines.h"

// CD to add new items
#import "NTGroup.h"
#import "NTLog.h"
#import "NSTreeController_Extensions.h"

// log import
#ifdef ENABLE_GEEKTOOL_2_IMPORTS
#import "NTShell.h"
#import "NTFile.h"
#import "NTImage.h"
#import "NTUtility.h"
#endif // ENABLE_GEEKTOOL_2_IMPORTS

// expose border
#import "NTExposeBorder.h"
#import "NSWindow+StickyWindow.h"

// drag n drop
#import "NSTreeNode_Extensions.h"

NSString *NTTreeNodeType = @"NTTreeNodeType";

#pragma mark Category Interfaces
@interface AppDelegate (ExposeBorder)
- (void)exposeBorder:(BOOL)activate;
@end

@interface AppDelegate (LoginItemManagement)
- (void)addLoginItem:(NSString*)path;
- (void)removeLoginItem:(NSString*)path;
- (BOOL)isLoginItem:(NSString*)path;
@end

#pragma mark  
@implementation AppDelegate

- (id)init
{
    // initialize variables we will need
    if (self = [super init])
    {        
        exposeBorderWindowArray = [[NSMutableArray alloc]init];
        windowControllerArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)awakeFromNib
{
    [self loadPreferences];
    
    // TODO: uncomment to register for wake notifications
    // register for wake notifications
    //[[[NSWorkspace sharedWorkspace]notificationCenter]addObserver:self selector:@selector(receiveWakeNote) name: NSWorkspaceDidWakeNotification object:NULL];
    
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
    [outlineView registerForDraggedTypes:[NSArray arrayWithObject:NTTreeNodeType]];
}

- (void)receiveWakeNote
{
    // TODO: refresh everything on wake
    //[groupController observeValueForKeyPath:@"selectedObjects" ofObject:nil change:nil context:nil];
}

#pragma mark -
#pragma mark NerdToolRO
// TODO: fix up all of RO
- (IBAction)refreshGroupSelection:(id)sender
{
    // TODO update
    //[groupController observeValueForKeyPath:@"selectedObjects" ofObject:nil change:nil context:nil];
}

- (IBAction)trackROProcess:(id)sender
{
    // see if RO process is running (and kill it if it is)
    // returns 0 if not running
    // returns 1 if it is running (or more accurately, was running)
    NSString *resourcePath = [[NSBundle mainBundle]resourcePath];
    NSString *shellCommand = [resourcePath stringByAppendingPathComponent:@"killROProcess.sh"];
    NSTask *task = [[NSTask alloc]init];
    [task setLaunchPath:@"/bin/sh"];
    // needed to keep xcode's console working
    [task setStandardInput:[NSPipe pipe]];
    [task setArguments:[NSArray arrayWithObjects:shellCommand,@"-k",nil]];
    [task launch];
    [task waitUntilExit];    
    [task release];
}

#pragma mark IBActions: CoreData Actions
- (IBAction)newLeaf:(id)sender
{
    // TODO: put in code to select different types of logs to add
	NTLog *leafNode = [NSEntityDescription insertNewObjectForEntityForName:@"ShellLog" inManagedObjectContext:[self managedObjectContext]];
	static NSUInteger count = 0;
	leafNode.name = [NSString stringWithFormat:@"Log %i",++count];
	[treeController insertObject:leafNode atArrangedObjectIndexPath:[treeController indexPathForInsertion]];
}

- (IBAction)newGroup:(id)sender
{
	NTGroup *groupNode = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:[self managedObjectContext]];
	static NSUInteger count = 0;
	groupNode.name = [NSString stringWithFormat:@"Group %i",++count];
	[treeController insertObject:groupNode atArrangedObjectIndexPath:[treeController indexPathForInsertion]];	
}

#pragma mark IBActions: Preference Actions
- (IBAction)addAsLoginItem:(id)sender
{
    NSString *roPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"NerdToolRO.app"];
    if (![sender state]) [self removeLoginItem:roPath];
    else [self addLoginItem:roPath];
}

- (IBAction)logImport:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:YES];
    
    NSString *prefsDirectory = [[NSSearchPathForDirectoriesInDomains(NSAllLibrariesDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"Preferences"];
    
    [openPanel beginSheetForDirectory:prefsDirectory file:@"org.tynsoe.geektool.plist" types:nil modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)revertDefaultSelectionColor:(id)sender
{
    NSData *selectionColorData = [NSArchiver archivedDataWithRootObject:kDefaultSelectionColor];
    [[NSUserDefaults standardUserDefaults]setObject:selectionColorData forKey:@"selectionColor"];    
}

- (IBAction)showExpose:(id)sender
{
    [self exposeBorder:[[NSUserDefaults standardUserDefaults] boolForKey:@"expose"]];
}

- (IBAction)donate:(id)sender
{
	[[NSWorkspace sharedWorkspace]openURL:[NSURL URLWithString:DONATE_URL]];
}

- (IBAction)openReadme:(id)sender
{
    [[NSWorkspace sharedWorkspace]openFile:[[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:@"readme.txt"]];        
}

#pragma mark Saving

- (void)loadPreferences
{
    NSData *selectionColorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"selectionColor"];
    if (!selectionColorData) selectionColorData = [NSArchiver archivedDataWithRootObject:kDefaultSelectionColor];
    [[NSUserDefaults standardUserDefaults] setObject:selectionColorData forKey:@"selectionColor"];
    
    NSData *defaultFgColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultFgColor"];
    if (!defaultFgColor) defaultFgColor = [NSArchiver archivedDataWithRootObject:kDefaultFgColor];
    [[NSUserDefaults standardUserDefaults] setObject:defaultFgColor forKey:@"defaultFgColor"];    
    
    NSData *defaultBgColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultBgColor"];
    if (!defaultBgColor) defaultBgColor = [NSArchiver archivedDataWithRootObject:kDefaultBgColor];
    [[NSUserDefaults standardUserDefaults] setObject:defaultBgColor forKey:@"defaultBgColor"];    
    
    [self showExpose:nil];
    [self trackROProcess:nil];
    
    // is it a startup item?
    [loginItem setState:[self isLoginItem:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"NerdToolRO.app"]]];
}

#pragma mark Core Data Boilerplate
/*
 Returns the support folder for the application, used to store the Core Data
 store file.  This code uses a folder named "AbstractTree" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */
- (NSString *)applicationSupportFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] :NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:CORE_DATA_STORE_FILE];
}

/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel == nil) {
        managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    }
    return managedObjectModel;
}

/*
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The folder for the store is created, 
 if necessary.)
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator == nil) {
        NSFileManager *fileManager;
        NSString *applicationSupportFolder = nil;
        NSURL *url;
        NSError *error;
        
        fileManager = [NSFileManager defaultManager];
        applicationSupportFolder = [self applicationSupportFolder];
        if (![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL]) {
            [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
        }
        
        url = [NSURL fileURLWithPath:[applicationSupportFolder stringByAppendingPathComponent:[[NSString stringWithString:CORE_DATA_STORE_FILE] stringByAppendingString:@".xml"]]];
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
            [[NSApplication sharedApplication] presentError:error];
        }    
    }
    return persistentStoreCoordinator;
}


/*
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext == nil) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil) {
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            [managedObjectContext setPersistentStoreCoordinator:coordinator];
        }
    }
    return managedObjectContext;
}


/*
 Returns the NSUndoManager for the application.  In this case, the manager
 returned is that of the managed object context for the application.
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/*
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */
- (IBAction)saveAction:(id)sender {
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

#pragma mark Application Management
- (void)windowWillClose:(NSNotification *)notification
{
    // TODO: change this
    //if ([logController content]) [logController setSelectedObjects:nil];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    if (![mainConfigWindow isVisible]) [mainConfigWindow makeKeyAndOrderFront:nil];
    return NO;
}

// if the resolution is changed, reload the active group
- (void)applicationDidChangeScreenParameters:(NSNotification *)aNotification
{
    // TODO: update
    //[groupController observeValueForKeyPath:@"selectedObjects" ofObject:nil change:nil context:nil];
}

/*
 Implementation of the applicationShouldTerminate:method, used here to
 handle the saving of changes in the application managed object context
 before the application terminates.
 */
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    NSError *error;
    int reply = NSTerminateNow;
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.
                
                // Typically, this process should be altered to include application-specific 
                // recovery steps.  
                
                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } else {
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } else {
            reply = NSTerminateCancel;
        }
    }
    
    // TODO: we just want to get rid of logs that could still be running (like tail -F). The controller holds a lot of retains, and we have one.
    //[groupController release];
    
    // do we want to run the RO process before we leave?
    if (![[NSUserDefaults standardUserDefaults]integerForKey:@"enableNerdtool"]) return reply;
    NSString *resourcePath = [[NSBundle mainBundle]resourcePath];
    NSString *ROPath = [resourcePath stringByAppendingPathComponent:@"NerdToolRO.app"];
    [[NSWorkspace sharedWorkspace]launchApplication:ROPath];        
    
    return reply;
}

#pragma mark Misc
// used so we can keep our tree in order
- (NSArray *)treeNodeSortDescriptors
{
	return [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES] autorelease]];
}

/*
 Implementation of dealloc, to release the retained variables.
 This does not need to be a separate function, as when this variable is deallocated, the rest of the program will be soon
 */ 
- (void)dealloc
{
    [exposeBorderWindowArray release], exposeBorderWindowArray = nil;
    [windowControllerArray release], windowControllerArray = nil;
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    [super dealloc];
}

@end

#pragma mark 

#ifdef ENABLE_GEEKTOOL_2_IMPORTS
@implementation AppDelegate (LogImport)

// TODO: all of this should be rewritten to import things into CD
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
@end
#endif // ENABLE_GEEKTOOL_2_IMPORTS

@implementation AppDelegate (ExposeBorder)

- (void)exposeBorder:(BOOL)activate
{
    [exposeBorderWindowArray removeAllObjects];
    [windowControllerArray removeAllObjects];
    if (!activate) return;
    
    NSMutableArray *screens = [NSMutableArray arrayWithArray:[NSScreen screens]];
    
    for (int i = 0; i < [screens count]; i++)
    {
        NSRect visibleFrame = [[screens objectAtIndex:i] frame];
        
        if (i == 0) visibleFrame.size.height -= [NSMenuView menuBarHeight];
        
        NSWindow *exposeBorderWindow = [[NSWindow alloc]initWithContentRect:visibleFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[screens objectAtIndex:0]];
        [exposeBorderWindow setDelegate:self];
        [exposeBorderWindow setOpaque:NO];
        [exposeBorderWindow setLevel:kCGDesktopWindowLevel];
        [exposeBorderWindow setBackgroundColor:[NSColor clearColor]];
        [exposeBorderWindow setSticky:YES];
        
        NTExposeBorder *view = [[NTExposeBorder alloc] initWithFrame:visibleFrame];
        [exposeBorderWindow setContentView:view];
        [view setNeedsDisplay:YES];
        [view release];
        
        NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:exposeBorderWindow];
        [windowController setWindow:exposeBorderWindow];
        [windowController showWindow:self];
        
        [exposeBorderWindowArray addObject:exposeBorderWindow];
        [windowControllerArray addObject:windowController];
        
        [exposeBorderWindow release];
        [windowController release];
    }    
}

@end

@implementation AppDelegate (LoginItemManagement)

- (void)addLoginItem:(NSString*)path
{
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems,NULL);
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    
    LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,kLSSharedFileListItemLast,NULL,NULL,url,NULL,NULL);		
    if (item) CFRelease(item);    
}

- (void)removeLoginItem:(NSString*)path
{
    UInt32 seedValue;
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems,NULL);
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    
    NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
    for (id item in loginItemsArray)
    {		
        if (LSSharedFileListItemResolve((LSSharedFileListItemRef)item,0,(CFURLRef*)&url,NULL) == noErr && [[(NSURL *)url path] hasPrefix:path])
            LSSharedFileListItemRemove(loginItems,(LSSharedFileListItemRef)item); // Remove startup item
    }
    
    [loginItemsArray release];            
}

- (BOOL)isLoginItem:(NSString*)path
{
    UInt32 seedValue;
    BOOL isLoginItem = NO;
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems,NULL);
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    
    NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
    for (id item in loginItemsArray)
    {		
        if (LSSharedFileListItemResolve((LSSharedFileListItemRef)item,0,(CFURLRef*)&url,NULL) == noErr && [[(NSURL *)url path] hasPrefix:path])
            isLoginItem = YES;
    }
    
    [loginItemsArray release];
    return isLoginItem;
}
@end

@implementation AppDelegate (NSOutlineViewDragAndDrop)
- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteBoard
{
	[pasteBoard declareTypes:[NSArray arrayWithObject:NTTreeNodeType] owner:self];
	[pasteBoard setData:[NSKeyedArchiver archivedDataWithRootObject:[items valueForKey:@"indexPath"]] forType:NTTreeNodeType];
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)proposedParentItem proposedChildIndex:(NSInteger)proposedChildIndex
{
	if (proposedChildIndex == -1) // will be -1 if the mouse is hovering over a leaf node
		return NSDragOperationNone;
    
	NSArray *draggedIndexPaths = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:NTTreeNodeType]];
	BOOL targetIsValid = YES;
	for (NSIndexPath *indexPath in draggedIndexPaths) {
		NSTreeNode *node = [treeController nodeAtIndexPath:indexPath];
		if (!node.isLeaf) {
			if ([proposedParentItem isDescendantOfNode:node] || proposedParentItem == node) { // can't drop a group on one of its descendants
				targetIsValid = NO;
				break;
			}
		}
	}
	return targetIsValid ? NSDragOperationMove : NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)proposedParentItem childIndex:(NSInteger)proposedChildIndex
{
	NSArray *droppedIndexPaths = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:NTTreeNodeType]];
	
	NSMutableArray *draggedNodes = [NSMutableArray array];
	for (NSIndexPath *indexPath in droppedIndexPaths)
		[draggedNodes addObject:[treeController nodeAtIndexPath:indexPath]];
	
	NSIndexPath *proposedParentIndexPath;
	if (!proposedParentItem)
		proposedParentIndexPath = [[[NSIndexPath alloc] init] autorelease]; // makes a NSIndexPath with length == 0
	else
		proposedParentIndexPath = [proposedParentItem indexPath];
    
	[treeController moveNodes:draggedNodes toIndexPath:[proposedParentIndexPath indexPathByAddingIndex:proposedChildIndex]];
	return YES;
}

@end

@implementation AppDelegate (NSOutlineViewDelegate)
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	if ([[(NTTreeNode *)[item representedObject] isLeaf] boolValue] || [(NSTreeNode *)item isLeaf])
		return NO;
	return [[[item representedObject] isSpecialGroup] boolValue];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item
{
	if ([[(NTTreeNode *)[item representedObject] isLeaf] boolValue] || [(NSTreeNode *)item isLeaf])
		return NO;
	return [[[item representedObject] canCollapse] boolValue];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
	if ([[(NTTreeNode *)[item representedObject] isLeaf] boolValue] || [(NSTreeNode *)item isLeaf])
		return NO;
	return [[[item representedObject] canExpand] boolValue];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return [[(NTTreeNode *)[item representedObject] isSelectable] boolValue];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	NTGroup *collapsedItem = [[[notification userInfo] valueForKey:@"NSObject"] representedObject];
	collapsedItem.isExpanded = [NSNumber numberWithBool:NO];
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	NTGroup *expandedItem = [[[notification userInfo] valueForKey:@"NSObject"] representedObject];
	expandedItem.isExpanded = [NSNumber numberWithBool:YES];
}
@end