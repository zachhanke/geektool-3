/*
 * AIQuartzView.m
 * NerdTool
 * Created by Kevin Nygaard on 5/26/09.
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

#import "AIQuartzView.h"
#import "defines.h"

#import "LogWindow.h"


@implementation AIQuartzView

@synthesize unlock;

- (void)awakeFromNib
{
    render = FALSE;
    unlock = FALSE;
    
    // set this low because we don't want to spend too much time on the clock
    [self setMaxRenderingFrameRate:MAX_FRAMERATE];
    
    // redraw view if window is resized
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(requestRender) name:NSWindowDidResizeNotification object:parentWindow];
}

- (void)requestRender
{
    render = TRUE;
    if (![self isRendering]) [self startRendering];
}

- (BOOL)renderAtTime:(NSTimeInterval)time arguments:(NSDictionary*)arguments
{
    // render ONCE and only once
    BOOL success = FALSE;
    if (unlock || render) success = [super renderAtTime:time arguments:arguments];
    
    render = FALSE;
    
    return success;
}

@end
