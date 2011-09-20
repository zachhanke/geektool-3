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

enum printMode
{
    NTWaitForData = 0,
    NTAppendData,
    NTPrintOnlyNewData
};

@interface NTShell : NTLog <LogProtocol>
{
    IBOutlet id command;
    IBOutlet id refresh;
    IBOutlet id printMode;
    int oldPrintMode;
}
@end