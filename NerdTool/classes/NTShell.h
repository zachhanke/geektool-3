//
//  NTShell.h
//  NerdTool
//
//  Created by Kevin Nygaard on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLog.h"

@interface NTShell : NTLog
{
    IBOutlet id command;
    IBOutlet id refresh;
}

@end