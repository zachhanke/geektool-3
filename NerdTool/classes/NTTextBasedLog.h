/*
 * NTTextBasedLog.h
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

#import <Cocoa/Cocoa.h>
#import "NTLog.h"

@interface NTTextBasedLog : NTLog
{
    NSMutableString *lastRecievedString;
    NSAttributedString *colorTestString;
}

// Core Data Properties
@property (nonatomic, retain) NSNumber * alignment;
@property (nonatomic, retain) id backgroundColor;
@property (nonatomic, retain) id bgBlack;
@property (nonatomic, retain) id bgBlue;
@property (nonatomic, retain) id bgBrightBlack;
@property (nonatomic, retain) id bgBrightBlue;
@property (nonatomic, retain) id bgBrightCyan;
@property (nonatomic, retain) id bgBrightGreen;
@property (nonatomic, retain) id bgBrightMagenta;
@property (nonatomic, retain) id bgBrightRed;
@property (nonatomic, retain) id bgBrightWhite;
@property (nonatomic, retain) id bgBrightYellow;
@property (nonatomic, retain) id bgCyan;
@property (nonatomic, retain) id bgGreen;
@property (nonatomic, retain) id bgMagenta;
@property (nonatomic, retain) id bgRed;
@property (nonatomic, retain) id bgWhite;
@property (nonatomic, retain) id bgYellow;
@property (nonatomic, retain) id fgBlack;
@property (nonatomic, retain) id fgBlue;
@property (nonatomic, retain) id fgBrightBlack;
@property (nonatomic, retain) id fgBrightBlue;
@property (nonatomic, retain) id fgBrightCyan;
@property (nonatomic, retain) id fgBrightGreen;
@property (nonatomic, retain) id fgBrightMagenta;
@property (nonatomic, retain) id fgBrightRed;
@property (nonatomic, retain) id fgBrightWhite;
@property (nonatomic, retain) id fgBrightYellow;
@property (nonatomic, retain) id fgCyan;
@property (nonatomic, retain) id fgGreen;
@property (nonatomic, retain) id fgMagenta;
@property (nonatomic, retain) id fgRed;
@property (nonatomic, retain) id fgWhite;
@property (nonatomic, retain) id fgYellow;
@property (nonatomic, retain) id font;
@property (nonatomic, retain) NSNumber * stringEncoding;
@property (nonatomic, retain) id textColor;
@property (nonatomic, retain) NSNumber * textDropShadow;
@property (nonatomic, retain) NSNumber * useAsciiEscapes;
@property (nonatomic, retain) NSNumber * wrap;

// Standard properties
@property (retain) NSMutableString *lastRecievedString;
@property (copy) NSAttributedString *colorTestString;

- (void)awakeFromInsert;
- (void)setupPreferenceObservers;
- (void)removePreferenceObservers;
- (void)destroyLogProcess;
- (void)updateWindowIncludingTimer:(BOOL)updateTimer;
- (IBAction)attemptBestWindowSize:(id)sender;
// Custom ANSI Colors
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
- (NSArray*)colorNames;
- (NSDictionary*)customAnsiColors;
- (NSArray*)ansiFgColors;
- (NSArray*)ansiBgColors;
- (NSArray*)ansiBgBrightColors;
- (NSArray*)ansiFgBrightColors;

@end

@interface NTTextBasedLog (CoreDataGeneratedAccessors)
@end
