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

    MovedRowsType = @"GTLog_Moved_Item";
    CopiedRowsType = @"GTLog_Copied_Item";

	[tableView setDraggingSourceOperationMask:NSDragOperationLink forLocal:NO];
	[tableView setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationMove) forLocal:YES];
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:CopiedRowsType,MovedRowsType,nil]];
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
    NSEvent *event = [NSEvent mouseEventWithType:NSLeftMouseDown location:[sender convertPoint:NSMakePoint(frame.origin.x,frame.origin.y + NSHeight(frame) + MENU_Y_OFFSET) toView:nil] modifierFlags:0 timestamp:0 windowNumber:[[sender window]windowNumber] context:nil eventNumber:0 clickCount:1 pressure:0]; 
    [NSMenu popUpContextMenu:[sender menu] withEvent:event forView:sender];    
}

#pragma mark Content Add/Dupe/Remove
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

#pragma mark Drag n' Drop Stuff
// thanks to mmalc for figuring most of this stuff out for me (and just being amazing)
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObjects:MovedRowsType,nil];
    
    [pboard declareTypes:typesArray owner:self];
	
    // add rows array for local move
	NSData *rowIndexesArchive = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard setData:rowIndexesArchive forType:MovedRowsType];
	
	// create new array of selected rows for remote drop could do deferred provision, but keep it direct for clarity
	NSMutableArray *rowCopies = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
	
    unsigned int currentIndex = [rowIndexes firstIndex];
    while (currentIndex != NSNotFound)
    {
		[rowCopies addObject:[[self arrangedObjects]objectAtIndex:currentIndex]];
        currentIndex = [rowIndexes indexGreaterThanIndex: currentIndex];
    }
	
	// setPropertyList works here because we're using dictionaries, strings, and dates; otherwise, archive collection to NSData...
	[pboard setPropertyList:rowCopies forType:CopiedRowsType];
	
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    NSDragOperation dragOp = NSDragOperationCopy;
    
    // if drag source is self, it's a move unless the Option key is pressed
    if ([info draggingSource] == tableView)
        dragOp = NSDragOperationMove;
    
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
