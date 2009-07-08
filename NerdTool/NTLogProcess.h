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
    
    BOOL timerRepeats;
    
    NSDictionary *env;
    NSTask *task;
    NSTimer *timer;
    
    GTLog *parentLog;
    NSDictionary *parentProperties;
    NSDictionary *attributes;
    NSArray *arguments;
    BOOL timerNeedsUpdate;
}
@property (assign) NSWindowController *windowController;
@property (assign) GTLog *parentLog;
@property (assign) NSDictionary *parentProperties;
@property (copy) NSDictionary *attributes;
@property (copy) NSArray *arguments;
@property (assign) BOOL timerNeedsUpdate;
@property (assign) LogWindow *window;

- (id)initWithParentLog:(id)parent;

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
- (NSRect)screenToRect:(NSRect)var;
- (NSRect)rect;
- (int)imageFit;
- (int)imageAlignment;
@end
