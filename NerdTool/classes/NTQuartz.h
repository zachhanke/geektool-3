//
//  NTQuartz.h
//  NerdTool
//
//  Created by Kevin Nygaard on 7/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLog.h"

@interface NTQuartz : NTLog
{
    IBOutlet id quartzFile;
    IBOutlet id refresh;
}
- (IBAction)fileChoose:(id)sender;

@end
