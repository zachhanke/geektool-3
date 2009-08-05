//
//  LogTextField.m
//  GeekTool
//
//  Created by Yann Bizeul on Sun Feb 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "LogTextField.h"

#import "ANSIEscapeHelper.h"
#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"

#define ZeroRange NSMakeRange(NSNotFound, 0)

@implementation LogTextField

@synthesize attributes;

- (void)awakeFromNib
{
    [self setEditable:NO];
    [self setSelectable:NO];
}

- (void)dealloc
{
    [attributes release];
    [super dealloc];
}

#pragma mark Text Properties
- (void)applyAttributes:(NSDictionary *)attrs
{
    [[self textStorage]setAttributes:attrs range:NSMakeRange(0,[[self string]length])];
}

- (void)updateTextAttributesUsingProps:(NSDictionary *)properties
{
    NSShadow *defShadow = nil;
    if ([properties boolForKey:@"shadowText"])
    {
        defShadow = [[NSShadow alloc]init];
        [defShadow setShadowOffset:(NSSize){SHADOW_W,SHADOW_H}];
        [defShadow setShadowBlurRadius:SHADOW_RADIUS];
    }
    
    NSMutableParagraphStyle *myParagraphStyle = [[NSMutableParagraphStyle alloc]init];
    [myParagraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    if ([properties boolForKey:@"wrap"]) [myParagraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    else [myParagraphStyle setLineBreakMode:NSLineBreakByClipping];
    switch ([properties integerForKey:@"alignment"])
    {
        case ALIGN_LEFT: [myParagraphStyle setAlignment:NSLeftTextAlignment]; break;
        case ALIGN_CENTER: [myParagraphStyle setAlignment:NSCenterTextAlignment]; break;
        case ALIGN_RIGHT: [myParagraphStyle setAlignment:NSRightTextAlignment]; break;
        case ALIGN_JUSTIFIED: [myParagraphStyle setAlignment:NSJustifiedTextAlignment]; break;
    }
    
    NSFont *tmpFont = [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"font"]];
    
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:myParagraphStyle,NSParagraphStyleAttributeName,tmpFont,NSFontAttributeName,[NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"textColor"]],NSForegroundColorAttributeName,defShadow,NSShadowAttributeName,nil];
    
    [self setAttributes:attrs];
    
    [myParagraphStyle release];
    [defShadow release];
    
}

- (void)processAndSetText:(NSMutableString *)newString withEscapes:(BOOL)translateAsciiEscapes andCustomColors:(NSDictionary*)customColors insert:(BOOL)insert
{
    // kill \n's at the end of the string (to correct "push up" error on resizing)
    if (!insert)
        while ([newString length] && [newString characterAtIndex:[newString length] - 1] == 10) [newString deleteCharactersInRange:NSMakeRange([newString length] - 1,1)];
    
    if (translateAsciiEscapes)
    {
        ANSIEscapeHelper *ansiEscapeHelper = [[[ANSIEscapeHelper alloc]init]autorelease];
        [ansiEscapeHelper setAnsiColors:customColors];
        [ansiEscapeHelper setDefaultStringColor:[attributes valueForKey:NSForegroundColorAttributeName]];
        [ansiEscapeHelper setFont:[attributes valueForKey:NSFontAttributeName]];
        NSAttributedString *outputString = [self combineAttributes:attributes withAttributedString:[ansiEscapeHelper attributedStringWithANSIEscapedString:newString]];
        if (!insert)
            [[self textStorage]setAttributedString:outputString];
        else
        {
            [self setEditable:YES];
            [self insertText:outputString];
            [self setEditable:NO];            
        }
    }
    else
    {
        if (!insert)
            [self setString:newString];
        else
        {
            [self setEditable:YES];
            [self insertText:newString];
            [self setEditable:NO];            
        }
        
        [self applyAttributes:attributes];
    }    
}

- (NSAttributedString *)combineAttributes:(NSDictionary *)attrs withAttributedString:(NSAttributedString *)attributedString
{
    // add in attributes (like font and alignment) to colored text
    NSMutableAttributedString *attrStr = [[attributedString mutableCopy]autorelease];
    for (NSString *key in attrs)
    {
        // these are taken care of in ANSIEscapeHelper
        if ([key isEqualToString:NSForegroundColorAttributeName] || [key isEqualToString:NSFontAttributeName]) continue;
        [attrStr addAttribute:key value:[attrs valueForKey:key] range:NSMakeRange(0,[[attrStr string]length])];
    }
    return attrStr;
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
