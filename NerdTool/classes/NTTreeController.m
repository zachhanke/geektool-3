/*
 * NTTreeController.m
 * NerdTool
 * Created by Kevin Nygaard on 5/22/10.
 * Copyright 2010 MutableCode. All rights reserved.
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

// TODO plug original developer

#import "NTTreeController.h"
#import "NSTreeController_Extensions.h"
#import "NSTreeNode_Extensions.h"
#import "NSIndexPath_Extensions.h"

#import "NTLog.h"
#import "NTTreeNode.h"


@interface NTTreeController (Observer)
@end

@interface NTTreeController(LogManipulation)
- (void)operateOnNTLogArray:(NSArray *)logItems withOptions:(NSLogOperator)options refLog:(NTLog *)refLog direction:(NSWindowOrderingMode)direction;
- (void)moveNodeWindow:(NTLog *)node;
- (void)moveNodeWindow:(NTLog *)node usingRefLogs:(NSArray *)refLogs;
- (void)moveNodeWindows:(NSArray *)nodes;
@end

@interface NTTreeController (NodeProperties)
- (BOOL)_parentHierarchyEnabledForItem:(NTTreeNode *)item;
- (NTLog *)_findNextReferenceLogFor:(NTLog *)item direction:(NSWindowOrderingMode*)direction usingRefLogs:(NSArray *)refLogs;
- (BOOL (^)(id obj, NSUInteger idx, BOOL *stop))_blockTestingForRefLog;
@end

@interface NTTreeController (TreeAccessors)
- (NSArray *)_allEnabledLogs;
- (NSArray *)_leafDescendantRepObjsForGroup:(NTGroup *)group;
- (NSArray *)_enabledDescendantLogsForGroup:(NTGroup *)group;
- (NSArray *)_enabledLeafDescendantRepObjsForNodes:(NSArray *)nodes;
@end


@implementation NTTreeController

@synthesize previousSelectedLogs;

#pragma mark Content Modifiers
- (void)insertObject:(id)object atArrangedObjectIndexPath:(NSIndexPath *)indexPath;
{
	[super insertObject:object atArrangedObjectIndexPath:indexPath];
	[self _updateSortOrderOfModelObjects];
}

- (void)insertObjects:(NSArray *)objects atArrangedObjectIndexPaths:(NSArray *)indexPaths;
{
	[super insertObjects:objects atArrangedObjectIndexPaths:indexPaths];
	[self _updateSortOrderOfModelObjects];
}

- (void)removeObjectAtArrangedObjectIndexPath:(NSIndexPath *)indexPath;
{
	[super removeObjectAtArrangedObjectIndexPath:indexPath];
	[self _updateSortOrderOfModelObjects];
}

- (void)removeObjectsAtArrangedObjectIndexPaths:(NSArray *)indexPaths;
{
	[super removeObjectsAtArrangedObjectIndexPaths:indexPaths];
	[self _updateSortOrderOfModelObjects];
}

- (void)moveNode:(NSTreeNode *)node toIndexPath:(NSIndexPath *)indexPath;
{
	[super moveNode:node toIndexPath:indexPath];
	[self _updateSortOrderOfModelObjects];	
}

- (void)moveNodes:(NSArray *)nodes toIndexPath:(NSIndexPath *)indexPath;
{
	[super moveNodes:nodes toIndexPath:indexPath];
    [self _updateSortOrderOfModelObjects];
    
    NSArray *enabledArray = [self _enabledLeafDescendantRepObjsForNodes:nodes];
    NSArray *allArray = [self _leafDescendantRepObjsForNodes:nodes];
    
    [self createAndDestroyLogsIfNecessary:allArray];
    [self moveNodeWindows:enabledArray];
}

- (void)createAndDestroyLogsIfNecessary:(NSArray *)nodes
{
    for (NTLog *node in nodes)
    {
        if (![self _parentHierarchyEnabledForItem:node]) [node destroyLogProcess];
        else if ([node.enabled boolValue])
        {
            if (![node createLogProcess]) break;
            [node updateWindowIncludingTimer:YES];
        }
    }
}

- (void)_updateSortOrderOfModelObjects
{
	for (NSTreeNode *node in [self flattenedNodes])
		[[node representedObject] setValue:[NSNumber numberWithInt:[[node indexPath] lastIndex]] forKey:@"sortIndex"];
}

@end

@implementation NTTreeController (Observer)

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];
    [self addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"enabled" options:0 context:nil];
}

- (void)fullReorder
{
    [self operateOnNTLogArray:[self _allEnabledLogs] withOptions:NTLogOperatorReorderLogs refLog:nil direction:NSWindowAbove];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // when a selection is changed
    if([keyPath isEqualToString:@"selectedObjects"])
    {   
        // TODO: GCD Blocking canidate
        // clear prefsView
        [[prefsView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        // TODO: GCD Blocking canidate
        // unselect our previous items
        for (NTLog *previousSelectedLog in previousSelectedLogs)
        {
            [previousSelectedLog setHighlighted:NO from:self];
            [previousSelectedLog removePreferenceObservers];
            [[previousSelectedLog unloadPrefsViewAndUnbind] removeFromSuperview];
        }
        
        // we are done with this. nil it out now in case we exit early
        self.previousSelectedLogs = nil;
        
        // handle the case where we have nothing selected
        if (![[object selectedObjects] count])
        {
            [defaultPrefsViewText setStringValue:@"No Selection"];
            [prefsView addSubview:defaultPrefsView];
            return;
        }        
        
        // TODO: GCD Blocking canidate
        // perhaps use -indexOfObjectPassingTest:. We only need to find one outlier to quit this loop
        id firstItem = [[object selectedObjects] objectAtIndex:0];
        for (id item in [object selectedObjects])
        {
            // have we selected a group?
            if ([item isKindOfClass:[NTGroup class]])
            {
                [defaultPrefsViewText setStringValue:@"Group selected"];
                [prefsView addSubview:defaultPrefsView];
                return;
            }
            
            // can the selected items share the preference view?
            if (![firstItem isKindOfClass:[item class]])
            {
                [defaultPrefsViewText setStringValue:@"Multiple Values"];
                [prefsView addSubview:defaultPrefsView];
                return;
            }
        }
        
        // TODO: GCD Blocking canidate
        // We are guaranteed that these are all similar NTLogs
        self.previousSelectedLogs = [object selectedObjects];
        for (NTLog *selectedLog in previousSelectedLogs)
        {
            [selectedLog setHighlighted:YES from:self];
            [selectedLog setupPreferenceObservers];
        }
        [prefsView addSubview:[firstItem loadPrefsViewAndBind:object]];
    }
    // when we add/remove/rearrange an item
    
    else if([keyPath isEqualToString:@"arrangedObjects"])
    {
        static BOOL once = FALSE;
        if (once) return;
        once = TRUE;
        NSArray *enabledItems = [self _allEnabledLogs];                
        [self operateOnNTLogArray:enabledItems withOptions:(NTLogOperatorCreateLogs | NTLogOperatorReorderLogs) refLog:nil direction:NSWindowAbove];
    }
    // when something is enabled/disabled
    else if([keyPath isEqualToString:@"enabled"])
    {
        BOOL groupSelected = ([object isKindOfClass:[NTGroup class]]) ? YES : NO;
        BOOL currentEnabledState = [[object valueForKey:@"enabled"] boolValue];
        NSWindowOrderingMode direction = NSWindowAbove;
        /*
         * Group?    Enabled?    Action
         *   NO         NO       If parent hierarchy is enabled, kill Log process (no other info needed)
         *   NO         YES      If parent hierarchy is enabled, create Log process (need next enabled Log above, if it exists)
         *   YES        NO       If parent hierarchy is enabled, kill all enabled members of group (no other info needed)
         *   YES        YES      If parent hierarchy is enabled, create all enabled members of group (need next enabled Log above, if it exists)
         */
        
        if (currentEnabledState && ![self _parentHierarchyEnabledForItem:object]) return; // bail early if our hierarchy isn't enabled
        
        NSArray *logs = nil;
        if (groupSelected) logs = (currentEnabledState) ? [self _enabledDescendantLogsForGroup:object] : [self _leafDescendantRepObjsForGroup:object];
        else logs = [NSArray arrayWithObject:object];
                
        // if we have we are operating on a selected item, we should highlight it too
        NSLogOperator highlight = ([[self selectedObjects] containsObject:object] && !groupSelected) ? NTLogOperatorHighlightLogs : NTLogOperatorNothing;
        [self operateOnNTLogArray:logs withOptions:(currentEnabledState) ? (NTLogOperatorCreateLogs | highlight) : NTLogOperatorDestroyLogs refLog:nil direction:direction];
        
        if (currentEnabledState) [self moveNodeWindows:logs];
    }
    else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}
@end


@implementation NTTreeController(LogManipulation)

// TODO: GCD Blocking canidate
// Be careful; there are relationships between the elements of the array. If anything, the logs can be created/destroyed in parallel, but need to be reordered serially.
- (void)operateOnNTLogArray:(NSArray *)logItems withOptions:(NSLogOperator)options refLog:(NTLog *)refLog direction:(NSWindowOrderingMode)direction
{
    NSEnumerator *e = [logItems reverseObjectEnumerator];
    for (NTLog *log in e)
    {
        if (NTLogOperatorCreateLogs & options)
        {
            if (![log createLogProcess]) break;
            [log updateWindowIncludingTimer:YES];
        }
        if (NTLogOperatorDestroyLogs & options) [log destroyLogProcess];
        if ((NTLogOperatorHighlightLogs | NTLogOperatorUnhighlightLogs) & options) [log setHighlighted:(NTLogOperatorHighlightLogs & options) from:self];
    }
}

- (void)moveNodeWindow:(NTLog *)node
{
    if (!node || ![node.enabled boolValue]) return;
    
    // since we are only moving one node, we can use all the logs for reference
    [self moveNodeWindow:node usingRefLogs:[self _allEnabledLogs]];
}

- (void)moveNodeWindow:(NTLog *)node usingRefLogs:(NSArray *)refLogs
{
    if (!node || ![node.enabled boolValue]) return;
    
    NTLog *refLog = nil;
    NSWindowOrderingMode direction = NSWindowAbove;
    
    refLog = [self _findNextReferenceLogFor:node direction:&direction usingRefLogs:refLogs];
    if (refLog) [[node window] orderWindow:direction relativeTo:[[refLog window] windowNumber]];
    else [node front];
}

- (void)moveNodeWindows:(NSArray *)nodes
{
    if (!nodes) return;
    
    // find all canidates
    NSArray *allLogs = [self _allEnabledLogs];
    NSMutableArray *refLogs = [NSMutableArray array];
    NSMutableArray *nodesToKeep = [NSMutableArray array];
    NSMutableArray *nodesToDelete = [NSMutableArray array];
    
    NSEnumerator *e = [nodes reverseObjectEnumerator];
    for (NTLog *node in e)
    {
        if (![node.enabled boolValue]) continue;
        
        [refLogs setArray:allLogs]; // reset our refs
        [nodesToKeep addObject:node]; // every time we run through this loop, we gain another reference log to use
        
        [nodesToDelete setArray:nodes];
        [nodesToDelete removeObjectsInArray:nodesToKeep]; // protect the nodes we want to keep
        [refLogs removeObjectsInArray:nodesToDelete]; // kill the rest from our refs

        [self moveNodeWindow:node usingRefLogs:refLogs];
    }
}

@end


@implementation NTTreeController (NodeProperties)

// returns TRUE if all related parents to NTTreeNode `item' are enabled
- (BOOL)_parentHierarchyEnabledForItem:(NTTreeNode *)item
{
    // make sure all the parents of the selected object are enabled
    BOOL parentHierarchyEnabled = YES;
    while ((item = item.parent) && parentHierarchyEnabled) parentHierarchyEnabled = [item.enabled boolValue];
    return parentHierarchyEnabled;
}

// return the closest NTLog in `refLogs' to NTLog `item'. Direction is changed to the relative position of the returned NTLog to NTLog `item'
- (NTLog *)_findNextReferenceLogFor:(NTLog *)item direction:(NSWindowOrderingMode*)direction usingRefLogs:(NSArray *)refLogs
{    
    // find which part of the array is good for us to use
    int baseLogIndex = [refLogs indexOfObject:item];
    if (baseLogIndex == NSNotFound) return nil; // couldn't find the root object
    
    NSRange range;
    NSUInteger top = NSNotFound;
    NSUInteger bottom = NSNotFound;
    
    // look at top
    range.location = 0;
    range.length = baseLogIndex;
    NSIndexSet *topSet = [NSIndexSet indexSetWithIndexesInRange:range];
    top = [refLogs indexOfObjectAtIndexes:topSet options:NSEnumerationReverse passingTest:[self _blockTestingForRefLog]];
    
    if (direction) *direction = NSWindowBelow;
    if (top != NSNotFound) return [refLogs objectAtIndex:top];
    
    // look at bottom
    range.location = baseLogIndex + 1;
    range.length = (range.location < [refLogs count]) ? [refLogs count] - range.location : 0;
    NSIndexSet *bottomSet = [NSIndexSet indexSetWithIndexesInRange:range];
    bottom = [refLogs indexOfObjectAtIndexes:bottomSet options:NSEnumerationConcurrent passingTest:[self _blockTestingForRefLog]];
    
    if (direction) *direction = NSWindowAbove;
    if (bottom != NSNotFound) return [refLogs objectAtIndex:bottom];
    
    return nil;
}

// Block statement to test for a good reference log
- (BOOL (^)(id obj, NSUInteger idx, BOOL *stop))_blockTestingForRefLog
{
    return [[^(id obj, NSUInteger idx, BOOL *stop)
             {
                 // In order for a log to be a good reference by which another log can place its window, it must have a window active
                 if ([obj windowController])
                 {
                     *stop = YES;
                     return YES;
                 }
                 return NO;
             } copy] autorelease];
}

@end


@implementation NTTreeController (TreeAccessors)

// an array of all enabled NTLog objects (sorted)
- (NSArray *)_allEnabledLogs
{
    return [self _enabledLeafDescendantRepObjsForNodes:[self rootNodes]];
}

// a (sorted) array of all NTLog objects that descend from the NTGroup `group'
- (NSArray *)_leafDescendantRepObjsForGroup:(NTGroup *)group
{
    NSTreeNode *groupTreeNode = [self treeNodeForObject:group];
    return [[groupTreeNode leafDescendants] valueForKey:@"representedObject"];
}

// a (sorted) array of all enabled NTLog objects that descend from the NTGroup `group', provided that the parent hierarchy is also enabled
- (NSArray *)_enabledDescendantLogsForGroup:(NTGroup *)group
{
    if (![self _parentHierarchyEnabledForItem:group]) return nil; // bail early if our hierarchy isn't enabled
    
    NSTreeNode *groupTreeNode = [self treeNodeForObject:group];
    return [self _enabledLeafDescendantRepObjsForNodes:[NSArray arrayWithObject:groupTreeNode]];
}

// a (sorted) array of all enabled NTLog objects that descend from the array of NTTreeNode `nodes', provided that the parent hierarchy is also enabled
- (NSArray *)_enabledLeafDescendantRepObjsForNodes:(NSArray *)nodes
{
    NSMutableArray *array = [NSMutableArray array];
    NTTreeNode *repObj = nil;
    
	for (NSTreeNode *item in nodes)
    {
        repObj = [item representedObject];
        if (![[repObj valueForKey:@"enabled"] boolValue]) continue; // is the object enabled?
        if (![self _parentHierarchyEnabledForItem:repObj]) continue; // is the parent hierarchy of the object enabled?
        
		if ([item isLeaf]) [array addObject:repObj];
		else [array addObjectsFromArray:[self _enabledLeafDescendantRepObjsForNodes:[item childNodes]]];
	}
	return [[array copy] autorelease];    
}

- (NSArray *)_leafDescendantRepObjsForNodes:(NSArray *)nodes
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSTreeNode *item in nodes)
    {
		if ([item isLeaf]) [array addObject:[item representedObject]];
		else [array addObjectsFromArray:[self _leafDescendantRepObjsForNodes:[item childNodes]]];      
    }
    
    return [[array copy] autorelease];
}

@end

