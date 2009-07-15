//
//  AIQuartzView.m
//  Geektool
//
//  Created by Kevin Nygaard on 5/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AIQuartzView.h"
#import "LogWindow.h"

#define MAX_FRAMERATE 1.0

@implementation AIQuartzView

- (void)awakeFromNib
{
    render = FALSE;
    
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
    if (render) success = [super renderAtTime:time arguments:arguments];
    
    render = FALSE;
    
    return success;
}

@end
