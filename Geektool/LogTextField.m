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
    if ([[self string] length] == 0) [self setString: @" "];
    
    NSRange range = NSMakeRange(0,[[self string]length]);
    NSTextStorage *textStorage = [self textStorage];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    if (wrap) [paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
    else [paragraphStyle setLineBreakMode:NSLineBreakByClipping];
    
    [textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
    //[self display];
}


#pragma mark Text Actions
- (void)scrollEnd
{
    [self scrollRangeToVisible:NSMakeRange(0,0)];
}

- (void)addText:(NSString*)newText clear:(BOOL)clear
{
    // TODO: I think here would be the place to add in colors
    NSMutableCharacterSet *cs = [[NSCharacterSet controlCharacterSet]mutableCopy];
    [cs removeCharactersInRange:NSMakeRange(10,1)]; // this is removing invisible characters I think
    
    NSMutableString *theText = [newText mutableCopy];
    NSRange r;
    while (!NSEqualRanges(r = [theText rangeOfCharacterFromSet:cs],ZeroRange))
        [theText deleteCharactersInRange:r];
    
    if (clear) [self setString:theText];
    else [self insertText:theText];
    
    [theText release];
    [cs release];
}

#pragma mark Shadow
- (void)drawRect:(NSRect)rect
{
    if (shadowText) [self showShadowHeight:2 radius:3 azimuth:135 ka:0];
    [super drawRect: rect];
    if (shadowText) [self hideShadow];
}

- (void)showShadowHeight:(int)height radius:(int)radius azimuth:(int)azimuth ka:(float)ka
{
    extern void *CGSReadObjectFromCString(char*);
    extern char *CGSUniqueCString(char*);
    extern void *CGSSetGStateAttribute(void*,char*,void*);
    void *graphicsPort;
    NSString *shadowValuesString = [NSString stringWithFormat: @"{Style = Shadow; Height = %d; Radius = %d; Azimuth = %d; Ka = %f;}",height,radius,azimuth,ka];

    [NSGraphicsContext saveGraphicsState];
    shadowValues = CGSReadObjectFromCString((char *) [shadowValuesString cString]);
    graphicsPort = [[NSGraphicsContext currentContext] graphicsPort];
    CGSSetGStateAttribute(graphicsPort, CGSUniqueCString("Style"), shadowValues);
}

- (void)hideShadow
{
    extern void *CGSReleaseGenericObj(void*);
    [NSGraphicsContext restoreGraphicsState];
    CGSReleaseGenericObj(shadowValues);
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
