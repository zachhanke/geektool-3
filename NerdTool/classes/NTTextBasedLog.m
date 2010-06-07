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
#import "defines.h"
#import "NS(Attributed)String+Geometrics.h"

#import "LogWindow.h"
#import "LogTextField.h"
#import "ANSIEscapeHelper.h"


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

// Standard properties
@synthesize lastRecievedString;
@synthesize colorTestString;

- (void)awakeFromFetch
{
    [super awakeFromFetch];
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    
    // Standard properties
    self.lastRecievedString = nil;
    
    // Set some defaults that we can't set in our CoreData model
    self.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    self.textColor = kDefaultFgColor;
    self.backgroundColor = kDefaultBgColor;    
    self.bgBlack = kDefaultANSIColorBgBlack;
    self.bgBlue = kDefaultANSIColorBgBlue;
    self.bgCyan = kDefaultANSIColorBgCyan;
    self.bgGreen = kDefaultANSIColorBgGreen;
    self.bgMagenta = kDefaultANSIColorBgMagenta;
    self.bgRed = kDefaultANSIColorBgRed;
    self.bgWhite = kDefaultANSIColorBgWhite;
    self.bgYellow = kDefaultANSIColorBgYellow;
    self.fgBlack = kDefaultANSIColorFgBlack;
    self.fgBlue = kDefaultANSIColorFgBlue;
    self.fgCyan = kDefaultANSIColorFgCyan;
    self.fgGreen = kDefaultANSIColorFgGreen;
    self.fgMagenta = kDefaultANSIColorFgMagenta;
    self.fgRed = kDefaultANSIColorFgRed;
    self.fgWhite = kDefaultANSIColorFgWhite;
    self.fgYellow = kDefaultANSIColorFgYellow;
    self.bgBrightBlack = kDefaultANSIColorBgBrightBlack;
    self.bgBrightBlue = kDefaultANSIColorBgBrightBlue;
    self.bgBrightCyan = kDefaultANSIColorBgBrightCyan;
    self.bgBrightGreen = kDefaultANSIColorBgBrightGreen;
    self.bgBrightMagenta = kDefaultANSIColorBgBrightMagenta;
    self.bgBrightRed = kDefaultANSIColorBgBrightRed;
    self.bgBrightWhite = kDefaultANSIColorBgBrightWhite;
    self.bgBrightYellow = kDefaultANSIColorBgBrightYellow;
    self.fgBrightBlack = kDefaultANSIColorFgBrightBlack;
    self.fgBrightBlue = kDefaultANSIColorFgBrightBlue;
    self.fgBrightCyan = kDefaultANSIColorFgBrightCyan;
    self.fgBrightGreen = kDefaultANSIColorFgBrightGreen;
    self.fgBrightMagenta = kDefaultANSIColorFgBrightMagenta;
    self.fgBrightRed = kDefaultANSIColorFgBrightRed;
    self.fgBrightWhite = kDefaultANSIColorFgBrightWhite;
    self.fgBrightYellow = kDefaultANSIColorFgBrightYellow;     
}

- (void)setupPreferenceObservers
{
    [super setupPreferenceObservers];
    
    [self updatePreviewText];
    
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
}

- (void)removePreferenceObservers
{
    [super removePreferenceObservers];
    
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
}

- (void)destroyLogProcess
{
    self.lastRecievedString = nil;
    
    [super destroyLogProcess];
}

- (void)updateWindowIncludingTimer:(BOOL)updateTimer
{
    [super updateWindowIncludingTimer:updateTimer];
    
    // text setup
    NSRect tmpRect = [self rect];
    tmpRect.origin = NSZeroPoint;
    
    [self.window setTextRect:tmpRect]; 
    [self.window setTextBackgroundColor:self.backgroundColor];
    
    // text presentation
    [[self.window textView] setParentLog:self];
    [[self.window textView] updateTextAttributesUsingProps];
    
    if (![self.useAsciiEscapes boolValue] || !lastRecievedString) [[window textView] applyAttributes:[[window textView] attributes]];
    else [[window textView] processAndSetText:lastRecievedString withEscapes:YES andCustomColors:[self customAnsiColors] insert:NO];
}    

- (IBAction)attemptBestWindowSize:(id)sender
{
    NSSize bestFit = [[[window textView] attributedString] sizeForWidth:(([self.wrap boolValue]) ? NSWidth([window frame]) : FLT_MAX) height:FLT_MAX];
    [window setContentSize:bestFit];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResizeNotification object:window];
    [window displayIfNeeded];
}

#pragma mark Custom ANSI Colors
- (void)updatePreviewText
{
    NSString *testString = @"TEST";
    NSNumber *boldness = [NSNumber numberWithFloat:-5.0];
    float size = 32.0;
    NSFont *displayFont = [NSFont fontWithName:@"Helvetica" size:size];
    BOOL firstTime = YES;
    
    NSMutableAttributedString *stringToPrint = [[[NSMutableAttributedString alloc] init] autorelease];
    for (NSColor *bgColor in self.ansiBgColors)
    {
        if (!firstTime)
        {
            firstTime = NO;
            [stringToPrint appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
        }

        for (NSColor *fgColor in self.ansiFgColors)
        {
            NSDictionary *normAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                       fgColor,NSForegroundColorAttributeName,
                                       bgColor,NSBackgroundColorAttributeName,
                                       boldness,NSStrokeWidthAttributeName,
                                       displayFont,NSFontAttributeName,
                                       nil];
            
            NSAttributedString *normString = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",testString] attributes:normAttrs] autorelease];

            [stringToPrint appendAttributedString:normString];
        }
        
        [stringToPrint appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];

        for (NSColor *fgBrightColor in self.ansiFgBrightColors)
        {
            NSDictionary *brightAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                       fgBrightColor,NSForegroundColorAttributeName,
                                       bgColor,NSBackgroundColorAttributeName,
                                       boldness,NSStrokeWidthAttributeName,
                                       displayFont,NSFontAttributeName,
                                       nil];
            
            NSAttributedString *brightString = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",testString] attributes:brightAttrs] autorelease];
            
            [stringToPrint appendAttributedString:brightString];
        }
    }
    self.colorTestString = stringToPrint;
}

- (NSArray*)colorNames
{
    return [NSArray arrayWithObjects:@"fgBlack",
            @"fgRed",
            @"fgGreen",
            @"fgYellow",
            @"fgBlue",
            @"fgMagenta",
            @"fgCyan",
            @"fgWhite",
            @"bgBlack",
            @"bgRed",
            @"bgGreen",
            @"bgYellow",
            @"bgBlue",
            @"bgMagenta",
            @"bgCyan",
            @"bgWhite",
            @"fgBrightBlack",
            @"fgBrightRed",
            @"fgBrightGreen",
            @"fgBrightYellow",
            @"fgBrightBlue",
            @"fgBrightMagenta",
            @"fgBrightCyan",
            @"fgBrightWhite",
            @"bgBrightBlack",
            @"bgBrightRed",
            @"bgBrightGreen",
            @"bgBrightYellow",
            @"bgBrightBlue",
            @"bgBrightMagenta",
            @"bgBrightCyan",
            @"bgBrightWhite",
            nil];
    
}

- (NSDictionary*)customAnsiColors
{
    NSDictionary *colors = [[NSDictionary alloc] initWithObjectsAndKeys:
                            self.fgBlack, [NSNumber numberWithInt:SGRCodeFgBlack],
                            self.fgRed, [NSNumber numberWithInt:SGRCodeFgRed],
                            self.fgGreen, [NSNumber numberWithInt:SGRCodeFgGreen],
                            self.fgYellow, [NSNumber numberWithInt:SGRCodeFgYellow],
                            self.fgBlue, [NSNumber numberWithInt:SGRCodeFgBlue],
                            self.fgMagenta, [NSNumber numberWithInt:SGRCodeFgMagenta],
                            self.fgCyan, [NSNumber numberWithInt:SGRCodeFgCyan],
                            self.fgWhite, [NSNumber numberWithInt:SGRCodeFgWhite],
                            self.bgBlack, [NSNumber numberWithInt:SGRCodeBgBlack],
                            self.bgRed, [NSNumber numberWithInt:SGRCodeBgRed],
                            self.bgGreen, [NSNumber numberWithInt:SGRCodeBgGreen],
                            self.bgYellow, [NSNumber numberWithInt:SGRCodeBgYellow],
                            self.bgBlue, [NSNumber numberWithInt:SGRCodeBgBlue],
                            self.bgMagenta, [NSNumber numberWithInt:SGRCodeBgMagenta],
                            self.bgCyan, [NSNumber numberWithInt:SGRCodeBgCyan],
                            self.bgWhite, [NSNumber numberWithInt:SGRCodeBgWhite],
                            self.fgBrightBlack, [NSNumber numberWithInt:SGRCodeFgBrightBlack],
                            self.fgBrightRed, [NSNumber numberWithInt:SGRCodeFgBrightRed],
                            self.fgBrightGreen, [NSNumber numberWithInt:SGRCodeFgBrightGreen],
                            self.fgBrightYellow, [NSNumber numberWithInt:SGRCodeFgBrightYellow],
                            self.fgBrightBlue, [NSNumber numberWithInt:SGRCodeFgBrightBlue],
                            self.fgBrightMagenta, [NSNumber numberWithInt:SGRCodeFgBrightMagenta],
                            self.fgBrightCyan, [NSNumber numberWithInt:SGRCodeFgBrightCyan],
                            self.fgBrightWhite, [NSNumber numberWithInt:SGRCodeFgBrightWhite],
                            self.bgBrightBlack, [NSNumber numberWithInt:SGRCodeBgBrightBlack],
                            self.bgBrightRed, [NSNumber numberWithInt:SGRCodeBgBrightRed],
                            self.bgBrightGreen, [NSNumber numberWithInt:SGRCodeBgBrightGreen],
                            self.bgBrightYellow, [NSNumber numberWithInt:SGRCodeBgBrightYellow],
                            self.bgBrightBlue, [NSNumber numberWithInt:SGRCodeBgBrightBlue],
                            self.bgBrightMagenta, [NSNumber numberWithInt:SGRCodeBgBrightMagenta],
                            self.bgBrightCyan, [NSNumber numberWithInt:SGRCodeBgBrightCyan],
                            self.bgBrightWhite, [NSNumber numberWithInt:SGRCodeBgBrightWhite],
                            nil];
    return [colors autorelease];
    
}

- (NSArray*)ansiFgColors
{
    return [NSArray arrayWithObjects:
            self.fgBlack,
            self.fgRed,
            self.fgGreen,
            self.fgYellow,
            self.fgBlue,
            self.fgMagenta,
            self.fgCyan,
            self.fgWhite,
            nil];    
}

- (NSArray*)ansiBgColors
{
    return [NSArray arrayWithObjects:
            self.bgBlack,
            self.bgRed,
            self.bgGreen,
            self.bgYellow,
            self.bgBlue,
            self.bgMagenta,
            self.bgCyan,
            self.bgWhite,
            nil];
}

- (NSArray*)ansiBgBrightColors
{
    return [NSArray arrayWithObjects:
            self.bgBrightBlack,
            self.bgBrightRed,
            self.bgBrightGreen,
            self.bgBrightYellow,
            self.bgBrightBlue,
            self.bgBrightMagenta,
            self.bgBrightCyan,
            self.bgBrightWhite,
            nil];    
}

- (NSArray*)ansiFgBrightColors
{
    return [NSArray arrayWithObjects:
            self.fgBrightBlack,
            self.fgBrightRed,
            self.fgBrightGreen,
            self.fgBrightYellow,
            self.fgBrightBlue,
            self.fgBrightMagenta,
            self.fgBrightCyan,
            self.fgBrightWhite,
            nil];    
}

@end