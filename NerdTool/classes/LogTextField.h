/*
 * LogTextField.h
 * NerdTool
 * Created by Kevin Nygaard
 * Copyright 2010 MutableCode. All rights reserved.
 *
 * Based on code by Yann Bizeul from Sun Feb 09 2003.
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

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface LogTextField : NSTextView
{
    NSDictionary *attributes;
}
@property (copy) NSDictionary *attributes;

- (void)awakeFromNib;
// Text Properties
- (void)applyAttributes:(NSDictionary *)attrs;
- (void)updateTextAttributesUsingProps:(NSDictionary *)properties;
- (void)processAndSetText:(NSMutableString *)newString withEscapes:(BOOL)translateAsciiEscapes andCustomColors:(NSDictionary*)customColors insert:(BOOL)insert;
- (NSAttributedString *)combineAttributes:(NSDictionary *)attrs withAttributedString:(NSAttributedString *)attributedString;
// Text Actions
- (void)scrollEnd;
// Attributes
- (BOOL)isOpaque;
- (BOOL)shouldDrawInsertionPoint;
- (BOOL)acceptsFirstResponder;
- (BOOL)resignFirstResponder;
- (BOOL)becomeFirstResponder;
@end
