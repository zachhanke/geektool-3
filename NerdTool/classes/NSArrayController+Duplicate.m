/*
 * NSArrayController+Duplicate.m
 * NerdTool
 * Created by Kevin Nygaard on 6/17/09.
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

#import "NSArrayController+Duplicate.h"


@implementation NSArrayController (Duplicate)

- (void)duplicateSelection
{
    // just in case this gets called with nothing selected...
    if ([self selectionIndex] != NSNotFound)
    {
        // copy the selection (potentially multiple items)
        NSArray *copyObjects = [[NSArray alloc]initWithArray:[self selectedObjects] copyItems:YES];
        
        NSMutableDictionary *tmpDictionary = nil;
        
        for (id tmpObject in copyObjects)
        {
            tmpDictionary = [tmpObject properties];
            [[tmpObject properties]setObject:[self duplicateCheck:[tmpDictionary objectForKey:@"name"]] forKey:@"name"];
        }
        
        // add our duplicate groups to the controller
        [self insertObjects:copyObjects atArrangedObjectIndexes:[NSIndexSet indexSetWithIndex:[self selectionIndex]]];
        
        [copyObjects release];
    }
}

- (NSString*)duplicateCheck:(NSString*)myObjectName
{
    // add a new group, but don't allow duplicates
    NSString *newObjectName = [NSString stringWithString: myObjectName];
    NSArray *splitName = [newObjectName componentsSeparatedByString:@" "];
    NSMutableArray *mutableSplitName = [splitName mutableCopy];
    
    BOOL needsCopy = YES;
    
    for (NSString *tmpString in mutableSplitName)
        if([tmpString isEqualToString:NSLocalizedString(@"copy",nil)]) needsCopy = NO;
    
    if (needsCopy) [mutableSplitName addObject:NSLocalizedString(@"copy",nil)];
    else
    {
        NSInteger count = [[mutableSplitName lastObject]integerValue];
        if (count != 0) [mutableSplitName removeLastObject];
        count++;
        [mutableSplitName addObject:[NSString stringWithFormat:@"%i",count]];
    }
    
    NSString *returnString = [mutableSplitName componentsJoinedByString:@" "]; 
    [mutableSplitName release];
    
    return returnString;
}

@end
