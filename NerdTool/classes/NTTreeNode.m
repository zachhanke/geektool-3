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
    [self addObserver:self forKeyPath:@"children" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"enabled" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"parentHierarchyEnabled" options:0 context:NULL];
}

- (void)destroyNode
{
    [self removeObserver:self forKeyPath:@"parent"];
    [self removeObserver:self forKeyPath:@"enabled"];
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
        //[[object children] makeObjectsPerformSelector:@selector(setParentHierarchyEnabled:) withObject:self.parentHierarchyEnabled];
    }
    else if([keyPath isEqualToString:@"parentHierarchyEnabled"])// TODO working with enable around here. what does it need to do. Who should handle it?
    {
        //[[object children] makeObjectsPerformSelector:@selector(setParentHierarchyEnabled:) withObject:self.parentHierarchyEnabled];
    }
    else if([keyPath isEqualToString:@"children"]){}
    else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

/*
+ (NSSet *)keyPathsForValuesAffectingParent
{
    return [NSSet setWithObjects:@"children", nil];
}

+ (NSSet *)keyPathsForValuesAffectingEffectiveEnabled
{
    return [NSSet setWithObjects:@"parentHierarchyEnabled", @"enabled", nil];
}*/

#pragma mark Children
/**
 * @returns ordered (sorted) array of the object's children
 */
- (NSArray *)sortedChildren
{
    NSSet *children = [self children];
    return [self sortSet:children];
}

/**
 * @returns ordered (sorted) array of the object's enabled children
 */
- (NSArray *)sortedEnabledChildren
{
    NSSet *enabledChildren = [[self children] objectsPassingTest:[self objectEnabled]];
    return [self sortSet:enabledChildren];
}

/**
 * @returns sorts a set into an array using the property `sortIndex'
 */
- (NSArray *)sortSet:(NSSet *)set
{
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
    return [set sortedArrayUsingDescriptors:sortDescriptors];
}

/**
 * A GCD Block statement to find objects that are enabled
 */
- (BOOL (^)(id obj, BOOL *stop))objectEnabled
{
    return [[^(id obj, BOOL *stop)
             {
                 if ([[obj enabled] boolValue])
                 {
                     *stop = YES;
                     return YES;
                 }
                 return NO;
             } copy] autorelease];
}

#pragma mark Descendants

/**
 * Returns unordered set of all leaf descendants (NTLogs). If none exist, an
 * empty set is returned.
 *
 * @returns unordered set of all leaf descendants (NTLogs)
 */
- (NSSet *)unorderedDescendants
{
	NSMutableSet *set = [NSMutableSet set];

	for (NTTreeNode *child in [self children])
    {
		if ([[child isLeaf] boolValue]) [set addObject:child];
        else [set unionSet:[child unorderedDescendants]];
	}
	return [[set copy] autorelease];
}

/**
 * Returns an ordered (sorted) array of all leaf descendants (NTLogs). If none
 * exist, an empty array is returned.
 *
 * For those of you clever folk, you CANNOT call -unorderedDescendants and then
 * try to sort by `sortIndex'.  `sortIndex' is on a per child relationship, so a
 * parent's children can have indicies of 1, 2, 3, 4, etc.  and the parent's
 * children's children could also have indicies of 1, 2, 3, 4, etc.
 *
 * @returns Ordered (sorted) array of all leaf descendants (NTLogs).
 */
- (NSArray *)orderedDescendants
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (NTTreeNode *child in [self sortedChildren])
    {
        if ([[child isLeaf] boolValue]) [array addObject:child];
        else [array addObjectsFromArray:[child orderedDescendants]];
    }
	return [[array copy] autorelease];    
}

/**
 * Returns an ordered (sorted) array of all effective enabled leaf descendants
 * (NTLogs). If none exist, an empty array is returned. 
 *
 * Like the unordered situation, you CANNOT use the -enabledDescendants and
 * parse out the enabled bits. Actually, you could, but you would be traversing
 * through the array twice (which is bad).  
 *
 * @returns Ordered (sorted) array of all effective enabled leaf descendants
 * (NTLogs)
 */
- (NSArray *)orderedEnabledDescendants
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (NTTreeNode *child in [self sortedEnabledChildren])
    {
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
