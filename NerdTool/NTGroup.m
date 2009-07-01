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

- (id)initWithProperties:(NSDictionary*)initProperties andLogs:(NSArray*)initLogs
{
    if (!(self = [super init])) return nil;
    
    // just in case we wanted to add more stuff later on
    [self setProperties:initProperties];
    [self setLogs:initLogs];
    [self addObserver:self forKeyPath:@"properties.active" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
    
    return self;
}

- (id)init
{
    // just in case we wanted to add more stuff later on
    NSDictionary *defaultProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       @"Default", @"name",
                                       [NSNumber numberWithBool:NO], @"active",
                                       nil];
    NSArray *defaultLogs = [[NSMutableArray alloc] init];
    
    return [self initWithProperties:defaultProperties andLogs:defaultLogs];
}

- (void)dealloc
{
    [properties release];
    [logs release];
    [self removeObserver:self forKeyPath:@"properties.active"]; 
    [super dealloc];
}

#pragma mark Observing
// properties.active is changed by GroupController
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"properties.active"])
    {
        if ([change valueForKey:NSKeyValueChangeOldKey] != [change valueForKey:NSKeyValueChangeNewKey]) return;
        if ([logs count]) [logs makeObjectsPerformSelector:@selector(setActive:) withObject:[NSNumber numberWithBool:[[change valueForKey:NSKeyValueChangeNewKey]boolValue]]];
    }
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
        properties = [[NSMutableDictionary alloc]initWithDictionary:newProperties];
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
        logs = [[NSMutableArray alloc]initWithArray:newLogs];
    }
}

#pragma mark Coding
- (id)initWithCoder:(NSCoder *)coder
{
    return [self initWithProperties:[coder decodeObjectForKey:@"properties"] andLogs:[coder decodeObjectForKey:@"logs"]];
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
