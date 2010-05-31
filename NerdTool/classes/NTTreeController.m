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
- (NTLog *)_findNextEnabledLogAbove:(NTTreeNode *)item;
- (BOOL)_parentHierarchyEnabledForItem:(NTTreeNode *)item;
- (void)operateOnNTLogArray:(NSArray *)logItems withOptions:(NSLogOperator)options refLog:(NTLog *)refLog;
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
	[super moveNodes:nodes toIndexPath:indexPath];
	[self _updateSortOrderOfModelObjects];

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
    //[self addObserver:self forKeyPath:@"arrangedObjects.enabled" options:0 context:nil];
    [self addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];
    [self addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];
    [self addObserver:self forKeyPath:@"enabled" options:0 context:nil];    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // when a selection is changed
    if([keyPath isEqualToString:@"selectedObjects"])
    {        
        // clear prefsView
        [[prefsView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
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
        
        // We are guarantee that these are all similar NTLogs
        self.previousSelectedLogs = [object selectedObjects];
        for (NTLog *selectedLog in previousSelectedLogs)
        {
            [selectedLog setHighlighted:YES from:self];
            [selectedLog setupPreferenceObservers];
        }
        [prefsView addSubview:[firstItem loadPrefsViewAndBind:object]];
    }
    // when we add/remove/rearrange an item
    /*
    else if([keyPath isEqualToString:@"arrangedObjects"])
    {
        NSLog(@"Selected objects");
    }
     */
    // when something is enabled/disabled
   else if([keyPath isEqualToString:@"enabled"])
    {
        BOOL groupSelected = ([object isKindOfClass:[NTGroup class]]) ? YES : NO;
        BOOL currentEnabledState = [[object valueForKey:@"enabled"] boolValue];
        /*
         * Group?    Enabled?    Action
         *   NO         NO       If parent hierarchy is enabled, kill Log process (no other info needed)
         *   NO         YES      If parent hierarchy is enabled, create Log process (need next enabled Log above, if it exists)
         *   YES        NO       If parent hierarchy is enabled, kill all enabled members of group (no other info needed)
         *   YES        YES      If parent hierarchy is enabled, create all enabled members of group (need next enabled Log above, if it exists)
         */
        if (![self _parentHierarchyEnabledForItem:object]) return; // return if a parent hierarchy is not enabled
        
        if (groupSelected)
        {
            NSArray *descendants = [object descendants];
            if (currentEnabledState)
            {
                // make sure the guy above us has a window, otherwise he's worthless to us
                NTLog *nextEnableLogAbove = [self _findNextEnabledLogAbove:object];
                nextEnableLogAbove = ([nextEnableLogAbove window]) ? nextEnableLogAbove : nil;
                [self operateOnNTLogArray:descendants withOptions:(NTLogOperatorCreateLogs | NTLogOperatorReorderLogs) refLog:nextEnableLogAbove];
            }
            else [self operateOnNTLogArray:descendants withOptions:NTLogOperatorDestroyLogs refLog:nil];
        }
        else
        {
            NSArray *descendants = [object descendants];
            NSArray *selectedLog = [NSArray arrayWithObject:object];
            
            if (currentEnabledState)
            {                
                NTLog *nextEnableLogAbove = [self _findNextEnabledLogAbove:object];
                nextEnableLogAbove = ([nextEnableLogAbove window]) ? nextEnableLogAbove : nil;
                
                [self operateOnNTLogArray:selectedLog withOptions:(NTLogOperatorCreateLogs | NTLogOperatorReorderLogs) refLog:nextEnableLogAbove];
            }
            else [self operateOnNTLogArray:selectedLog withOptions:NTLogOperatorDestroyLogs refLog:nil];
        }
    }
    else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

// returns nil if there isn't one
- (NTLog *)_findNextEnabledLogAbove:(NTTreeNode *)item
{
    // find root
    NSArray *allItems = [self flattenedContent]; // this array comes sorted
    
    // keep enabled items only
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.enabled == 1 AND self isKindOfClass: %@", [NTLog class]];
    NSArray *enabledItems = [allItems filteredArrayUsingPredicate:predicate];
    
    // sort array
    NSRange range;
    range.location = 0;
    range.length = [enabledItems indexOfObject:item];
    NSArray *aboveItems = [enabledItems subarrayWithRange:range];
    
    return [aboveItems lastObject];
}

- (BOOL)_parentHierarchyEnabledForItem:(NTTreeNode *)item
{
    // make sure all the parents of the selected object are enabled
    BOOL parentHierarchyEnabled = YES;
    while ((item = item.parent) && parentHierarchyEnabled) parentHierarchyEnabled = [item.enabled boolValue];
    return parentHierarchyEnabled;
}

- (void)operateOnNTLogArray:(NSArray *)logItems withOptions:(NSLogOperator)options refLog:(NTLog *)refLog
{
    NSEnumerator *e = [logItems reverseObjectEnumerator];
    for (NTLog *log in e)
    {
        if (NTLogOperatorCreateLogs & options)
        {
            [log createLogProcess];
            [log updateWindowIncludingTimer:YES];
        }
        if (NTLogOperatorReorderLogs & options)
        {
            // if we have a refLog, use that. Otherwise, just do a crude process
            if (refLog) [[log window] orderWindow:NSWindowBelow relativeTo:[[refLog window] windowNumber]];
            else [log front];
        }
        if (NTLogOperatorDestroyLogs & options) [log destroyLogProcess];
    }
}


@end