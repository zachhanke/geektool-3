/*
 * NSTreeController+NodeAccessor.m
 * NerdTool
 * Created by Kevin Nygaard on 5/28/10.
 * Copyright 2009 MutableCode. All rights reserved.
 * 
 * Adapted from:
 * $Id: UtilityFunctions.m 1066 2007-11-12 07:14:42Z stephen_booth $
 * Copyright (C) 2006 - 2007 Stephen F. Booth <me@sbooth.org>
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

#import "NSTreeController+NodeAccessor.h"


@interface NSTreeController (NodeAccessor_Private)
- (NSTreeNode *)_treeNodeForRepresentedObject:(id)representedObject root:(NSTreeNode *)root;
@end

@implementation NSTreeController (NodeAccessor)

- (NSTreeNode *)treeNodeForRepresentedObject:(id)representedObject
{
    return [self _treeNodeForRepresentedObject:representedObject root: [self arrangedObjects]];
}

@end

@implementation NSTreeController (NodeAccessor_Private)

- (NSTreeNode *)_treeNodeForRepresentedObject:(id)representedObject root:(NSTreeNode *)root
{
	NSCParameterAssert(nil != root);
	NSCParameterAssert(nil != representedObject);
	
	// Termination condition
	if([[root representedObject] isEqual:representedObject])
		return root;
	
	NSEnumerator	*enumerator		= [[root childNodes] objectEnumerator];
	NSTreeNode		*child			= nil;
	NSTreeNode		*match			= nil;
	
	// Perform a breadth-first search
	while(nil == match && (child = [enumerator nextObject])) {
		if([[child representedObject] isEqual:representedObject])
			match = child;
	}
	
	if(nil == match) {
		enumerator 	= [[root childNodes] objectEnumerator];
		child 		= nil;
		
		while(nil == match && (child = [enumerator nextObject]))
			match = [self _treeNodeForRepresentedObject:representedObject root:child];
	}
	
	return match;
}

@end
