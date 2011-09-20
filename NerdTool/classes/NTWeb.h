//
//  NTWeb.h
//  NerdTool
//
//  Created by Kevin Nygaard on 7/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLog.h"
#import "LogProtocol.h"

@interface NTWeb : NTLog <LogProtocol>
{
    IBOutlet id webURL;
    IBOutlet id refresh;
    IBOutlet id opacity;
    IBOutlet id opacityText;
    BOOL highlighted;
    BOOL needsScroll;
}
- (void)configureLog;
- (IBAction)setScrollLocation:(id)sender;

@end
