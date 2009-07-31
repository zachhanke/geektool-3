//
//  NTFile.h
//  NerdTool
//
//  Created by Kevin Nygaard on 7/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLog.h"
#import "LogProtocol.h"

@interface NTFile : NTLog <LogProtocol>
{
    IBOutlet id file;
}
- (void)configureLog;
- (IBAction)fileChoose:(id)sender;
@end
