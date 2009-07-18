/*
 *  NTLogProtocol.h
 *  NerdTool
 *
 *  Created by Kevin Nygaard on 7/16/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class LogWindow;
@class NTGroup;

@protocol NTLogProtocol

@property (assign) BOOL timerNeedsUpdate;
@property (copy) NSNumber *active;
@property (assign) NTGroup *parentGroup;

- (id)init;
- (void)setupLogWindowAndDisplay;
- (void)updateWindow;
- (void)killTimer;
- (void)front;
- (LogWindow *)window;
- (BOOL)needsDisplayUIBox;
- (NSView *)loadPrefsViewAndBind:(id)bindee;
- (NSView *)unloadPrefsViewAndUnbind;

@end