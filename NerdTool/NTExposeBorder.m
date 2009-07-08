//
//  NTExposeBorder.m
//  NerdTool
//
//  Created by Kevin Nygaard on 7/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTExposeBorder.h"
#import "defines.h"

@implementation NTExposeBorder

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    NSRectFillUsingOperation(rect,NSCompositeClear);

    NSBezierPath *bp = [NSBezierPath bezierPathWithRect:[self bounds]];
    [[NSColor alternateSelectedControlColor] set];
    
    [bp setLineWidth:EXPOSE_WIDTH * 2];
    [bp stroke];
}

@end
