//
//  GTLog.h
//  GeekTool
//
//  Created by Yann Bizeul on Sun Jan 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "NTLogProtocol.h"

@class NTGroup;

@interface GTLog : NSObject <NSMutableCopying,NSCopying,NSCoding>
{
    id highlightSender;
    NTGroup *parentGroup;
    
    id<NTLogProtocol> logProcess;
    NSMutableDictionary *properties;
    
    NSNumber *active;
    BOOL postActivationRequest;
    BOOL isBeingDragged;
    BOOL needCoordObservers;
}
@property (assign) NTGroup *parentGroup;
@property (assign) id<NTLogProtocol> logProcess;
@property (retain) NSMutableDictionary *properties;
@property (copy) NSNumber *active;
@property (assign) BOOL postActivationRequest;

- (id)initWithProperties:(NSDictionary*)newProperties;
- (id)initAsType:(NSString*)type;
- (void)dealloc;

// observing
- (void)setupObservers;
- (void)removeObservers;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

// kvc
- (void)setIsBeingDragged:(BOOL)var;
- (BOOL)isBeingDragged;

// misc
- (void)setCoords:(NSRect)newCoords;
- (void)setHighlighted:(BOOL)val from:(id)sender;
- (BOOL)equals:(GTLog*)comp;
- (NSString*)description;

// copying
- (id)copyWithZone:(NSZone *)zone;
- (id)mutableCopyWithZone:(NSZone *)zone;

// coding
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
@end