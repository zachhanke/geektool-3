//
//  NTGroup.h
//  NerdTool
//
//  Created by Kevin Nygaard on 6/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTGroup : NSObject <NSCoding, NSCopying, NSMutableCopying>
{
    NSMutableDictionary *properties;
    NSMutableArray *logs;
}
@property (retain) NSMutableDictionary *properties;
@property (retain) NSMutableArray *logs;

- (id)initWithProperties:(NSDictionary*)initProperties andLogs:(NSArray*)initLogs;
- (void)reorder;

@end
