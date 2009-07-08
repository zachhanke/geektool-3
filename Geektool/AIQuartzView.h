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
    IBOutlet id owner;
    BOOL render;
}

- (void)requestRender;
@end
