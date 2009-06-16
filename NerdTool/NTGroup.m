//
//  NTGroup.m
//  NerdTool
//
//  Created by Kevin Nygaard on 6/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTGroup.h"

// Organizes and holds instantiated GTLogs

@implementation NTGroup

- (id)init
{
    if (self = [super init])
    {
        // just in case we wanted to add more stuff later on
        properties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                               @"Default", @"name",
                               nil];
        logs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [properties release];
    [logs release];
    
    [super dealloc];
}

#pragma mark KVC
- (NSMutableDictionary *)properties
{
    return properties;
}

- (void)setProperties:(NSDictionary *)newProperties
{
    if (properties != newProperties)
    {
        [properties autorelease];
        properties = [[NSMutableDictionary alloc] initWithDictionary:newProperties];
    }
}

- (NSMutableArray *)logs
{
    return logs;
}

- (void)setLogs:(NSArray *)newLogs
{
    if (logs != newLogs)
    {
        [logs autorelease];
        logs = [[NSMutableArray alloc] initWithArray:newLogs];
    }
}

#pragma mark Coding
- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        [self setProperties:[coder decodeObjectForKey:@"properties"]];
        [self setLogs: [coder decodeObjectForKey:@"logs"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:properties forKey:@"properties"];
    [coder encodeObject:logs forKey:@"logs"];
}

@end
