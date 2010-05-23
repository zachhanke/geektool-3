/*
 * LogProtocol.h
 * NerdTool
 * Created by Kevin Nygaard on 7/30/09.
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

