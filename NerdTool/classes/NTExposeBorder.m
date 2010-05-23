/*
 * NTExposeBorder.m
 * NerdTool
 * Created by Kevin Nygaard on 7/7/09.
 * Copyright 2009 MutableCode. All rights reserved.
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

#import "NTExposeBorder.h"
#import "defines.h"

@implementation NTExposeBorder

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
