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
    // log window creation
    NSWindowController *windowController;
    LogWindow *window;
    
    // log window movement
    BOOL _isBeingDragged;

    // resolution change detection
    NSRect _visibleFrame;
    
    // preference view management
    BOOL _loadedView;
    IBOutlet id prefsView;

    
    //// Below are ivars that are not used directly by NTLog
    // Set by NTLog for subclasses
    NSDictionary *env;
    
    // Created for use by subclasses (not referenced in NTLog except in creation/destruction)
    NSArray *arguments;
    NSTimer *timer;
    NSTask *task; // custom accessor setup
}

// Core Data Properties
@property (nonatomic, retain) NSNumber *alwaysOnTop;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *shadowWindow;
@property (nonatomic, retain) NSNumber *sizeToScreen;
@property (nonatomic, retain) NSNumber *h;
@property (nonatomic, retain) NSNumber *w;
@property (nonatomic, retain) NSNumber *x;
@property (nonatomic, retain) NSNumber *y;

// Standard properties
@property (retain) NSWindowController *windowController;
@property (assign) LogWindow *window;

@property (assign) IBOutlet id prefsView;

@property (copy) NSArray *arguments;
@property (copy) NSDictionary *env;
@property (retain) NSTimer *timer;
@property (retain) NSTask *task;

// Properties (Subclass these)
- (NSString *)logTypeName;
- (NSString *)preferenceNibName;
- (NSString *)displayNibName;
- (void)setupInterfaceBindingsWithObject:(id)bindee;
- (void)destroyInterfaceBindings;
// Window Management
- (void)updateWindowIncludingTimer:(BOOL)updateTimer;
- (void)awakeFromInsert;
- (void)awakeFromFetch;
- (void)createLog;
- (void)destroyLog;
- (void)dealloc;
// Interface
- (NSView *)loadPrefsViewAndBind:(id)bindee;
- (NSView *)unloadPrefsViewAndUnbind;
- (void)setupPreferenceObservers;
- (void)removePreferenceObservers;
// KVC
- (void)set_isBeingDragged:(BOOL)var;
// Process Creation/Destruction
- (BOOL)createLogProcess;
- (BOOL)destroyLogProcess;
// Window Creation/Destruction
- (BOOL)createWindow;
- (BOOL)destroyWindow;
// Environment Creation/Destruction
- (void)createEnv;
- (void)destroyEnv;
// Observing Creation/Destruction
- (void)setupProcessObservers;
- (void)notificationHandler:(NSNotification *)notification;
- (void)removeProcessObservers;
// KVC
- (void)setTask:(NSTask*)newTask;
// Window Management
- (void)setHighlighted:(BOOL)val from:(id)sender;
- (void)front;
// Convience
- (NSRect)screenToRect:(NSRect)appleCoordRect;
- (NSRect)rect;
@end
