//
//  LogController.m
//  GeektoolPreferencePane
//
//  Created by Kevin Nygaard on 3/18/09.
//  Copyright 2009 AllocInit. All rights reserved.
//

#import "LogController.h"
#import "GroupController.h"
#import "NTGroup.h"
#import "LogWindow.h"
#import "NTLog.h"
#import "NTShell.h"
#import "NTFile.h"
#import "NTImage.h"
#import "NTQuartz.h"
#import "NTWeb.h"

#import "defines.h"
#import "NSIndexSet+CountOfIndexesInRange.h"
#import "NSArrayController+Duplicate.h"

@implementation LogController

- (void)awakeFromNib
{
    _oldSelectedLog = nil;
    _userInsert = NO;
    
    MovedRowsType = @"NTLog_Moved_Item";
    CopiedRowsType = @"NTLog_Copied_Item";
    
    [tableView setDelegate:self];
	[tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
	[tableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:CopiedRowsType,MovedRowsType,NSFilenamesPboardType,NSURLPboardType,nil]];
    [tableView setAllowsMultipleSelection:YES];    
    
    [self addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];
    [self observeValueForKeyPath:@"selectedObjects" ofObject:self change:nil context:nil];
    [self setAvoidsEmptySelection:YES];
    [self setSelectsInsertedObjects:YES];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"selectedObjects"];
    [super dealloc];
}

#pragma mark UI
- (IBAction)displayLogTypeMenu:(id)sender
{    
    NSRect frame = [sender frame];    
    NSEvent *event = [NSEvent mouseEventWithType:NSLeftMouseDown location:[[sender superview]convertPoint:NSMakePoint(frame.origin.x,frame.origin.y) toView:nil] modifierFlags:0 timestamp:0 windowNumber:[[sender window]windowNumber] context:nil eventNumber:0 clickCount:1 pressure:0]; 
    [NSMenu popUpContextMenu:[sender menu] withEvent:event forView:sender];    
}

- (IBAction)displayLogGearMenu:(id)sender
{    
    NSRect frame = [sender frame];    
    NSEvent *event = [NSEvent mouseEventWithType:NSLeftMouseDown location:[[sender superview]convertPoint:NSMakePoint(frame.origin.x,frame.origin.y) toView:nil] modifierFlags:0 timestamp:0 windowNumber:[[sender window]windowNumber] context:nil eventNumber:0 clickCount:1 pressure:0]; 
    
    NSMenu *menu = [[NSMenu alloc]init]; 
    
    NSMenuItem *duplicateItem = [[NSMenuItem alloc]init];
    [duplicateItem setTitle:@"Duplicate"];
    [duplicateItem setTarget:self];
    [duplicateItem setAction:@selector(duplicate:)];
    [menu addItem:duplicateItem];
    
    NSMenuItem *exportItem = [[NSMenuItem alloc]init];
    [exportItem setTitle:@"Export"];
    [exportItem setTarget:self];
    [exportItem setAction:@selector(exportSelectedLogs:)];
    [menu addItem:exportItem];
    
    [NSMenu popUpContextMenu:menu withEvent:event forView:sender];    
    
    [menu release];
    [duplicateItem release];
    [exportItem release];
}

#pragma mark Exporting
- (IBAction)exportSelectedLogs:(id)sender
{
    if (![[self selectedObjects]count]) return;
    NSString *baseExportDir = [[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory,NSUserDomainMask,YES) objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ Exported Logs",[[NSProcessInfo processInfo]processName]]];
    [self exportLogs:[self selectedObjects] withRootDestination:baseExportDir];
}

- (NSArray*)exportLogs:(NSArray*)logs withRootDestination:(NSString*)rootPath
{
    if (!rootPath) return nil;
    if (![[NSFileManager defaultManager]fileExistsAtPath:rootPath]) [[NSFileManager defaultManager]createDirectoryAtPath:rootPath attributes:nil];
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:[logs count]];
    
    for (NTLog *log in logs)
    {
        NSMutableDictionary *rootObject = [NSMutableDictionary dictionaryWithCapacity:[logs count]];
        [rootObject setValue:log forKey:@"log"];
        NSString *name = [[log properties]valueForKey:@"name"];
        
        // prevent clobbering
        NSString *outputFile = [rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ntlog",name]];
        int x = 0;
        while ([[NSFileManager defaultManager]fileExistsAtPath:outputFile])
        {
            x++;
            outputFile = [rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %i.ntlog",name,x]];
        }        
        
        [returnArray addObject:outputFile];
        [NSKeyedArchiver archiveRootObject:rootObject toFile:outputFile];
    }
    return returnArray;
}

#pragma mark Importing
- (IBAction)importLogs:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setCanChooseFiles:YES];
    
    NSString *defExportPath = [[NSSearchPathForDirectoriesInDomains(NSDesktopDirectory,NSUserDomainMask,YES) objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ Exported Logs",[[NSProcessInfo processInfo]processName]]];
    
    [openPanel beginSheetForDirectory:defExportPath file:nil types:[NSArray arrayWithObject:@"ntlog"] modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)importLogAtPath:(NSString*)logPath toRow:(int)insertRow
{
    NSDictionary *rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:logPath];
    NTLog *importedLog = [rootObject objectForKey:@"log"];
    _userInsert = YES;
    [self insertObject:importedLog atArrangedObjectIndex:insertRow];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [NSApp endSheet:sheet];
    if (returnCode == NSOKButton)
    {
        if (![[sheet filenames]count]) return;
        for (NSString *path in [sheet filenames])
        {
            if (![[path pathExtension]isEqualToString:@"ntlog"]) continue;
            [self importLogAtPath:path toRow:([tableView selectedRow] > 0)?[tableView selectedRow]:0];
        }        
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn) [sheet close];
}

#pragma mark Content
- (IBAction)insertLog:(id)sender
{
    _userInsert = YES;
    
    int insertionIndex = 0;
    if ([[self selectedObjects]count] > 0) insertionIndex = [[self selectionIndexes]firstIndex];
        
    if ([[sender title]isEqualToString:@"Shell"]) [self insertObject:[[[NTShell alloc]init]autorelease] atArrangedObjectIndex:insertionIndex];
    else if ([[sender title]isEqualToString:@"File"]) [self insertObject:[[[NTFile alloc]init]autorelease] atArrangedObjectIndex:insertionIndex];
    else if ([[sender title]isEqualToString:@"Image"]) [self insertObject:[[[NTImage alloc]init]autorelease] atArrangedObjectIndex:insertionIndex];
    else if ([[sender title]isEqualToString:@"Quartz"]) [self insertObject:[[[NTQuartz alloc]init]autorelease] atArrangedObjectIndex:insertionIndex];
    else if ([[sender title]isEqualToString:@"Web"]) [self insertObject:[[[NTWeb alloc]init]autorelease] atArrangedObjectIndex:insertionIndex];
}

- (void)removeObjectsAtArrangedObjectIndexes:(NSIndexSet *)indexes
{
    [[_oldSelectedLog unloadPrefsViewAndUnbind]removeFromSuperview];
    _oldSelectedLog = nil;
    [super removeObjectsAtArrangedObjectIndexes:indexes];
}

- (IBAction)duplicate:(id)sender
{
    _userInsert = YES;
    [self duplicateSelection];
}

- (void)insertObject:(id)object atArrangedObjectIndex:(NSUInteger)index
{
    NTGroup *parentGroup = [[groupController selectedObjects]objectAtIndex:0];
    if (_userInsert)
    {
        [object setActive:[NSNumber numberWithBool:YES]];
        [object setParentGroup:parentGroup];
    }
    [super insertObject:object atArrangedObjectIndex:index];
    
    if (_userInsert) [tableView editColumn:1 row:[tableView selectedRow] withEvent:nil select:YES];
    
    [parentGroup reorder];
    _userInsert = NO;
}

- (void)insertObjects:(NSArray *)objects atArrangedObjectIndexes:(NSIndexSet *)indexes
{
    NTGroup *parentGroup = [[groupController selectedObjects]objectAtIndex:0];
    if (_userInsert)
    {
        [objects makeObjectsPerformSelector:@selector(setActive:) withObject:[NSNumber numberWithBool:YES]];
        [objects makeObjectsPerformSelector:@selector(setParentGroup:) withObject:parentGroup];
        _userInsert = NO;
    }
    [super insertObjects:objects atArrangedObjectIndexes:indexes];
    [parentGroup reorder];
}

#pragma mark Observing
// based on selection, highlight/dehighlight the log window
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // when a selection is changed
    if([keyPath isEqualToString:@"selectedObjects"])
    {
        if ([[defaultPrefsView superview]isEqualTo:prefsView]) [defaultPrefsView removeFromSuperview];
        
        if (_oldSelectedLog != nil)
        {
            [_oldSelectedLog setHighlighted:NO from:self];
            [[_oldSelectedLog unloadPrefsViewAndUnbind]removeFromSuperview];
        }
        
        if (![[self selectedObjects]count])
        {
            [defaultPrefsViewText setStringValue:@"No Selection"];
            [prefsView addSubview:defaultPrefsView];
            return;
        }
        else if ([[self selectedObjects]count] > 1)
        {
            BOOL useSameView = YES;
            for (NTLog *log in [self selectedObjects])
            {
                if (![[[[self selectedObjects]objectAtIndex:0]logTypeName]isEqualToString:[log logTypeName]])
                {
                    useSameView = NO;
                    break;
                }
            }
            
            if (!useSameView)
            {
                [defaultPrefsViewText setStringValue:@"Multiple Values"];
                [prefsView addSubview:defaultPrefsView];
                return;            
            }
        }
        
        _oldSelectedLog = [[self selectedObjects]objectAtIndex:0];
        [prefsView addSubview:[_oldSelectedLog loadPrefsViewAndBind:self]];
        [_oldSelectedLog setHighlighted:YES from:self];
    }
    else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}
#pragma mark Drag and Drop

// drag source
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    [pboard declareTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType,MovedRowsType,nil] owner:self];
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:MovedRowsType];
	
	// create new array of selected rows for remote drop. could do deferred provision, but keep it direct for clarity
	NSMutableArray *rowCopies = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
	
    unsigned int currentIndex = [rowIndexes firstIndex];
    while (currentIndex != NSNotFound)
    {
		[rowCopies addObject:[[self arrangedObjects]objectAtIndex:currentIndex]];
        currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
    }
	
	// setPropertyList works here because we're using dictionaries, strings, and dates; otherwise, archive collection to NSData...
    [pboard setPropertyList:[NSArray arrayWithObject:@"ntlog"] forType:NSFilesPromisePboardType];
	[pboard setPropertyList:rowCopies forType:CopiedRowsType];
	
    return YES;
}

- (NSArray *)tableView:(NSTableView *)aTableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet
{
    return [self exportLogs:[[self content]objectsAtIndexes:indexSet] withRootDestination:[dropDestination path]];
}

// drag destination
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    NSDragOperation dragOp = NSDragOperationCopy;
    
    if ([info draggingSource] == tableView) dragOp = NSDragOperationMove;
    
    // we want to put the object at, not over, the current row (contrast NSTableViewDropOn) 
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOp;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    BOOL result = NO;
    
    if (row < 0) row = 0;
    
	// if drag source is self, it's a move unless the Option key is pressed
    if ([info draggingSource] == tableView)
    {
        NSData *rowsData = [[info draggingPasteboard]dataForType:MovedRowsType];
        NSIndexSet *indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:rowsData];
        
        NSIndexSet *destinationIndexes = [self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
        // set selected rows to those that were just moved
        [self setSelectionIndexes:destinationIndexes];
        
        result = YES;
    }
    else if ([[[info draggingPasteboard]types]containsObject:NSFilenamesPboardType])
    {
        NSArray *files = [[info draggingPasteboard]propertyListForType:NSFilenamesPboardType];
        for (NSString *file in files)
        {   
            if (!file || [file isEqualToString:@""]) continue;
            NTLog *logToAdd = nil;
            if ([[file pathExtension]isEqualToString:@"ntlog"])
            {
                [self importLogAtPath:file toRow:row];
            }
            else if ([[file pathExtension]isEqualToString:@"qtz"])
            {
                logToAdd = [[NTQuartz alloc]init];
                [[logToAdd properties]setValue:file forKey:@"quartzFile"];
            }
            else if ([[NSArray arrayWithObjects:@"url",@"htm",@"html",nil]containsObject:[file pathExtension]])
            {
                logToAdd = [[NTWeb alloc]init];
                [[logToAdd properties]setValue:[[NSURL fileURLWithPath:file]absoluteString] forKey:@"webURL"];
            }
            else if ([[NSArray arrayWithObjects:@"txt",@"log",@"todo",nil]containsObject:[file pathExtension]])
            {
                logToAdd = [[NTFile alloc]init];
                [[logToAdd properties]setValue:file forKey:@"file"];
            }
            else if ([[NSArray arrayWithObjects:@"sh",@"pl",@"rb",@"py",nil]containsObject:[file pathExtension]])
            {
                logToAdd = [[NTShell alloc]init];
                [[logToAdd properties]setValue:file forKey:@"command"];
            }
            else if ([[NSImage imageFileTypes]containsObject:[file pathExtension]])
            {
                logToAdd = [[NTImage alloc]init];
                [[logToAdd properties]setValue:[[NSURL fileURLWithPath:file]absoluteString] forKey:@"imageURL"];
            }
            
            if (!logToAdd) continue;
            _userInsert = YES;
            [self insertObject:logToAdd atArrangedObjectIndex:row];
            [logToAdd release];
        }
        result = YES;
    }
    else if ([[[info draggingPasteboard]types]containsObject:NSURLPboardType])
    {
        NSArray *urls = [[info draggingPasteboard]propertyListForType:NSURLPboardType];
        for (NSString *url in urls)
        {
            if (!url || [url isEqualToString:@""]) continue;
            NTLog *logToAdd = [[NTWeb alloc]init];
            [[logToAdd properties]setValue:[[NSURL URLWithString:url]absoluteString] forKey:@"webURL"];
            
            _userInsert = YES;
            [self insertObject:logToAdd atArrangedObjectIndex:row];
            [logToAdd release];
        }
        
    }
    
    return result;
}

- (NSIndexSet *)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)fromIndexSet toIndex:(unsigned int)insertIndex
{	
	// If any of the removed objects come before the insertion index, we need to decrement the index appropriately
	unsigned int adjustedInsertIndex = insertIndex - [fromIndexSet countOfIndexesInRange:(NSRange){0, insertIndex}];
	NSRange destinationRange = NSMakeRange(adjustedInsertIndex, [fromIndexSet count]);
	NSIndexSet *destinationIndexes = [NSIndexSet indexSetWithIndexesInRange:destinationRange];
	
	NSArray *objectsToMove = [[self arrangedObjects] objectsAtIndexes:fromIndexSet];
	[self removeObjectsAtArrangedObjectIndexes:fromIndexSet];	
	[self insertObjects:objectsToMove atArrangedObjectIndexes:destinationIndexes];
	
	return destinationIndexes;
}

@end
