/*
 * LogTextField.m
 * NerdTool
 * Created by Kevin Nygaard
 * Copyright (c) 2010 MutableCode. All rights reserved.
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

#import "LogTextField.h"

#import "NTTextBasedLog.h"
#import "ANSIEscapeHelper.h"
#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"

#define ZeroRange NSMakeRange(NSNotFound, 0)

@implementation LogTextField

@synthesize attributes;
@synthesize parentLog;

- (void)awakeFromNib
{
    [self setEditable:NO];
    [self setSelectable:NO];
}

- (void)dealloc
{
    self.attributes = nil;
    [super dealloc];
}
#pragma mark Text Properties
- (void)applyAttributes:(NSDictionary *)attrs
{
    [[self textStorage] setAttributes:attrs range:NSMakeRange(0,[[self string] length])];
}

- (void)updateTextAttributesUsingProps
{
    NSShadow *defShadow = nil;
    if ([parentLog.textDropShadow boolValue])
    {
        defShadow = [[NSShadow alloc] init];
        [defShadow setShadowOffset:(NSSize){SHADOW_W,SHADOW_H}];
        [defShadow setShadowBlurRadius:SHADOW_RADIUS];
    }
    
    NSMutableParagraphStyle *myParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [myParagraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    if ([parentLog.wrap boolValue]) [myParagraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    else [myParagraphStyle setLineBreakMode:NSLineBreakByClipping];
    switch ([parentLog.alignment intValue])
    {
        case ALIGN_LEFT: [myParagraphStyle setAlignment:NSLeftTextAlignment]; break;
        case ALIGN_CENTER: [myParagraphStyle setAlignment:NSCenterTextAlignment]; break;
        case ALIGN_RIGHT: [myParagraphStyle setAlignment:NSRightTextAlignment]; break;
        case ALIGN_JUSTIFIED: [myParagraphStyle setAlignment:NSJustifiedTextAlignment]; break;
    }    
    self.attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                       myParagraphStyle,NSParagraphStyleAttributeName,
                       parentLog.font,NSFontAttributeName,
                       parentLog.textColor,NSForegroundColorAttributeName,
                       defShadow,NSShadowAttributeName,
                       nil];
    
    [myParagraphStyle release];
    [defShadow release];
    
}

- (void)processAndSetText:(NSMutableString *)newString withEscapes:(BOOL)translateAsciiEscapes andCustomColors:(NSDictionary*)customColors insert:(BOOL)insert
{
    // kill \n's at the end of the string (to correct "push up" error on resizing)
    if ([newString characterAtIndex:[newString length] - 1] == 10)
    {
        [newString deleteCharactersInRange:NSMakeRange([newString length] - 1,1)];
        if (insert && ![[self string] isEqualToString:@""]) [newString insertString:@"\n" atIndex:0];
    }
    
    if (translateAsciiEscapes)
    {
        ANSIEscapeHelper *ansiEscapeHelper = [[[ANSIEscapeHelper alloc] init] autorelease];
        [ansiEscapeHelper setAnsiColors:customColors];
        [ansiEscapeHelper setDefaultStringColor:[self.attributes valueForKey:NSForegroundColorAttributeName]];
        [ansiEscapeHelper setFont:[self.attributes valueForKey:NSFontAttributeName]];
        NSAttributedString *outputString = [self combineAttributes:self.attributes withAttributedString:[ansiEscapeHelper attributedStringWithANSIEscapedString:newString]];
        if (!insert || [[self string]isEqualToString:@""])
            [[self textStorage] setAttributedString:outputString];
        else
        {
            [self setEditable:YES];
            [self insertText:outputString];
            [self setEditable:NO];            
        }
    }
    else
    {
        if (!insert || [[self string] isEqualToString:@""])
            [self setString:newString];
        else
        {
            [self setEditable:YES];
            [self insertText:newString];
            [self setEditable:NO];            
        }
        
        [self applyAttributes:self.attributes];
    }    
}

- (NSAttributedString *)combineAttributes:(NSDictionary *)attrs withAttributedString:(NSAttributedString *)attributedString
{
    // add in attributes (like font and alignment) to colored text
    NSMutableAttributedString *attrStr = [[attributedString mutableCopy] autorelease];
    for (NSString *key in attrs)
    {
        // these are taken care of in ANSIEscapeHelper
        if ([key isEqualToString:NSForegroundColorAttributeName] || [key isEqualToString:NSFontAttributeName]) continue;
        [attrStr addAttribute:key value:[attrs valueForKey:key] range:NSMakeRange(0,[[attrStr string] length])];
    }
    return attrStr;
}

#pragma mark Text Actions
- (void)scrollEnd
{
    [self scrollRangeToVisible:NSMakeRange([[self string] length], 0)];
}

#pragma mark Attributes
- (BOOL)isOpaque
{
    return NO;
}

- (BOOL)shouldDrawInsertionPoint
{
    return NO;
}

- (BOOL)acceptsFirstResponder
{
    return NO;
}

- (BOOL)resignFirstResponder
{
    return NO;
}

- (BOOL)becomeFirstResponder
{
    return NO;
}

@end
