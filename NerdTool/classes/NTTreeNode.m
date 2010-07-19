/*
 * NTTreeNode.m
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

#import "NTTreeNode.h"


@implementation NTTreeNode

// Core Data Properties
@dynamic enabled;
@dynamic isLeaf;
@dynamic isSelectable;
@dynamic name;
@dynamic sortIndex;
@dynamic children;
@dynamic parent;

@synthesize parentHierarchyEnabled;

- (void)awakeFromInsert
{
    [self configureNode];
}

- (void)awakeFromFetch
{
    [self configureNode];
}

- (void)configureNode
{
    if (!self.parent) self.parentHierarchyEnabled = [NSNumber numberWithBool:TRUE];
    else if ([self.enabled boolValue]) self.parentHierarchyEnabled = self.parent.parentHierarchyEnabled;
    else self.parentHierarchyEnabled = [NSNumber numberWithBool:FALSE];
    
    [self addObserver:self forKeyPath:@"parent" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"parentHierarchyEnabled" options:0 context:NULL];
}

- (void)destroyNode
{
    [self removeObserver:self forKeyPath:@"parent"];
    [self removeObserver:self forKeyPath:@"parentHierarchyEnabled"];
}

- (BOOL)effectiveEnabled
{
    return (![self.enabled boolValue] || ![self.parentHierarchyEnabled boolValue]) ? FALSE : TRUE;
}

#pragma mark Observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"parent"])
    {
        
        [[object children] makeObjectsPerformSelector:@selector(setParentHierarchyEnabled:) withObject:self.parentHierarchyEnabled];
    }
    else if([keyPath isEqualToString:@"parentHierarchyEnabled"])
    {
        [[object children] makeObjectsPerformSelector:@selector(setParentHierarchyEnabled:) withObject:self.parentHierarchyEnabled];
    }
    else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


+ (NSSet *)keyPathsForValuesAffectingParent
{
    return [NSSet setWithObjects:@"children", nil];
}

+ (NSSet *)keyPathsForValuesAffectingEffectiveEnabled
{
    return [NSSet setWithObjects:@"parentHierarchyEnabled", @"enabled", nil];
}

#pragma mark Children
- (NSArray *)sortedChildren
{
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
    return [[self children] sortedArrayUsingDescriptors:sortDescriptors];
}

#pragma mark Descendants
/*
 * NOTE: The reason that these descendants functions include `self' is to avoid creating a proxy object. The function names are somewhat misleading, as it implies that you be your own child.
 * We are trying to get a flat list of NTLogs. With this inclusive implementation, I can call an array of NTTreeNodes and get my flat NTLog list. The alternative to this is creating a proxy NTGroup, point it's children to the NTTreeNode array, and then call -descendants (non-inclusive flavor). This would restore the meaning of `descendant', but when I tried to implement it, I felt the creation of the proxy object was very shady with all the MO stuff going on. I really don't care about keeping track of my changes this proxy object does; I just want access to the functions.
 * Hopefully, my reasoning makes sense to everyone.
 */
// Returns an unordered set of all leaf descendants (NTLogs). Inclusive. If none exist, nil is returned.
- (NSSet *)unorderedDescendants
{
    // This is why the fn is inclusive. Return self if it's a leaf.
    if ([[self isLeaf] boolValue]) return [NSSet setWithObject:self];
    return [self _unorderedDescendants];
}

- (NSSet *)_unorderedDescendants
{
	NSMutableSet *set = [NSMutableSet set];
	for (NTTreeNode *child in [self children])
    {
		if ([[child isLeaf] boolValue]) [set addObject:child];
        else [set unionSet:[child unorderedDescendants]];
	}
	return [[set copy] autorelease];
}

// Returns an ordered set of all leaf descendants (NTLogs). Inclusive. If none exist, nil is returned.
- (NSArray *)orderedDescendants
{
    // This is why the fn is inclusive. Return self if it's a leaf.
    if ([[self isLeaf] boolValue]) return [NSArray arrayWithObject:self];
    return [self _orderedDescendants];
}

- (NSArray *)_orderedDescendants
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (NTTreeNode *child in [self sortedChildren])
    {
        if ([[child isLeaf] boolValue]) [array addObject:child];
        else [array addObjectsFromArray:[child orderedDescendants]];
    }
	return [[array copy] autorelease];    
}

// Returns an ordered set of all effective enabled leaf descendants (NTLogs). Inclusive. If none exist, nil is returned.
- (NSArray *)orderedEnabledDescendants
{
    // If we are not enabled, then our descendants are also not enabled
    if (![self.enabled boolValue]) return nil;

    // If our parent hierarchy is not enabled, then neither are we, and hence, neither are our descendants
    if (![self parentHierarchyEnabled]) return nil;
    
    // This is why the fn is inclusive. Return self if it's a leaf.
    if ([[self isLeaf] boolValue]) return [NSArray arrayWithObject:self];
        
    return [self _orderedEnabledDescendants];
}

- (NSArray *)_orderedEnabledDescendants
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (NTTreeNode *child in [self sortedChildren])
    {
        // If the child is not enabled, go to the next one
        if (![[child enabled] boolValue]) continue;
        
        if ([[child isLeaf] boolValue]) [array addObject:child];
        else [array addObjectsFromArray:[child orderedEnabledDescendants]];
	}
	return [[array copy] autorelease];            
}

#pragma mark  
- (NSString*)description
{
    return [NSString stringWithFormat: @"%@ :[%@] %@",[self className],[self.enabled boolValue] ? @"X" : @" ", self.name];
}

- (void)createLogProcess
{
    NSAssert(YES,@"Method was not overwritten: `createLogProcess'");
}

- (void)destroyLogProcess
{
    NSAssert(YES,@"Method was not overwritten: `destroyLogProcess'");
}

@end
