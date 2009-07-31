//
//  NTImage.h
//  NerdTool
//
//  Created by Kevin Nygaard on 7/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLog.h"
#import "LogProtocol.h"

@interface NTImage : NTLog <LogProtocol>
{
    IBOutlet id refresh;
    IBOutlet id imageURL;
    IBOutlet id alignment;
    IBOutlet id opacity;
    IBOutlet id opacityText;
    IBOutlet id scaling;    
}

- (IBAction)fileChoose:(id)sender;
- (void)setImage:(NSString*)urlStr;
- (int)imageFit;
- (int)imageAlignment;
@end
