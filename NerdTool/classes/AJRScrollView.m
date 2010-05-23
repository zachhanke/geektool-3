/*
 * AJRScrollView.m
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

// TODO plug original developer

#import "AJRScrollView.h"
#import "LogTextField.h"

// Holds our text view. Turns out this class was taken from some Cocoa mailing list to work around a problem with displaying semi-transparency for scroll views pre-Jaguar. Background colors are now displayed through NSTextField instead of NSScroll/ClipView
@implementation AJRScrollView
- (BOOL)isOpaque
{
    return NO;
}

// This first line is necessary, the remainder isn't...
- (void)awakeFromNib
{
    [self setDocumentView:textView];
    [[self contentView]setCopiesOnScroll:NO];
    [[self contentView]setDrawsBackground:NO];
}

- (void)setBackgroundColor:(NSColor *)aColor
{
    [[self documentView]setBackgroundColor:aColor];
}

@end
