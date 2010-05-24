/*
 * NTTextBasedLog.m
 * NerdTool
 * Created by Kevin Nygaard on 5/22/10.
 * Copyright 2010 MutableCode. All rights reserved.
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

#import "NTTextBasedLog.h"
#import "LogWindow.h"
#import "LogTextField.h"

@implementation NTTextBasedLog

// Core Data Properties
@dynamic alignment;
@dynamic backgroundColor;
@dynamic bgBlack;
@dynamic bgBlue;
@dynamic bgBrightBlack;
@dynamic bgBrightBlue;
@dynamic bgBrightCyan;
@dynamic bgBrightGreen;
@dynamic bgBrightMagenta;
@dynamic bgBrightRed;
@dynamic bgBrightWhite;
@dynamic bgBrightYellow;
@dynamic bgCyan;
@dynamic bgGreen;
@dynamic bgMagenta;
@dynamic bgRed;
@dynamic bgWhite;
@dynamic bgYellow;
@dynamic fgBlack;
@dynamic fgBlue;
@dynamic fgBrightBlack;
@dynamic fgBrightBlue;
@dynamic fgBrightCyan;
@dynamic fgBrightGreen;
@dynamic fgBrightMagenta;
@dynamic fgBrightRed;
@dynamic fgBrightWhite;
@dynamic fgBrightYellow;
@dynamic fgCyan;
@dynamic fgGreen;
@dynamic fgMagenta;
@dynamic fgRed;
@dynamic fgWhite;
@dynamic fgYellow;
@dynamic font;
@dynamic stringEncoding;
@dynamic textColor;
@dynamic textDropShadow;
@dynamic useAsciiEscapes;
@dynamic wrap;

- (void)setupPreferenceObservers
{
    [self addObserver:self forKeyPath:@"font" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"stringEncoding" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"textColor" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"backgroundColor" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"wrap" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"alignment" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"textDropShadow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"useAsciiEscapes" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBlack" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgRed" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgGreen" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgYellow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBlue" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgMagenta" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgCyan" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgWhite" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBlack" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgRed" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgGreen" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgYellow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBlue" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgMagenta" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgCyan" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgWhite" options:0 context:NULL];    
    [self addObserver:self forKeyPath:@"fgBrightBlack" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightRed" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightGreen" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightYellow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightBlue" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightMagenta" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightCyan" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightWhite" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightBlack" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightRed" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightGreen" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightYellow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightBlue" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightMagenta" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightCyan" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightWhite" options:0 context:NULL];    
    
    [super setupPreferenceObservers];
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"font"];
    [self removeObserver:self forKeyPath:@"stringEncoding"];
    [self removeObserver:self forKeyPath:@"textColor"];
    [self removeObserver:self forKeyPath:@"backgroundColor"];
    [self removeObserver:self forKeyPath:@"wrap"];
    [self removeObserver:self forKeyPath:@"alignment"];
    [self removeObserver:self forKeyPath:@"textDropShadow"];
    [self removeObserver:self forKeyPath:@"useAsciiEscapes"];
    [self removeObserver:self forKeyPath:@"fgBlack"];
    [self removeObserver:self forKeyPath:@"fgRed"];
    [self removeObserver:self forKeyPath:@"fgGreen"];
    [self removeObserver:self forKeyPath:@"fgYellow"];
    [self removeObserver:self forKeyPath:@"fgBlue"];
    [self removeObserver:self forKeyPath:@"fgMagenta"];
    [self removeObserver:self forKeyPath:@"fgCyan"];
    [self removeObserver:self forKeyPath:@"fgWhite"];
    [self removeObserver:self forKeyPath:@"bgBlack"];
    [self removeObserver:self forKeyPath:@"bgRed"];
    [self removeObserver:self forKeyPath:@"bgGreen"];
    [self removeObserver:self forKeyPath:@"bgYellow"];
    [self removeObserver:self forKeyPath:@"bgBlue"];
    [self removeObserver:self forKeyPath:@"bgMagenta"];
    [self removeObserver:self forKeyPath:@"bgCyan"];
    [self removeObserver:self forKeyPath:@"bgWhite"];    
    [self removeObserver:self forKeyPath:@"fgBrightBlack"];
    [self removeObserver:self forKeyPath:@"fgBrightRed"];
    [self removeObserver:self forKeyPath:@"fgBrightGreen"];
    [self removeObserver:self forKeyPath:@"fgBrightYellow"];
    [self removeObserver:self forKeyPath:@"fgBrightBlue"];
    [self removeObserver:self forKeyPath:@"fgBrightMagenta"];
    [self removeObserver:self forKeyPath:@"fgBrightCyan"];
    [self removeObserver:self forKeyPath:@"fgBrightWhite"];
    [self removeObserver:self forKeyPath:@"bgBrightBlack"];
    [self removeObserver:self forKeyPath:@"bgBrightRed"];
    [self removeObserver:self forKeyPath:@"bgBrightGreen"];
    [self removeObserver:self forKeyPath:@"bgBrightYellow"];
    [self removeObserver:self forKeyPath:@"bgBrightBlue"];
    [self removeObserver:self forKeyPath:@"bgBrightMagenta"];
    [self removeObserver:self forKeyPath:@"bgBrightCyan"];
    [self removeObserver:self forKeyPath:@"bgBrightWhite"];    
    
    [super removePreferenceObservers];
}

- (void)updateWindowIncludingTimer:(BOOL)updateTimer
{
    // super is called first, as it sets up stuff dealing with rect
    [super updateWindowIncludingTimer:updateTimer];
    
    // Configure text based things
    NSRect tmpRect = [self rect];
    tmpRect.origin = NSZeroPoint;
    
    [self.window setTextRect:tmpRect]; 
    [self.window setTextBackgroundColor:self.backgroundColor];
    [[self.window textView] updateTextAttributesUsingProps:properties];
    
    if (![self.useAsciiEscapes boolValue] || !lastRecievedString) [[window textView] applyAttributes:[[window textView] attributes]];
    else [[window textView] processAndSetText:lastRecievedString withEscapes:YES andCustomColors:[self customAnsiColors] insert:NO];
}    

@end
