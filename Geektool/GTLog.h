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

@interface GTLog : NSObject <NSCopying,NSCoding>
{
    IBOutlet id logWindowController;
    LogWindowController *windowController;
    
    NSMutableDictionary *properties;
    
    NSFont *font;
    
    NSArray *arguments;
    NSDictionary *attributes;
    NSMutableDictionary *logDictionary;
    NSDictionary *env;
    NSTask *task;
    NSTimer *timer;
    bool clear;
    bool empty;
    bool running;
    bool keepTimers;
    int i;
    int windowLevel;
}

- (id)initWithDictionary:(NSDictionary*)aDictionary;
- (NSDictionary*)dictionary;
- (void)setDictionary:(NSDictionary*)aDictionary force:(BOOL)force;
- (void)setDictionary:(NSDictionary*)dictionary;

- (NSMutableDictionary *)properties;
- (void)setProperties:(NSDictionary *)newProperties;
#pragma mark -
#pragma mark Convience Accessors
- (NSRect)realRect;
- (NSRect)rect;
- (int)NSImageFit;
- (int)NSPictureAlignment;
- (NSFont*)font;
#pragma mark -
#pragma mark Convience Mutators

#pragma mark -
#pragma mark Logs operations
- (id)copyWithZone:(NSZone *)zone;
- (bool)equals:(GTLog*)comp;
- (void)front;
- (id)mutableCopyWithZone:(NSZone *)zone;
- (void)newLines:(NSNotification*)aNotification;
- (void)openWindow;
- (void)setHighlighted:(BOOL)myHighlight;
- (void)setSticky:(BOOL)flag;
- (void)taskEnd:(NSNotification*)aNotification;
- (void)terminate;
- (void)updateCommand:(NSTimer*)timer;
- (void)updateWindow;
#pragma mark -
#pragma mark Misc
- (NSRect)screenToRect:(NSRect)var;

@end

@interface NSDictionary (intBoolValues)
- (int)integerForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
@end