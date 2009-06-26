//
//  AIQuartzView.m
//  Geektool
//
//  Created by Kevin Nygaard on 5/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AIQuartzView.h"
#import "LogWindowController.h"


@implementation AIQuartzView

- (void)awakeFromNib
{
    render = FALSE;
    
    // set this low because we don't want to spend too much time on the clock
    [self setMaxRenderingFrameRate:1.0];
    
    // We register for some notifications
    [[NSDistributedNotificationCenter defaultCenter] addObserver: self
                                                        selector: @selector(flagUpdate:)
                                                            name: @"GTLogUpdate"
                                                          object: @"GeekTool"
                                              suspensionBehavior: NSNotificationSuspensionBehaviorCoalesce];
}

- (void)flagUpdate:(NSNotification*)aNotification
{
    // check to see if our log sent the notification
    // the ident is simply the refresh, as if two logs have the same refresh,
    // they are going to be refreshing at the same time.
    if ([owner ident] == [[[aNotification userInfo]objectForKey:@"ident"]intValue])
    {
        render = TRUE;
        if (![self isRendering]) [self startRendering];
    }
}

- (BOOL)renderAtTime:(NSTimeInterval)time arguments:(NSDictionary*)arguments
{
    // render ONCE and only once
    BOOL success = FALSE;
    if (render)
        success = [super renderAtTime:time arguments:arguments];
    
    render = FALSE;
    
    return success;
}

@end
