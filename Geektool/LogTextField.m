//
//  LogTextField.m
//  GeekTool
//
//  Created by Yann Bizeul on Sun Feb 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "LogTextField.h"

@implementation LogTextField
- (void)awakeFromNib
{
    [self setEditable:NO];
    [self setSelectable:NO];
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

#pragma mark Shadow
- (void)drawRect: (NSRect) rect
{
    if (shadowText)
        [self showShadowHeight: 2 radius: 3 azimuth: 135 ka: 0 ];

    if (shadowText)
        [self hideShadow];
    [super drawRect: rect];
}

- (void)showShadowHeight: (int) height
                   radius: (int) radius
                  azimuth: (int) azimuth
                       ka: (float) ka
{
    extern void *CGSReadObjectFromCString(char*);
    extern char *CGSUniqueCString(char*);
    extern void *CGSSetGStateAttribute(void*,char*,void*);
    void *graphicsPort;
    NSString *shadowValuesString = [NSString stringWithFormat:
        @"{ Style = Shadow; Height = %d; Radius = %d; Azimuth = %d; Ka = %f; }",
        height, radius, azimuth, ka];

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

- (void)setShadowText:(bool)theShadow
{
    shadowText = theShadow;
}

@end
