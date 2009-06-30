//
//  GTLog.h
//  GeekTool
//
//  Created by Yann Bizeul on Sun Jan 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "LogWindowController.h"

@interface GTLog : NSObject <NSMutableCopying, NSCopying, NSCoding>
{
    // KVC
    NSTimer *timer;
    
    bool isBeingDragged;
    
    // Synthesized
    LogWindowController *windowController;
    NSMutableDictionary *properties;
    NSTask *task;
    BOOL active;
    BOOL keepTimers;
    NSDictionary *env;
    NSDictionary *attributes;
    NSArray *arguments;
}
@property (retain) LogWindowController *windowController;
@property (copy) NSDictionary* properties;
@property (retain) NSTask *task;
@property (assign) BOOL active;
@property (assign) BOOL keepTimers;
@property (copy) NSDictionary *env;
@property (copy) NSDictionary *attributes;
@property (copy) NSArray *arguments;
@property (retain) NSTimer *timer;

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context;
- (id)init;
- (id)initWithProperties:(NSDictionary*)newProperties;
- (void)dealloc;
- (void)terminate;

#pragma mark Observing
- (void)setupObservers;
- (void)removeObservers;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
#pragma mark -
#pragma mark KVC
- (void)setTimer:(NSTimer*)newTimer;
- (NSTimer*)timer;
- (void)setIsBeingDragged:(BOOL)var;
- (bool)isBeingDragged;
#pragma mark -
- (BOOL)updateAgainstProperties:(NSDictionary*)aDictionary;
#pragma mark Convience Accessors
- (void)setCoords:(NSRect)newCoords;
- (NSRect)realRect;
- (NSRect)screenToRect:(NSRect)var;
- (NSRect)rect;
- (int)NSImageFit;
- (int)NSPictureAlignment;
- (NSFont*)font;
#pragma mark -
#pragma mark Window operations
- (void)front;
- (void)setImage:(NSString*)urlStr;
- (void)setHighlighted:(BOOL)myHighlight;
- (void)setSticky:(BOOL)flag;
#pragma mark Window Creation/Management
- (void)createWindow;
- (void)updateWindow;
- (void)updateCommand:(NSTimer*)timer;
#pragma mark Convenience Helpers
- (void)updateTextAttributes;
- (void)updateTimer;
#pragma mark -
#pragma mark Window notifications
- (void)newLines:(NSNotification*)aNotification;
- (void)taskEnd:(NSNotification*)aNotification;
#pragma mark -
#pragma mark Misc
- (BOOL)equals:(GTLog*)comp;
- (NSString*)description;
#pragma mark -
#pragma mark Copying
- (id)copyWithZone:(NSZone *)zone;
- (id)mutableCopyWithZone:(NSZone *)zone;
#pragma mark Coding
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
@end

#pragma mark 
@interface NSDictionary (intBoolValues)
- (int)integerForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
@end