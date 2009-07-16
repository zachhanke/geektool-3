//
//  LogTextField.m
//  GeekTool
//
//  Created by Yann Bizeul on Sun Feb 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "LogTextField.h"
#import "defines.h"

#define ZeroRange NSMakeRange(NSNotFound, 0)

@implementation LogTextField

@synthesize shadowText;

- (void)awakeFromNib
{
    [self setEditable:NO];
    [self setSelectable:NO];
}

#pragma mark Text Properties
- (void)setTextAlignment:(int)alignment
{
    switch (alignment)
    {
        case ALIGN_LEFT: [self setAlignment:NSLeftTextAlignment]; break;
        case ALIGN_CENTER: [self setAlignment:NSCenterTextAlignment]; break;
        case ALIGN_RIGHT: [self setAlignment:NSRightTextAlignment]; break;
        case ALIGN_JUSTIFIED: [self setAlignment:NSJustifiedTextAlignment]; break;
    }
    //[self display];
}

- (void)setAttributes:(NSDictionary*)attributes
{
    [[self textStorage]setAttributes:attributes range:NSMakeRange(0,[[self string]length])];
}

- (void)setWrap:(BOOL)wrap
{
    if ([[self string]length] == 0) [self setString: @" "];
    
    NSRange range = NSMakeRange(0,[[self string]length]);
    NSTextStorage *textStorage = [self textStorage];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle]mutableCopy];
    
    if (wrap) [paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
    else [paragraphStyle setLineBreakMode:NSLineBreakByClipping];
    
    [textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
}


#pragma mark Text Actions
- (void)scrollEnd
{
    [self scrollRangeToVisible:NSMakeRange([[self string]length],0)];
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
