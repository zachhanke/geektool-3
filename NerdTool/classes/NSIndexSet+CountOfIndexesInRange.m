//
//  NSIndexSet+CountOfIndexesInRange.m
//  NerdTool
//
//  Created by Kevin Nygaard on 6/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSIndexSet+CountOfIndexesInRange.h"

@implementation NSIndexSet (CountOfIndexesInRange)

- (unsigned int)countOfIndexesInRange:(NSRange)range
{
    unsigned int start, end, count;
    
    if (range.length == 0)
    {
        return 0;  
    }
    
    start  = range.location;
    end    = start + range.length;
    count  = 0;
    
    unsigned int currentIndex = [self indexGreaterThanOrEqualToIndex:start];
    
    while ((currentIndex != NSNotFound) && (currentIndex < end))
    {
        count++;
        currentIndex = [self indexGreaterThanIndex:currentIndex];
    }
    
    return count;
}

@end