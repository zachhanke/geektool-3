/*
 * NSArrayController+Duplicate.h
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
