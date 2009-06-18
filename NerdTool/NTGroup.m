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
                               [NSNumber numberWithBool:NO], @"active",
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

#pragma mark Copying/Misc
- (id)copyWithZone:(NSZone *)zone
{
    id result = [[[self class] allocWithZone:zone] init];
    
    [result setProperties:[self properties]];
    [result setLogs:[self logs]];
    
    return result;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [self copyWithZone: zone];
}

- (BOOL)equals:(NTGroup*)comp
{
    if ([[self properties] isEqualTo: [comp properties]] &&
        [[self logs] isEqualTo: [comp logs]]) return YES;
    else return NO;
}
@end
