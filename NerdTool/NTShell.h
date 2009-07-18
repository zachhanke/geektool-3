//
//  NTShell.h
//  NerdTool
//
//  Created by Kevin Nygaard on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLogProtocol.h"

@class LogWindow;
@class NTGroup;

@interface NTShell : NSObject <NTLogProtocol>
{
    IBOutlet id command;
    IBOutlet id refresh;
    IBOutlet id prefsView;
    
    // Container
    NSMutableDictionary *properties;
    NTGroup *parentGroup;
    NSNumber *active;
    BOOL _isBeingDragged;
    BOOL _postActivationRequest;
    id _highlightSender;
    
    // LogProcess
    NSWindowController *_windowController;
    LogWindow *window;
    NSDictionary *_env;    
    
    NSArray *_arguments;
    
    NSTask *_task;
    NSTimer *_timer;
    
    BOOL _timerNeedsUpdate;
}
// Container
@property (retain) NSMutableDictionary *properties;
@property (assign) NTGroup *parentGroup;
@property (copy) NSNumber *active;
@property (assign) BOOL _isBeingDragged;

// LogProcess
@property (retain) NSWindowController *_windowController;
@property (assign) LogWindow *window;
@property (copy) NSDictionary *_env;
@property (copy) NSArray *_arguments;
@property (retain) NSTask *_task;
@property (retain) NSTimer *_timer;
@property (assign) BOOL timerNeedsUpdate;

//// Container

// Protocol Methods
- (BOOL)needsDisplayUIBox;
- (NSView *)loadPrefsViewAndBind:(id)bindee;
- (NSView *)unloadPrefsViewAndUnbind;

//// Log Container
- (id)initWithProperties:(NSDictionary*)newProperties;
- (void)dealloc;
// Observing
- (void)setupPreferenceObservers;
- (void)removePreferenceObservers;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
// KVC
- (void)set_isBeingDragged:(BOOL)var;

//// Log Process
- (void)createLogProcess;
- (void)destroyLogProcess;
// Observing
- (void)setupProcessObservers;
- (void)removeProcessObservers;
- (void)notificationHandler:(NSNotification *)notification;
// KVC
- (void)set_timer:(NSTimer*)newTimer;
- (void)killTimer;
- (void)updateTimer;
// Window Creation/Management
- (void)setupLogWindowAndDisplay;
- (void)createWindow;
- (void)updateWindow;
// Task
- (void)updateCommand:(NSTimer*)timer;
- (void)processNewDataFromTask:(NSNotification*)aNotification;
// Update
- (void)updateTextAttributes;
// Window operations
- (void)front;
// Convience
- (NSRect)screenToRect:(NSRect)appleCoordRect;
- (NSRect)rect;
// Misc
- (void)setHighlighted:(BOOL)val from:(id)sender;
- (BOOL)equals:(NTShell*)comp;
- (NSString*)description;
// Copying
- (id)copyWithZone:(NSZone *)zone;
- (id)mutableCopyWithZone:(NSZone *)zone;
// Coding
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

@end