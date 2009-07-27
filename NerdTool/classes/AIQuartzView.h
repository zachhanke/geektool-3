//
//  AIQuartzView.h
//  Geektool
//
//  Created by Kevin Nygaard on 5/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@interface AIQuartzView : QCView
{
    IBOutlet id parentWindow;
    BOOL render;
    BOOL unlock;
}
@property (assign) BOOL unlock;

- (void)requestRender;
@end
