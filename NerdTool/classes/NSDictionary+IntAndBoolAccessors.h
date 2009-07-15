//
//  NSDictionary+IntAndBoolAccessors.h
//  NerdTool
//
//  Created by Kevin Nygaard on 6/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSDictionary (IntAndBoolAccessors)
- (int)integerForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
@end
