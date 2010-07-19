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

#import "AppDelegate.h"
#import "NTLog.h"
#import "NTGroup.h"
#import "NTTreeNode.h"


@interface NTTreeController (Observer)
@end

@interface NTTreeController(LogManipulation)
- (void)createAndDestroyLogsIfNecessary:(NSArray *)logs;
- (void)moveNodeWindow:(NTLog *)node;
- (void)moveNodeWindow:(NTLog *)node usingRefLogs:(NSArray *)refLogs;
- (void)moveNodeWindows:(NSArray *)nodes;
@end

@interface NTTreeController (NodeProperties)
- (NTLog *)_findNextReferenceLogFor:(NTLog *)item direction:(NSWindowOrderingMode*)direction usingRefLogs:(NSArray *)refLogs;
- (BOOL (^)(id obj, NSUInteger idx, BOOL *stop))_blockTestingForRefLog;
@end

@interface NTTreeController (TreeAccessors)
- (NSSet *)_unorderedAllLogs;
- (NSArray *)_allLogs;
- (NSArray *)_allEnabledLogs;
- (NSSet *)_unorderedLogsIn:(NSSet *)ntNodes;
- (NSArray *)_logsIn:(NSArray *)ntNodes;
- (NSArray *)_enabledLogsIn:(NSArray *)ntNodes;

- (NSArray *)_leafDescendantRepObjsForNodes:(NSArray *)nodes;
- (NSArray *)_enabledLeafDescendantRepObjsForNodes:(NSArray *)nodes;
- (NSArray *)_leafDescendantRepObjsForGroup:(NTGroup *)group;
- (NSArray *)_enabledDescendantLogsForGroup:(NTGroup *)group;
- (NSArray *)_leafDescendantRepObjsForNTNodes:(NSArray *)ntNodes;
- (NSSet *)_unorderedLeafDescendantForNTNodes:(NSSet *)ntNodes;
- (NSArray *)_leafDescendantRepObjsForIndexPaths:(NSArray *)indexPaths;
@end


@implementation NTTreeController

@synthesize previousSelectedLogs;

#pragma mark Content Modifiers
- (void)insertObject:(id)object atArrangedObjectIndexPath:(NSIndexPath *)indexPath;
{
	[super insertObject:object atArrangedObjectIndexPath:indexPath];
	[self _updateSortOrderOfModelObjects];
    
    NSArray *objectArray = [self _leafDescendantRepObjsForNTNodes:[NSArray arrayWithObject:object]];
    
    [self createAndDestroyLogsIfNecessary:objectArray];
    [self moveNodeWindows:objectArray];    
}

- (void)insertObjects:(NSArray *)objects atArrangedObjectIndexPaths:(NSArray *)indexPaths;
{
	[super insertObjects:objects atArrangedObjectIndexPaths:indexPaths];
	[self _updateSortOrderOfModelObjects];

    NSArray *objectArray = [self _leafDescendantRepObjsForNTNodes:objects];
    
    [self createAndDestroyLogsIfNecessary:objectArray];
    [self moveNodeWindows:objectArray];    
}

- (void)removeObjectAtArrangedObjectIndexPath:(NSIndexPath *)indexPath;
{
    NSArray *objectArray = [self _leafDescendantRepObjsForIndexPaths:[NSArray arrayWithObject:indexPath]];

    [super removeObjectAtArrangedObjectIndexPath:indexPath];
	[self _updateSortOrderOfModelObjects];
        
    [objectArray makeObjectsPerformSelector:@selector(destroyLog)];
}

- (void)removeObjectsAtArrangedObjectIndexPaths:(NSArray *)indexPaths;
{
    NSArray *objectArray = [self _leafDescendantRepObjsForIndexPaths:indexPaths];
    
    [super removeObjectsAtArrangedObjectIndexPaths:indexPaths];
	[self _updateSortOrderOfModelObjects];
        
    [objectArray makeObjectsPerformSelector:@selector(destroyLog)];    
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
    
    // !!!: uncomment
    //NSArray *enabledArray = [self _enabledLeafDescendantRepObjsForNodes:nodes];
    //NSArray *allArray = [self _leafDescendantRepObjsForNodes:nodes];
    
    //[self createAndDestroyLogsIfNecessary:allArray];
    //[self moveNodeWindows:enabledArray];
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
    [self addObserver:self forKeyPath:@"effectiveEnabled" options:0 context:nil];
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
        for (NTTreeNode *item in [object selectedObjects])
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
            
            if (![[self _unorderedAllLogs] containsObject:item]) return;
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
        
        NSArray *logArray = [self _allLogs];
        [self createAndDestroyLogsIfNecessary:logArray];
        [self moveNodeWindows:logArray];
    }
    // when something is enabled/disabled
    else if([keyPath isEqualToString:@"effectiveEnabled"])
    {                
        [self moveNodeWindows:object];
    }
    else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}
@end


@implementation NTTreeController(LogManipulation)

// Take an array of NTLogs and create/destroy their log processes as needed
- (void)createAndDestroyLogsIfNecessary:(NSArray *)logs
{
    for (NTLog *log in logs)
    {
        if (![log.enabled boolValue] || ![[log parentHierarchyEnabled] boolValue]) [log destroyLogProcess];
        else if ([log.enabled boolValue])
        {
            [log createLogProcess];
            [log updateWindowIncludingTimer:YES];
            if ([[self selectedObjects] containsObject:log]) [log setHighlighted:YES from:self];
        }
    }
}

// Takes an NTLog and positions it's window correctly with respect to windows of other NTLogs
- (void)moveNodeWindow:(NTLog *)node
{
    if (!node || ![node.enabled boolValue]) return;
    
    // since we are only moving one node, we can use all the logs for reference
    [self moveNodeWindow:node usingRefLogs:[self _allEnabledLogs]];
}

// Moves a single NTLog into position, but restricts the references to which it can position the window against to `refLogs'.
- (void)moveNodeWindow:(NTLog *)node usingRefLogs:(NSArray *)refLogs
{
    if (!node || ![node.enabled boolValue]) return;
    
    NTLog *refLog = nil;
    NSWindowOrderingMode direction = NSWindowAbove;
    
    refLog = [self _findNextReferenceLogFor:node direction:&direction usingRefLogs:refLogs];
    if (refLog) [[node window] orderWindow:direction relativeTo:[[refLog window] windowNumber]];
    else [node front];
}

// Takes an array of NTLogs and positions their windows correctly without using logs from `nodes'. This method assures that while moving groups of NTLogs, they will not be placed with a bad reference.
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

// Returns an unordered set of all NTLog objects
- (NSSet *)_unorderedAllLogs
{
    return [self _unorderedLogsIn:[self content]];
}

// Returns a sorted array of all NTLog objects
- (NSArray *)_allLogs
{
    return [self _logsIn:[self content]];
}

// Returns a sorted array of all effective enabled NTLog objects
- (NSArray *)_allEnabledLogs
{
    return [self _enabledLogsIn:[self content]];
}

// Returns an unordered set of NTLogs that descend from the set `ntNodes' (inclusive)
- (NSSet *)_unorderedLogsIn:(NSSet *)ntNodes
{
    NSMutableSet *set = [NSMutableSet set];
    
    for (NTTreeNode *ntNode in ntNodes)
    {
        [set unionSet:[ntNode unorderedDescendants]];
    }
    
    return [[set copy] autorelease];    
}

// Returns an ordered array of NTLogs that descend from the array `ntNodes' (inclusive)
- (NSArray *)_logsIn:(NSArray *)ntNodes
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (NTTreeNode *ntNode in ntNodes)
    {
        [array addObjectsFromArray:[ntNode orderedDescendants]];
    }
    
    return [[array copy] autorelease];    
}

// Returns an ordered array of effective enabled NTLogs that descend from the array `ntNodes' (inclusive)
- (NSArray *)_enabledLogsIn:(NSArray *)ntNodes
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (NTTreeNode *ntNode in ntNodes)
    {
        [array addObjectsFromArray:[ntNode orderedEnabledDescendants]];
    }
    
    return [[array copy] autorelease];    
}

- (NTTreeNode *)objectAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *object = [self content];
    int i;
    for (i=0; i < [indexPath length]; i++)
    {
        object = [object objectAtIndex:[indexPath indexAtPosition:i]];
    }
}

#pragma mark (NSTreeNode) Node Leaf Descendants
// a (sorted) array of all NTLog objects that descend from the array of NSTreeNode `nodes'
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

// a (sorted) array of all enabled NTLog objects that descend from the array of NSTreeNode `nodes', provided that the parent hierarchy is also enabled
- (NSArray *)_enabledLeafDescendantRepObjsForNodes:(NSArray *)nodes
{
    NSMutableArray *array = [NSMutableArray array];
    NTTreeNode *repObj = nil;
    
	for (NSTreeNode *node in nodes)
    {
        repObj = [node representedObject];
        if (![[repObj valueForKey:@"enabled"] boolValue]) continue; // is the object enabled?
        if (![self _parentHierarchyEnabledForItem:repObj]) continue; // is the parent hierarchy of the object enabled?
        
		if ([node isLeaf]) [array addObject:repObj];
		else [array addObjectsFromArray:[self _enabledLeafDescendantRepObjsForNodes:[node childNodes]]];
	}
	return [[array copy] autorelease];    
}

#pragma mark NTGroup Leaf Descendants
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

#pragma mark NTTreeNode Leaf Descendants
- (NSArray *)_leafDescendantRepObjsForNTNodes:(NSArray *)ntNodes
{
    NSMutableArray *array = [NSMutableArray array];
    for (NTTreeNode *node in ntNodes)
    {
        if (![[node enabled] boolValue]) continue; // is the object enabled?
        if (![self _parentHierarchyEnabledForItem:node]) continue; // is the parent hierarchy of the object enabled?
        
		if ([[node isLeaf] boolValue]) [array addObject:node];
		else [array addObjectsFromArray:[self _leafDescendantRepObjsForGroup:(NTGroup *)node]];
	}
    return [[array copy] autorelease];
}

// a (unsorted) array of all NTLog objects that descend from the array of NTTreeNode `nodes'
- (NSSet *)_unorderedLeafDescendantForNTNodes:(NSSet *)ntNodes
{
    NSMutableSet *set = [NSMutableSet set];
    for (NTTreeNode *node in ntNodes)
    {        
		if ([[node isLeaf] boolValue]) [set addObject:node];
		else [set unionSet:[self _unorderedLeafDescendantForNTNodes:[node children]]];
	}
    return [[set copy] autorelease];
}

#pragma mark NSIndexPath Leaf Descendants
- (NSArray *)_leafDescendantRepObjsForIndexPaths:(NSArray *)indexPaths
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPaths)
    {
        [array addObject:[self nodeAtIndexPath:indexPath]];
    }
    
    return [self _leafDescendantRepObjsForNodes:array];
}
@end

