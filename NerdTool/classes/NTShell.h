//
//  NTShell.h
//  NerdTool
//
//  Created by Kevin Nygaard on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLog.h"
#import "LogProtocol.h"

@interface NTShell : NTLog <LogProtocol>
{
    IBOutlet id command;
    IBOutlet id refresh;
}

@end