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
@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSNumber * isLeaf;
@property (nonatomic, retain) NSNumber * isSelectable;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * sortIndex;
@property (nonatomic, retain) NSSet* children;
@property (nonatomic, retain) NTTreeNode * parent;

- (NSArray *)descendants;
- (void)destroyLogProcess;
- (void)createLogProcess;

@end

@interface NTTreeNode (CoreDataGeneratedAccessors)
- (void)addChildrenObject:(NTTreeNode *)value;
- (void)removeChildrenObject:(NTTreeNode *)value;
- (void)addChildren:(NSSet *)value;
- (void)removeChildren:(NSSet *)value;
@end
