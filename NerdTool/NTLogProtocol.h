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

// Holds the preferences for your log
@property (retain) NSMutableDictionary *properties;
// Where you are contained.
@property (assign) NTGroup *parentGroup;
// active is for you to know your group is selected
@property (copy) NSNumber *active;

// Return an initialized log with the defaults loaded into properties.
- (id)init;
- (void)setupLogWindowAndDisplay;
- (void)updateWindow;
- (void)killTimer;
// Bring the log window to the front
- (void)front;
// This window holds the visual representation of the log.
- (LogWindow *)window;
// When the log is selected, this will be called. Tell your window to highlight and enable/disable your resize/move/visualizations controls.
- (void)setHighlighted:(BOOL)val from:(id)sender;
// Returning NO disables the Display box in the UI
- (BOOL)needsDisplayUIBox;
// Return the view containing the log's specific preferences, and also set up bindings you need for those. bindee will be a log controller.
- (NSView *)loadPrefsViewAndBind:(id)bindee;
// Return the view containing the log's specific preferences, and also destroy the bindings you set up in the loadPrefsViewAndBind: function. bindee will be a log controller.
- (NSView *)unloadPrefsViewAndUnbind;

@end