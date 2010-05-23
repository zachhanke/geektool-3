/*
 * GroupController.m
 * NerdTool
 * Created by Kevin Nygaard on 3/17/09.
 * Copyright 2009 AllocInit. All rights reserved.
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

#import "GroupController.h"
#import "NTGroup.h"

#import "NSArrayController+Duplicate.h"

@implementation GroupController

- (void)awakeFromNib
{        
    selectedGroup = nil;
    MovedRowsType = @"NTGroup_Moved_Item";
    CopiedRowsType = @"NTGroup_Copied_Item";

    // register for drag and drop
	[tableView setDraggingSourceOperationMask:NSDragOperationLink forLocal:NO];
	[tableView setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationMove) forLocal:YES];
	
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:CopiedRowsType, MovedRowsType, nil]];
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

#pragma mark Observing
// based on selection, set the group to be active/inactive
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"selectedObjects"])
    {
        [logController setSelectedObjects:nil];
        if (selectedGroup) [[selectedGroup properties]setValue:[NSNumber numberWithBool:NO] forKey:@"active"];
        
        if (![[self selectedObjects]count]) return;
        //if (selectedGroup == [[self selectedObjects]objectAtIndex:0]) return;
        
        selectedGroup = [[self selectedObjects]objectAtIndex:0];
        
        if (![[NSUserDefaults standardUserDefaults]integerForKey:@"enableNerdtool"]) return;
        [[selectedGroup properties]setValue:[NSNumber numberWithBool:YES] forKey:@"active"];
    }    
    
}

- (void)addObject:(id)object
{
    [super addObject:object];
    [tableView editColumn:0 row:[tableView selectedRow] withEvent:nil select:YES];
}

#pragma mark UI
- (IBAction)showGroupsCustomization:(id)sender
{
    [NSApp beginSheet:groupsSheet modalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)groupsSheetClose:(id)sender
{    
    [groupsSheet orderOut:self];
    [NSApp endSheet:groupsSheet];
}

#pragma mark Content Remove/Dupe
- (void)removeObjectsAtArrangedObjectIndexes:(NSIndexSet *)indexes
{
    selectedGroup = nil;
    [super removeObjectsAtArrangedObjectIndexes:indexes];
}

- (IBAction)duplicate:(id)sender
{
    [self duplicateSelection];
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
