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
- (id)initWithProperties:(NSDictionary*)initProperties andLogs:(NSArray*)initLogs;

// KVC
- (NSMutableDictionary *)properties;
- (void)setProperties:(NSDictionary *)newProperties;
- (NSMutableArray *)logs;
- (void)setLogs:(NSArray *)newLogs;

@end
