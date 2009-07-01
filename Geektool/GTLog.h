//
//  GTLog.h
//  GeekTool
//
//  Created by Yann Bizeul on Sun Jan 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
@class NTLogProcess;

@interface GTLog : NSObject <NSMutableCopying, NSCopying, NSCoding>
{
    NTLogProcess *logProcess;
    NSMutableDictionary *properties;
    BOOL isBeingDragged;
    NSNumber *active;
}
@property (assign) NTLogProcess *logProcess;
@property (retain) NSMutableDictionary *properties;
@property (copy) NSNumber *active;

- (id)initWithProperties:(NSDictionary*)newProperties;
- (id)init;
- (void)dealloc;

// observing
- (void)setupObservers;
- (void)removeObservers;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

// kvc
- (void)setIsBeingDragged:(BOOL)var;
- (BOOL)isBeingDragged;
- (void)setCoords:(NSRect)newCoords;

// misc
- (BOOL)equals:(GTLog*)comp;
- (NSString*)description;

// copying
- (id)copyWithZone:(NSZone *)zone;
- (id)mutableCopyWithZone:(NSZone *)zone;

// coding
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
@end