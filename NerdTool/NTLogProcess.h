//
//  NTLogProcess.h
//  NerdTool
//
//  Created by Kevin Nygaard on 6/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GTLog;
@class LogWindowController;

@interface NTLogProcess : NSObject
{
    LogWindowController *windowController;
    NSDictionary *env;
    NSTask *task;
    NSTimer *timer;
    
    GTLog *parentLog;
    NSDictionary *parentProperties;
    NSDictionary *attributes;
    NSArray *arguments;
    BOOL timerNeedsUpdate;
}
@property (assign) LogWindowController *windowController;
@property (assign) GTLog *parentLog;
@property (assign) NSDictionary *parentProperties;
@property (copy) NSDictionary *attributes;
@property (copy) NSArray *arguments;
@property (assign) BOOL timerNeedsUpdate;

- (id)initWithParentLog:(id)parent;

// window management
- (void)setupLogWindowAndDisplay;
- (void)createWindow;
- (void)updateWindow;

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
- (int)NSImageFit;
- (int)NSPictureAlignment;
@end
