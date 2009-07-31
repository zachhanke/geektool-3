//
//  NTQuartz.h
//  NerdTool
//
//  Created by Kevin Nygaard on 7/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLog.h"
#import "LogProtocol.h"

@interface NTQuartz : NTLog <LogProtocol>
{
    IBOutlet id quartzFile;
    IBOutlet id refresh;
    IBOutlet id framerateSlider;
    IBOutlet id framerateText;
}
- (void)configureLog;
- (IBAction)fileChoose:(id)sender;

@end
