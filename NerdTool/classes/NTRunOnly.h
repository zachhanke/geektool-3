//
//  NTRunOnly.h
//  NerdTool
//
//  Created by Kevin Nygaard on 7/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTGroup;
@interface NTRunOnly : NSObject
{
    NTGroup *activeGroup;
}

@property (retain) NTGroup *activeGroup;

- (void)awakeFromNib;
- (NSString *)pathForDataFile;
- (void)loadDataFromDisk;

@end
