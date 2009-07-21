//
//  NTFile.h
//  NerdTool
//
//  Created by Kevin Nygaard on 7/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLog.h"

@interface NTFile : NTLog
{
    IBOutlet id file;
}
- (IBAction)fileChoose:(id)sender;
@end
