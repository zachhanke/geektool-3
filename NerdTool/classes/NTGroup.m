/*
 * NTGroup.m
 * NerdTool
 * Created by Kevin Nygaard on 6/15/09.
 * Copyright 2009 MutableCode. All rights reserved.
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

#import "NTGroup.h"


@implementation NTGroup

// Core Data Properties
@dynamic canCollapse;
@dynamic canExpand;
@dynamic isExpanded;
@dynamic isSpecialGroup;

- (void)awakeFromInsert
{
	self.isLeaf = [NSNumber numberWithBool:NO];
}

@end
