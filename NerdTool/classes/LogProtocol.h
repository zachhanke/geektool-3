/*
 *  LogProtocol.h
 *  NerdTool
 *
 *  Created by Kevin Nygaard on 7/30/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

@protocol LogProtocol

// Initializes log with defaults.
- (id)init;

// Is TRUE if containing group is active.
//@property (copy) NSNumber *active;
- (void)setActive:(NSNumber*)var;
- (NSNumber*)active;

// Highlights log window. Sender is passed so that the log can recall the sending method if the log window was not instantiated at that time.
- (void)setHighlighted:(BOOL)val from:(id)sender;

// Brings log window to front
- (void)front;

// Sets up/destroys bindings for preferences and returns custom view to be put into the main UI.
- (NSView *)loadPrefsViewAndBind:(id)bindee;
- (NSView *)unloadPrefsViewAndUnbind;
@end

