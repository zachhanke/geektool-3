//
//  NTGroup.m
//  NerdTool
//
//  Created by Kevin Nygaard on 6/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTGroup.h"
#import "GTLog.h"
#import "NTLogProcess.h"

// Organizes and holds instantiated GTLogs
@implementation NTGroup

@synthesize properties;
@synthesize logs;

- (id)initWithProperties:(NSDictionary*)initProperties andLogs:(NSArray*)initLogs
{
    if (!(self = [super init])) return nil;
    
    // just in case we wanted to add more stuff later on
    [self setProperties:[NSMutableDictionary dictionaryWithDictionary:initProperties]];
    [self setLogs:[NSMutableArray arrayWithArray:initLogs]];
    
    [logs makeObjectsPerformSelector:@selector(setParentGroup:) withObject:self];
    
    [self addObserver:self forKeyPath:@"properties.active" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
    
    return self;
}

- (id)init
{
    // just in case we wanted to add more stuff later on
    NSDictionary *defaultProperties = [[NSMutableDictionary alloc]initWithObjectsAndKeys:
                                       NSLocalizedString(@"Default",nil), @"name",
                                       [NSNumber numberWithBool:NO], @"active",
                                       nil];
    NSArray *defaultLogs = [[NSMutableArray alloc]init];
    
    return [self initWithProperties:defaultProperties andLogs:defaultLogs];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"properties.active"]; 
    [properties release];
    [logs release];
    [super dealloc];
}

- (void)reorder
{
    NSEnumerator *e = [[self logs]reverseObjectEnumerator];
    for (GTLog *log in e) [[log logProcess]front];
}

#pragma mark Observing
// properties.active is changed by GroupController
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"properties.active"])
    {
        if (![logs count]) return;
        
        [logs makeObjectsPerformSelector:@selector(setActive:) withObject:[NSNumber numberWithBool:[[change valueForKey:NSKeyValueChangeNewKey]boolValue]]];
        [self reorder];
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

#pragma mark Misc
- (BOOL)equals:(NTGroup*)comp
{
    if ([[self properties]isEqualTo:[comp properties]] && [[self logs]isEqualTo:[comp logs]]) return YES;
    else return NO;
}

- (NSString*)description
{
    return [NSString stringWithFormat: @"Group:[%@]%@",[[[self properties]objectForKey:@"active"]boolValue]?@"X":@" ",[[self properties]objectForKey:@"name"]];
}

#pragma mark Copying
- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class]allocWithZone:zone]initWithProperties:[NSDictionary dictionaryWithDictionary:[self properties]] andLogs:[[[NSArray alloc]initWithArray:[self logs] copyItems:YES]autorelease]];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [self copyWithZone:zone];
}

@end
