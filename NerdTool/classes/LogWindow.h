/*
 * LogWindow.h
 * NerdTool
 * Created by Kevin Nygaard on 6/17/09.
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

@class LogTextField;
@class NTLog;
@class AIQuartzView;
@class WebView;

@interface LogWindow : NSWindow
{
    IBOutlet id textView;
    IBOutlet id scrollView;
    IBOutlet id logView;
    IBOutlet id imageView;
    IBOutlet id quartzView;
    IBOutlet id webView;
    
    NTLog *parentLog;
}
@property (assign) NTLog *parentLog;

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag;
- (BOOL)canBecomeKeyWindow;
- (void)setHighlighted:(BOOL)flag;
- (void)setTextColor:(NSColor*)color;
- (void)setTextBackgroundColor:(NSColor*)color;
- (void)setTextRect:(NSRect)rect;
- (LogTextField*)textView;
- (NSImageView*)imageView;
- (AIQuartzView*)quartzView;
- (WebView*)webView;
@end
