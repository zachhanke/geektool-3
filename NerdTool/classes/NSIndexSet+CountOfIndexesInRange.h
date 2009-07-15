//
//  NSIndexSet+CountOfIndexesInRange.h
//  NerdTool
//
//  Created by Kevin Nygaard on 6/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSIndexSet (CountOfIndexesInRange)
-(unsigned int)countOfIndexesInRange:(NSRange)range;
@end
