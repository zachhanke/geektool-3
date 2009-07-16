//
//  NTLogProcess.h
//  NerdTool
//
//  Created by Kevin Nygaard on 6/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GTLog;
@class LogWindow;

@interface NTLogProcess : NSObject
{
    NSWindowController *windowController;
    LogWindow *window;
    NSDictionary *env;
    GTLog *parentLog;
    NSDictionary *parentProperties;
    NSDictionary *attributes;

    BOOL timerRepeats;
    
    NSTask *task;
    NSTimer *timer;
    
    NSArray *arguments;
    BOOL timerNeedsUpdate;
}
@property (retain) NSWindowController *windowController;
@property (retain) LogWindow *window;
@property (copy) NSDictionary *env;
@property (assign) GTLog *parentLog;
@property (assign) NSDictionary *parentProperties;
@property (copy) NSDictionary *attributes;
@property (copy) NSArray *arguments;
@property (assign) BOOL timerNeedsUpdate;

@property (retain) NSTask *task;
@property (retain) NSTimer *timer;

- (id)initWithParentLog:(id)parent;
- (void)setupObservers;

// window management
- (void)setupLogWindowAndDisplay;
- (void)createWindow;
- (void)updateWindow;
- (void)killTimer;

// task
- (void)updateCommand:(NSTimer*)timer;
- (void)processNewDataFromTask:(NSNotification*)aNotification;

// updates
- (void)updateTimer;
- (void)updateTextAttributes;

// window operations
- (void)front;
- (void)setImage:(NSString*)urlStr;

// accessors
- (NSDictionary*)parentProperties;
- (NSRect)screenToRect:(NSRect)appleCoordRect;
- (NSRect)rect;
- (int)imageFit;
- (int)imageAlignment;
@end
