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
    if ([properties boolForKey:@"wrap"]) [myParagraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
    else [myParagraphStyle setLineBreakMode:NSLineBreakByClipping];
    switch ([properties integerForKey:@"alignment"])
    {
        case ALIGN_LEFT: [myParagraphStyle setAlignment:NSLeftTextAlignment]; break;
        case ALIGN_CENTER: [myParagraphStyle setAlignment:NSCenterTextAlignment]; break;
        case ALIGN_RIGHT: [myParagraphStyle setAlignment:NSRightTextAlignment]; break;
        case ALIGN_JUSTIFIED: [myParagraphStyle setAlignment:NSJustifiedTextAlignment]; break;
    }
    
    NSFont *tmpFont = [NSFont fontWithName:[properties objectForKey:@"fontName"] size:[[properties objectForKey:@"fontSize"]floatValue]];   
    
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:myParagraphStyle,NSParagraphStyleAttributeName,tmpFont,NSFontAttributeName,[NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"textColor"]],NSForegroundColorAttributeName,[defShadow autorelease],NSShadowAttributeName,nil];
    
    [self setAttributes:attrs];
}

- (void)processAndSetText:(NSMutableString *)newString withEscapes:(BOOL)translateAsciiEscapes
{
    // kill \n's at the end of the string (to correct "push up" error on resizing)
    while ([newString length] && [newString characterAtIndex:[newString length] - 1] == 10) [newString deleteCharactersInRange:NSMakeRange([newString length] - 1,1)];
    
    if (translateAsciiEscapes)
    {
        ANSIEscapeHelper *ansiEscapeHelper = [[[ANSIEscapeHelper alloc]init]autorelease];
        NSMutableAttributedString *attrStr = [[ansiEscapeHelper attributedStringWithANSIEscapedString:newString]mutableCopy];
        
        // add in attributes (like font and alignment) to colored text
        for (NSString *key in attributes)
        {
            if ([key isEqualToString:NSForegroundColorAttributeName]) continue;
            [attrStr addAttribute:key value:[attributes valueForKey:key] range:NSMakeRange(0,[[attrStr string]length])];
        }
        [[self textStorage]setAttributedString:attrStr];
        [attrStr release];
    }
    else
    {
        [self setString:newString];
        [self applyAttributes:attributes];
    }    
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
