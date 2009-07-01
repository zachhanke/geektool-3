//
//  NSDictionary+IntAndBoolAccessors.m
//  NerdTool
//
//  Created by Kevin Nygaard on 6/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+IntAndBoolAccessors.h"

@implementation NSDictionary (IntAndBoolAccessors)

- (int)integerForKey:(NSString *)key
{
    return [[self objectForKey:key]intValue];
}

- (BOOL)boolForKey:(NSString *)key
{
    return [[self objectForKey:key]boolValue];
}

@end
