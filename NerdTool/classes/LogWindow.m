/*
 * LogWindow.m
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

#import "LogWindow.h"
#import "NSWindow+StickyWindow.h"

#import <WebKit/WebKit.h>


@implementation LogWindow

@synthesize parentLog;

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:backingType defer:NO];
    if (self != nil)
    {
        [self setHighlighted:NO];
        [self setHasShadow:NO];
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [textView setEnabled:NO];
        [self setReleasedWhenClosed:YES];
    }
    return self;
}

// Custom windows that use the NSBorderlessWindowMask can't become key by default. Override this method so that controls in this window will be enabled.
// Works better with it off, since the key config window doesn't get stolen by the logs
- (BOOL)canBecomeKeyWindow
{
    return NO;
}

#pragma mark Window Properties
- (void)setHighlighted:(BOOL)flag
{
    [self setClickThrough:!flag];
    [logView setHighlighted:flag];
}

#pragma mark Text Properties
- (void)setTextColor:(NSColor*)color
{
    [textView setTextColor:color];
}

- (void)setTextBackgroundColor:(NSColor*)color
{
    [scrollView setBackgroundColor:color];
    [self setBackgroundColor:[NSColor clearColor]];
}

- (void)setTextRect:(NSRect)rect
{
    [scrollView setFrame:rect];
    [scrollView display];
}

#pragma mark Accessors
- (LogTextField*)textView
 {
    return textView;
}

- (NSImageView*)imageView
{
    return imageView;
}

- (AIQuartzView*)quartzView
{
    return quartzView;
}

- (WebView*)webView
{
    return webView;
}

- (id)scrollView
{
    return scrollView;
}

@end
