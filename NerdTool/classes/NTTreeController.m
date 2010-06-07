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

#define TREE_UP_DIRECTION 0
#define TREE_DOWN_DIRECTION 1

#import "NTTreeController.h"
#import "NSTreeController_Extensions.h"
#import "NSTreeNode_Extensions.h"
#import "NSIndexPath_Extensions.h"

#import "NTLog.h"
#import "NTTreeNode.h"


@interface NTTreeController (Observer)
- (NTLog *)_findNextReferenceLogFor:(NTTreeNode *)item direction:(NSWindowOrderingMode*)direction;
- (BOOL)_parentHierarchyEnabledForItem:(NTTreeNode *)item;
- (void)operateOnNTLogArray:(NSArray *)logItems withOptions:(NSLogOperator)options refLog:(NTLog *)refLog direction:(NSWindowOrderingMode)direction;
@end

@interface NTTreeController (Helper)
- (NSArray *)_enabledDescendantLogsForGroup:(NTGroup *)group;
- (NSArray *)_enabledLeafDescendantRepObjsForNode:(NSTreeNode *)node;
- (NSArray *)_allEnabledLogs;
@end


@implementation NTTreeController

@synthesize previousSelectedLogs;

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
    NSArray *array = [self _enabledLeafDescendantRepObjsForNodes:nodes];
	[super moveNodes:nodes toIndexPath:indexPath];
    [self _updateSortOrderOfModelObjects];
    [self moveNodeWindows:array];
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
    NSMutableArray *enabledItems = [NSMutableArray array];
    for (NSTreeNode *rootNode in [self rootNodes])
    {
        [enabledItems addObjectsFromArray:[self _enabledLeafDescendantRepObjsForNode:rootNode]];
    }
    
    [self operateOnNTLogArray:enabledItems withOptions:NTLogOperatorReorderLogs refLog:nil direction:NSWindowAbove];
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
        if (![self _parentHierarchyEnabledForItem:object]) return; // return if a parent hierarchy is not enabled
        NSArray *logs = (groupSelected) ? [self _enabledDescendantLogsForGroup:object] : [NSArray arrayWithObject:object];
        
        // make sure the guy above us has a window, otherwise he's worthless to us
        NTLog *refLog = [self _findNextReferenceLogFor:object direction:&direction usingRefLogs:[self _allEnabledLogs]];
        
        // if we have we are operating on a selected item, we should highlight it too
        NSLogOperator highlight = ([[self selectedObjects] containsObject:object] && !groupSelected) ? NTLogOperatorHighlightLogs : NTLogOperatorNothing;
        [self operateOnNTLogArray:logs withOptions:(currentEnabledState) ? (NTLogOperatorCreateLogs | NTLogOperatorReorderLogs | highlight) : NTLogOperatorDestroyLogs refLog:refLog direction:direction];
    }
    else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)moveNodeWindow:(NTTreeNode *)node usingRefLogs:(NSArray *)refLogs
{
    // We only need a refLog if we are inserting an object that will have a window
    NTLog *refLog = nil;
    NSWindowOrderingMode direction = NSWindowAbove;
    
    if (![self _parentHierarchyEnabledForItem:node]) return;
    
    refLog = [self _findNextReferenceLogFor:node direction:&direction usingRefLogs:refLogs];
    if (refLog) [[node window] orderWindow:direction relativeTo:[[refLog window] windowNumber]];
    else [node front];
}

- (void)moveNodeWindow:(NTTreeNode *)node
{
    // We only need a refLog if we are inserting an object that will have a window
    NTLog *refLog = nil;
    NSWindowOrderingMode direction = NSWindowAbove;
    NSArray *refLogs = [self _allEnabledLogs];
    
    if (![self _parentHierarchyEnabledForItem:node]) return;
    
    refLog = [self _findNextReferenceLogFor:node direction:&direction usingRefLogs:refLogs];
    if (refLog) [[node window] orderWindow:direction relativeTo:[[refLog window] windowNumber]];
    else [node front];
}

- (void)moveNodeWindows:(NSArray *)nodes
{
    // find all canidates
    NSMutableArray *allLogs = [[[self _allEnabledLogs] mutableCopy] autorelease]; // this array comes sorted
    
    NSEnumerator *e = [nodes reverseObjectEnumerator];
    for (NTTreeNode *node in e)
    {
        // don't reference logs that are being dragged (though, we must know where our new log resides, hence the removal of `node')
        NSMutableArray *refLogs = [[allLogs mutableCopy] autorelease];
        NSMutableArray *nodesToDelete = [[nodes mutableCopy] autorelease];
        [nodesToDelete removeObject:node];
        [refLogs removeObjectsInArray:nodesToDelete];

        [self moveNodeWindow:node usingRefLogs:refLogs];
    }
}

// Block statement to test for a good reference log
- (BOOL (^)(id obj, NSUInteger idx, BOOL *stop))blockTestingForRefLog
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

// returns nil if there isn't one
- (NTLog *)_findNextReferenceLogFor:(NTTreeNode *)item direction:(NSWindowOrderingMode*)direction usingRefLogs:(NSArray *)refLogs
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
    top = [refLogs indexOfObjectAtIndexes:topSet options:NSEnumerationReverse passingTest:[self blockTestingForRefLog]];
    
    if (direction) *direction = NSWindowBelow;
    if (top != NSNotFound) return [refLogs objectAtIndex:top];
    
    // look at bottom
    range.location = baseLogIndex + 1;
    range.length = (range.location < [refLogs count]) ? [refLogs count] - range.location : 0;
    NSIndexSet *bottomSet = [NSIndexSet indexSetWithIndexesInRange:range];
    bottom = [refLogs indexOfObjectAtIndexes:bottomSet options:NSEnumerationConcurrent passingTest:[self blockTestingForRefLog]];
    
    if (direction) *direction = NSWindowAbove;
    if (bottom != NSNotFound) return [refLogs objectAtIndex:bottom];
    
    return nil;
}

- (BOOL)_parentHierarchyEnabledForItem:(NTTreeNode *)item
{
    // make sure all the parents of the selected object are enabled
    BOOL parentHierarchyEnabled = YES;
    while ((item = item.parent) && parentHierarchyEnabled) parentHierarchyEnabled = [item.enabled boolValue];
    return parentHierarchyEnabled;
}

// TODO: GCD Blocking canidate
// Be careful though, as you need at least one reference to begin, and the effects of parallel operations may prove ineffective as the logs could appear out of order. If anything, the logs can be created in parallel, but need to be reordered serially.
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
        if (NTLogOperatorReorderLogs & options)
        {
            // if we have a refLog, use that. Otherwise, just do a crude process
            if (refLog) [[log window] orderWindow:direction relativeTo:[[refLog window] windowNumber]];
            else [log front];
        }
        if (NTLogOperatorDestroyLogs & options) [log destroyLogProcess];
        if ((NTLogOperatorHighlightLogs | NTLogOperatorUnhighlightLogs) & options) [log setHighlighted:(NTLogOperatorHighlightLogs & options) from:self];
    }
}
@end

@implementation NTTreeController (Helper)
- (NSArray *)_enabledDescendantLogsForGroup:(NTGroup *)group;
{
    NSTreeNode *groupTreeNode = [self treeNodeForObject:group];
    return [self _enabledLeafDescendantRepObjsForNode:groupTreeNode];
}

- (NSArray *)_enabledLeafDescendantRepObjsForNode:(NSTreeNode *)node;
{
    NSMutableArray *array = [NSMutableArray array];
    NTTreeNode *repObj = nil;
    
    if (![[[node representedObject] valueForKey:@"enabled"] boolValue]) return; // if not enabled, do not worry about it
    
    // if log, return obj
    if ([node isLeaf]) return [NSArray arrayWithObject:[node representedObject]];
        
    // if group, traverse group
	for (NSTreeNode *item in [node childNodes])
    {
        repObj = [item representedObject];
        if (![[repObj valueForKey:@"enabled"] boolValue]) continue;
        
		if ([item isLeaf]) [array addObject:repObj];
		else [array addObjectsFromArray:[self _enabledLeafDescendantRepObjsForNode:item]];
	}
	return [[array copy] autorelease];    
}

- (NSArray *)_enabledLeafDescendantRepObjsForNodes:(NSArray *)nodes;
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSTreeNode *node in nodes)
        [array addObjectsFromArray:[self _enabledLeafDescendantRepObjsForNode:node]];
    return [[array copy] autorelease];
}

- (NSArray *)_allEnabledLogs
{
    NSMutableArray *enabledItems = [NSMutableArray array];
    for (NSTreeNode *rootNode in [self rootNodes])
    {
        [enabledItems addObjectsFromArray:[self _enabledLeafDescendantRepObjsForNode:rootNode]];
    }
    return [[enabledItems copy] autorelease];
}

@end

