//
//  NTGroup.h
//  NerdTool
//
//  Created by Kevin Nygaard on 6/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Cocoa/Cocoa.h>

@class LogWindow;

@interface NTGroup : NSManagedObject 
{
    NSWindowController *windowController;
    LogWindow *mainWindow;
    
}

@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSNumber * groupID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSSet* logs;

- (void)reorder;

- (void)addLogsObject:(NSManagedObject *)value;
- (void)removeLogsObject:(NSManagedObject *)value;
- (void)addLogs:(NSSet *)value;
- (void)removeLogs:(NSSet *)value;

@end
