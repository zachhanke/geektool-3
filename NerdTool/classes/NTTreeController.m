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

// TODO: plug original developer

#import "NTTreeController.h"
#import "NSTreeController_Extensions.h"
#import "NSTreeNode_Extensions.h"
#import "NSIndexPath_Extensions.h"

#import "AppDelegate.h"
#import "NTLog.h"
#import "NTGroup.h"
#import "NTTreeNode.h"
#import "NTShell.h"

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
- (NSSet *)_allLogsUnordered;
- (NSArray *)_allLogsOrdered;
- (NSArray *)_allLogsEnabled;
- (NSSet *)_unorderedLogsIn:(NSSet *)ntNodes;
- (NSArray *)_orderedLogsIn:(NSArray *)ntNodes;
- (NSArray *)_enabledLogsIn:(NSArray *)ntNodes;

- (NSArray *)_descendantLogsForNodes:(NSArray *)nodes;
- (NSArray *)_enabledDescendantLogsForNodes:(NSArray *)nodes;
- (NSArray *)_NTLogsBeneathGroup:(NTGroup *)group;
- (NSArray *)_enabledNTLogsBeneathGroup:(NTGroup *)group;
- (NSArray *)_descendantLogsForNTNodes:(NSArray *)ntNodes;
- (NSSet *)_unorderedLeafDescendantForNTNodes:(NSSet *)ntNodes;
- (NSArray *)_leafDescendantRepObjsForIndexPaths:(NSArray *)indexPaths;
@end

/**
 * Responsible for managing the tree. Adding object(s), deleting object(s), moving object(s).
 * It should also be able to list the contents of the tree in a simple manner.
 * Because this class moves the logs around, it should also maintain the order
 */
@implementation NTTreeController

@synthesize previousSelectedLogs;

#pragma mark Content Modifiers

// Generates root node if we need one. Returns TRUE if it generated one, FALSE if one was already there.
- (BOOL)generateRootObject
{
    BOOL generated = NO;
    int rootNodes = [self numberOfRootNodes];
    
    if (rootNodes <= 0)
    {
        // TODO: should set parent of existing nodes to ROOT
        NTGroup *root = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:[self managedObjectContext]];
        root.name = @"ROOT";
        root.isSpecialGroup = [NSNumber numberWithBool:YES];
        [self insertObject:root atArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:0]];	
        generated = TRUE;
    }
    else if (rootNodes > 1)
    {
        [NSException raise:@"MyException" format:@"There are more than one root nodes!"];
    }

    return generated;
}

- (int)numberOfRootNodes
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Group" inManagedObjectContext:[self managedObjectContext]]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"isSpecialGroup == 1"]]; 
    
    NSError *error = nil;
    int rootNodes = [[self managedObjectContext] countForFetchRequest:request error:&error];
    
    [request release];
    return rootNodes;
}

- (NTGroup*)rootNode
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Group" inManagedObjectContext:[self managedObjectContext]]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"isSpecialGroup == 1"]];
    
    NSError* error = nil;
    NSArray* managedObjects = [[self managedObjectContext] executeFetchRequest:request error:&error];

    if(!managedObjects)
    {
        [NSException raise:@"MyException" format:@"Error occurred during fetch: %@",error];
    }
    
    NTGroup* rootItem = nil;
    if([managedObjects count]) rootItem = [managedObjects objectAtIndex:0];
    
    [request release];
    return rootItem;
}

/**
 * Inserts NTTreeNode `object' at NSIndexPath `indexPath'.
 * @param[in] object The object to insert. A solid NTTreeNode object (NTLog or NTGroup)
 * @param[in] indexPath Index path to insert object.
 */
- (void)insertObject:(id)object atArrangedObjectIndexPath:(NSIndexPath *)indexPath;
{
    if([indexPath length] == 1)
    {
        NTGroup *rootItem = [self rootNode];        
        if (!rootItem) [NSException raise:@"MyException" format:@"Could not find root note!"];
        ((NTTreeNode*)object).parent = rootItem;
    }
    
	[super insertObject:object atArrangedObjectIndexPath:indexPath];
	[self _updateSortOrderOfModelObjects];
    
    // TODO: objects should create themselves KVO on effectiveenabled
    //NSArray *objectArray = [self _orderedLogsIn:[NSArray arrayWithObject:object]];
    //[self createAndDestroyLogsIfNecessary:objectArray];
    
    // make sure that log windows are moved after their windos have been
    // initialized. Otherwise, we "move" the windows, then create them
    //[self moveNodeWindows:objectArray];
}

/**
 * Inserts multiple NTTreeNode `objects' at multiple NSIndexPath's `indexPaths'.
 * @param[in] objects An array of solid NTTreeNode objects (NTLog or NTGroup) to insert.
 * @param[in] indexPath An array of index paths to insert objects.
 */
- (void)insertObjects:(NSArray *)objects atArrangedObjectIndexPaths:(NSArray *)indexPaths;
{
    NTGroup *rootItem = [self rootNode];
    for (NSIndexPath *path in indexPaths)
    {
        if ([path length] == 1)
        {
            static NSUInteger i = 0;
            id object = [objects objectAtIndex:i];
            if (!rootItem) [NSException raise:@"MyException" format:@"Could not find root note!"];
            ((NTTreeNode*)object).parent = rootItem;
            i++;
        }
    }
	[super insertObjects:objects atArrangedObjectIndexPaths:indexPaths];
	[self _updateSortOrderOfModelObjects];

    // TODO: objects should create themselves KVO on effectiveenabled
    //NSArray *objectArray = [self _orderedLogsIn:objects];    
    //[self createAndDestroyLogsIfNecessary:objectArray];
    
    //[self moveNodeWindows:objectArray];    
}

/**
 * Removes object located at NSIndexPath `indexPath'.
 * This function should not be called directly.
 * @param[in] indexPath NSIndexPath to object to remove
 */
- (void)removeObjectAtArrangedObjectIndexPath:(NSIndexPath *)indexPath;
{
    NSArray *objectArray = [self _leafDescendantRepObjsForIndexPaths:[NSArray arrayWithObject:indexPath]];

    [super removeObjectAtArrangedObjectIndexPath:indexPath];
	[self _updateSortOrderOfModelObjects];
        
    [objectArray makeObjectsPerformSelector:@selector(destroyLog)];
}

/**
 * Removes objects located at NSIndexPath's `indexPaths'.
 * This function should not be called directly.
 * @param[in] indexPaths NSArray of NSIndexPath's of objects to remove
 */
- (void)removeObjectsAtArrangedObjectIndexPaths:(NSArray *)indexPaths;
{
    NSArray *objectArray = [self _leafDescendantRepObjsForIndexPaths:indexPaths];
    
    [super removeObjectsAtArrangedObjectIndexPaths:indexPaths];
	[self _updateSortOrderOfModelObjects];
        
    [objectArray makeObjectsPerformSelector:@selector(destroyLog)];    
}

/**
 * Moves NSTreeNode `node' to NSIndexPath `indexPath'.
 * @param[in] node NSTreeNode to move.
 * @param[in] indexPath NSIndexPath of where to move `node'.
 */
- (void)moveNode:(NSTreeNode *)node toIndexPath:(NSIndexPath *)indexPath;
{
	[super moveNode:node toIndexPath:indexPath];
	[self _updateSortOrderOfModelObjects];
    
    NSArray *enabledArray = [self _enabledDescendantLogsForNodes:[NSArray arrayWithObject:node]];
    NSArray *allArray = [self _descendantLogsForNodes:[NSArray arrayWithObject:node]];
    
    //[self createAndDestroyLogsIfNecessary:allArray];
    //[self moveNodeWindows:enabledArray];
}

/**
 * Moves all NSTreeNodes `nodes' to NSIndexPath `indexPath'.
 * @param[in] nodes NSArray of NSTreeNode's to move.
 * @param[in] indexPath NSIndexPath of where to move `nodes'.
 */
- (void)moveNodes:(NSArray *)nodes toIndexPath:(NSIndexPath *)indexPath;
{
	[super moveNodes:nodes toIndexPath:indexPath];
    [self _updateSortOrderOfModelObjects];
    
    NSArray *enabledArray = [self _enabledDescendantLogsForNodes:nodes];
    NSArray *allArray = [self _descendantLogsForNodes:nodes];
    
    //[self createAndDestroyLogsIfNecessary:allArray];
    //[self moveNodeWindows:enabledArray];
}

/**
 * Updates sort order of all NTTreeNode objects.
 * This takes the entire opaque NSTreeNode tree structure, pulls each
 * representive object and assigns a sort index.
 */
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
    [self generateRootObject];
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
            
            if (![[self _allLogsUnordered] containsObject:item]) return;
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
        
        NSArray *logArray = [self _allLogsOrdered];
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

/**
 * Take an array of NTLogs and create/destroy their log processes as needed.
 * @param[in] logs An array of NTLogs to create or destroy.
 */
- (void)createAndDestroyLogsIfNecessary:(NSArray *)logs
{
    for (NTLog *log in logs)
    {
        if (log.effectiveEnabled)
        {
            [log createLogProcess];
            [log updateWindowIncludingTimer:YES];
            if ([[self selectedObjects] containsObject:log]) [log setHighlighted:YES from:self];
        }
        else [log destroyLogProcess];
    }
}

/**
 * Takes an NTLog and positions it's window correctly with respect to windows of other NTLogs.
 * Using this function requires the node be enabled.
 * TODO: Does `node' need to have an active window as well?
 * @param[in] node NTLog to put into position.
 */
- (void)moveNodeWindow:(NTLog *)node
{
    // since we are only moving one node, we can use all the logs for reference
    [self moveNodeWindow:node usingRefLogs:[self _allLogsEnabled]];
}

/**
 * Moves a single NTLog into position, but restricts the references to which it can position the window against to `refLogs'.
 * @param[in] node NTLog to put into position.
 * @param[in] refLogs An array of NTLogs to use as a reference position. This
 * array must be properly ordered.
 */
- (void)moveNodeWindow:(NTLog *)node usingRefLogs:(NSArray *)refLogs
{
    if (!node || !node.effectiveEnabled) return;
    
    NTLog *refLog = nil;
    NSWindowOrderingMode direction = NSWindowAbove;
    
    refLog = [self _findNextReferenceLogFor:node direction:&direction usingRefLogs:refLogs];
    if (refLog) [[node window] orderWindow:direction relativeTo:[[refLog window] windowNumber]];
    else [node front];
}

/**
 * Takes an array of NTLogs and positions their windows correctly without using logs from `nodes'. 
 * This method assures that while moving groups of NTLogs, they will not be placed with a bad reference.
 * @param[in] An array of NTLogs to move properly into position.
 */
- (void)moveNodeWindows:(NSArray *)nodes
{
    if (!nodes || [nodes count] <= 0) return;
    
    // find all canidates
    NSArray *allLogs = [self _allLogsEnabled];
    NSMutableArray *refLogs = [NSMutableArray array];
    NSMutableArray *nodesToKeep = [NSMutableArray array];
    NSMutableArray *nodesToDelete = [NSMutableArray array];
    
    NSEnumerator *e = [nodes reverseObjectEnumerator];
    for (NTLog *node in e)
    {
        if (!node.effectiveEnabled) continue;
        
        [refLogs setArray:allLogs]; // reset our refs
        [nodesToKeep addObject:node]; // every time we run through this loop, we gain another reference log to use
        
        [nodesToDelete setArray:nodes];
        [nodesToDelete removeObjectsInArray:nodesToKeep]; // protect the nodes we want to keep
        [refLogs removeObjectsInArray:nodesToDelete]; // kill the rest from our refs

        [self moveNodeWindow:node usingRefLogs:refLogs];
    }
}

- (void)moveNodeWindows1:(NSArray *)nodes allNodes:(NSArray *)allNodes
{
    if (!nodes || [nodes count] <= 0) return;
    
    // find all canidates
    NSArray *allLogs = allNodes;
    NSMutableArray *refLogs = [NSMutableArray array];
    NSMutableArray *nodesToKeep = [NSMutableArray array];
    NSMutableArray *nodesToDelete = [NSMutableArray array];    
    NSEnumerator *e = [nodes reverseObjectEnumerator];
    for (NTLog *node in allLogs)
    {
        if (!node.effectiveEnabled) continue;
        
        [refLogs setArray:allLogs]; // reset our refs
        [nodesToKeep addObject:node]; // every time we run through this loop, we gain another reference log to use
        
        [nodesToDelete setArray:nodes];
        [nodesToDelete removeObjectsInArray:nodesToKeep]; // protect the nodes we want to keep
        [refLogs removeObjectsInArray:nodesToDelete]; // kill the rest from our refs
        
        [self moveNodeWindow:node usingRefLogs:refLogs];
    }
}

- (void)moveNodeWindows2:(NSArray *)nodes allNodes:(NSArray *)allNodes
{
    if (!nodes || [nodes count] <= 0) return;
    
    // find all canidates
    NSArray *allLogs = allNodes;    
    NSEnumerator *e = [nodes reverseObjectEnumerator];
    for (NTLog *node in allLogs)
    {
        if (!node.effectiveEnabled) continue;
        [node front];
    }
}

@end


@implementation NTTreeController (NodeProperties)

/**
 * Finds closest neighboring NTLog to the NTLog `item'.
 * Given a flat, ordered array representation of a tree structure (containing only NTLogs), this function will return a reference NTLog to the input `item', and include a reference direction (if the closest log is either above or below `item').
 * This function checks for top references before bottom references.
 * It is also important to note that in order for an NTLog in `refLogs' to be considered a neighbor, it **must** have an active window. The main purpose of this function is to facilitate window ordering, so a neighbor with no active window is useless to us.
 * Example. `item' = foo. `refLogs' is as follows:
 * 
 * - EnabledLog1
 * - EnabledLog2
 * - DisabledLog1
 * - DisabledLog2
 * - foo
 * - EnabledLog3
 * - DisabledLog3
 * - DisabledLog4
 *
 * The function would return `EnabledLog2' with a `direction' of NSWindowBelow. Note that even though EnabledLog3 is closer, EnabledLog2 is returned because the code checks the top of the array first.
 * 
 * @param[in] item The base NTLog. Must exist in `refLogs'.
 * @param[in] refLogs Neighboring NTLogs to `item'. This is ordered array that represents the flattened tree structure.
 * @param[out] direction Pointer that will contain the relative position of the neighboring log. This is where the base object is with respect to the returned object.
 * @returns NTLog that is closest to the base NTLog.
 */
- (NTLog *)_findNextReferenceLogFor:(NTLog *)item direction:(NSWindowOrderingMode *)direction usingRefLogs:(NSArray *)refLogs
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

/**
 * A GCD Block statement for finding logs with active windowControllers.
 * This function is used primarily by _findNextReferenceLogFor
 */
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

/** 
 * Returns an unordered set of all NTLog objects.
 * @returns Unordered set of all NTLog objects in the tree.
 */
- (NSSet *)_allLogsUnordered
{
    return [self _unorderedLogsIn:[self content]];
}

/** 
 * Returns an ordered (sorted) array of all NTLog objects.
 * @returns Ordered (sorted) array of all NTLog objects in the tree.
 */
- (NSArray *)_allLogsOrdered
{
    return [self _orderedLogsIn:[self content]];
}

/** 
 * Returns an ordered (sorted) array of all effective enabled NTLog objects.
 * @returns Ordered (sorted) array of all effective enabled NTLog objects in the tree.
 */
- (NSArray *)_allLogsEnabled
{
    return [self _enabledLogsIn:[self content]];
}

/** 
 * Returns an unordered set of all NTLog objects that descend from the set `ntNodes' (inclusive).
 * @param[in] ntNodes An NSSet of NTNodes to flatten
 * @returns Unordered set of all NTLog objects in `ntNodes'.
 */
- (NSSet *)_unorderedLogsIn:(NSSet *)ntNodes
{
    NSMutableSet *set = [NSMutableSet set];
    
    for (NTTreeNode *ntNode in ntNodes)
    {
        if ([ntNode.isLeaf boolValue]) [set addObject:ntNode];
        else [set unionSet:[ntNode unorderedDescendants]];
    }
    
    return [[set copy] autorelease];    
}

/** 
 * Returns an ordered (sorted) array of all NTLog objects that descend from the set `ntNodes' (inclusive).
 * @param[in] ntNodes An NSArray of NTNodes to flatten.
 * @returns Ordered (sorted) array of all NTLog objects in `ntNodes'.
 */
- (NSArray *)_orderedLogsIn:(NSArray *)ntNodes
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (NTTreeNode *ntNode in ntNodes)
    {
        if ([ntNode.isLeaf boolValue]) [array addObject:ntNode];
        else [array addObjectsFromArray:[ntNode orderedDescendants]];
    }
    
    return [[array copy] autorelease];    
}

/** 
 * Returns an ordered (sorted) array of all effective enabled NTLog objects that descend from the set `ntNodes' (inclusive).
 * @param[in] ntNodes An NSArray of NTNodes to flatten.
 * @returns Ordered (sorted) array of all effective enabled NTLog objects in `ntNodes'.
 */
- (NSArray *)_enabledLogsIn:(NSArray *)ntNodes
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (NTTreeNode *ntNode in ntNodes)
    {
        if ([ntNode.isLeaf boolValue]) [array addObject:ntNode];
        else [array addObjectsFromArray:[ntNode orderedEnabledDescendants]];
    }
    
    return [[array copy] autorelease];    
}

#pragma mark (NSTreeNode) Node Leaf Descendants
/** 
 * Returns a sorted array of all NTLog objects that descend from the array of opaque NSTreeNode `nodes'.
 * This operation is inclusive.
 *
 * Example
 *
 * - Group1
 *      - Log1
 *      - Log2
 *      - Log3
 * - Group2
 *      - Group3
 *          - Log4
 *      - Log5
 *      - Log6
 * - Group3
 *      - Log6
 *      - Log7
 * - Log8
 * - Log9
 *
 * For `nodes' Group2, Group3, and Log8, this function returns the represented objects
 * for logs 4-8 (which will be NTLogs).
 *
 * TODO: What happens if the same node is in the array multiple times? Empty
 * array? Null array?
 *  
 * @param[in] nodes An array of nodes to pull represented objects from.
 * @returns Ordered (sorted) array of NTLog objects.
 */
- (NSArray *)_descendantLogsForNodes:(NSArray *)nodes
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (NSTreeNode *item in nodes)
    {
		if ([item isLeaf]) [array addObject:[item representedObject]];
		else [array addObjectsFromArray:[self _descendantLogsForNodes:[item childNodes]]];      
    }
    
    return [[array copy] autorelease];
}

/** 
 * Returns a (sorted) array of all enabled NTLog objects that descend from the array of NSTreeNode `nodes', provided that the parent hierarchy is also enabled.
 * In other words, this returns the NTLogs that are `effectively' enabled.
 * @param[in] nodes An array of nodes to pull represented objects from.
 * @returns Ordered (sorted) array of enabled NTLog objects.
 */
- (NSArray *)_enabledDescendantLogsForNodes:(NSArray *)nodes
{
    NSMutableArray *array = [NSMutableArray array];
    NTTreeNode *repObj = nil;
    
	for (NSTreeNode *node in nodes)
    {
        repObj = [node representedObject];
        if (![[repObj valueForKey:@"enabled"] boolValue]) continue;
        
		if ([node isLeaf]) [array addObject:repObj];
		else [array addObjectsFromArray:[self _enabledDescendantLogsForNodes:[node childNodes]]];
	}
	return [[array copy] autorelease];    
}

#pragma mark NSIndexPath Leaf Descendants
- (NSArray *)_leafDescendantRepObjsForIndexPaths:(NSArray *)indexPaths
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPaths)
    {
        [array addObject:[self nodeAtIndexPath:indexPath]];
    }
    
    return [self _descendantLogsForNodes:array];
}
@end
