//
//  NTWeb.h
//  NerdTool
//
//  Created by Kevin Nygaard on 7/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLog.h"

@interface NTWeb : NTLog
{
    IBOutlet id webURL;
    IBOutlet id refresh;
    BOOL highlighted;
}

@end
