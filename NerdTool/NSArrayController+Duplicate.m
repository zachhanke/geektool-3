//
//  NSArrayController+Duplicate.m
//  NerdTool
//
//  Created by Kevin Nygaard on 6/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

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
