//
//  NTUtility.h
//  NerdTool
//
//  Created by Kevin Nygaard on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLog.h"
#import "LogProtocol.h"


@interface NTUtility : NTLog <LogProtocol> {
    IBOutlet id formattingString;
    IBOutlet id refresh;
    IBOutlet id printMode;
    int oldPrintMode;
    
}

@end
