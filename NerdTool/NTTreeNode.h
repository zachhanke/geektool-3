/*
 * NTTreeNode.h
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

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>


@interface NTTreeNode : NSManagedObject
{
}

// Core Data Properties
@property (retain) NSNumber *enabled;
@property (retain) NSNumber *isLeaf;
@property (retain) NSNumber *isSelectable;
@property (retain) NSString *name;
@property (retain) NSNumber *sortIndex;
@property (retain) NSSet *children;
@property (retain) NTTreeNode *parent;

@end

@interface NTTreeNode (CoreDataGeneratedAccessors)
- (void)addChildrenObject:(NTTreeNode *)value;
- (void)removeChildrenObject:(NTTreeNode *)value;
- (void)addChildren:(NSSet *)value;
- (void)removeChildren:(NSSet *)value;

@end
