/*
 * NTLog.h
 * NerdTool
 * Created by Kevin Nygaard on 7/20/09.
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

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>
#import "NTTreeNode.h"

@class NTGroup;
@class LogWindow;

@interface NTLog : NTTreeNode
{
    NSMutableDictionary *properties;
    NSNumber *active;
    NTGroup *parentGroup;

    NSWindowController *windowController;
    LogWindow *window;

    BOOL _loadedView;
    IBOutlet id prefsView;

    id highlightSender;
    BOOL postActivationRequest;
    BOOL _isBeingDragged;

    NSArray *arguments;
    NSDictionary *env;
    NSTimer *timer;
    NSTask *task;
    
    NSRect _visibleFrame;
    
    NSMutableString *lastRecievedString;
}

// Core Data Properties
@property (retain) NSNumber *alwaysOnTop;
@property (retain) NSString *name;
@property (retain) NSNumber *shadowWindow;
@property (retain) NSNumber *sizeToScreen;
@property (retain) NSNumber *h;
@property (retain) NSNumber *w;
@property (retain) NSNumber *x;
@property (retain) NSNumber *y;

@property (retain) NSWindowController *windowController;
@property (assign) LogWindow *window;

@property (assign) IBOutlet id prefsView;

@property (assign) id highlightSender;
@property (assign) BOOL postActivationRequest;
@property (assign) BOOL _isBeingDragged;

@property (copy) NSArray *arguments;
@property (copy) NSDictionary *env;
@property (retain) NSTimer *timer;
@property (retain) NSTask *task;
@property (retain) NSMutableString *lastRecievedString;

// Properties
- (NSString *)preferenceNibName;
- (NSString *)displayNibName;
- (NSDictionary *)defaultProperties;
// Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee;
- (void)destroyInterfaceBindings;

// Window Management
- (void)updateWindowIncludingTimer:(BOOL)updateTimer;
// Log Container
- (id)initWithProperties:(NSDictionary*)newProperties;
- (id)init;
- (void)dealloc;
// Interface
- (NSView *)loadPrefsViewAndBind:(id)bindee;
- (NSView *)unloadPrefsViewAndUnbind;
- (void)setupPreferenceObservers;
- (void)removePreferenceObservers;
// KVC
- (void)set_isBeingDragged:(BOOL)var;
// Log Process
// Management
- (void)createLogProcess;
- (void)destroyLogProcess;
// Observing
- (void)setupProcessObservers;
- (void)notificationHandler:(NSNotification *)notification;
// KVC
- (void)setTimer:(NSTimer*)newTimer;
- (void)killTimer;
- (void)updateTimer;
// Window Management
- (void)setHighlighted:(BOOL)val from:(id)sender;
- (void)front;
- (IBAction)attemptBestWindowSize:(id)sender;
// Convience
- (NSDictionary*)customAnsiColors;
- (NSRect)screenToRect:(NSRect)appleCoordRect;
- (NSRect)rect;
- (BOOL)equals:(NTLog*)comp;
- (NSString*)description;
// Copying
- (id)copyWithZone:(NSZone *)zone;
- (id)mutableCopyWithZone:(NSZone *)zone;
// Coding
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
@end
