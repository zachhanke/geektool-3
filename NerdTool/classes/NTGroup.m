//
//  NTGroup.m
//  NerdTool
//
//  Created by Kevin Nygaard on 6/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTGroup.h"
#import "NTLog.h"
#import "LogWindow.h"

#import "NSDictionary+IntAndBoolAccessors.h"

// Organizes and holds instantiated GTLogs
@implementation NTGroup

@dynamic active;
@dynamic groupID;
@dynamic name;
@dynamic order;
@dynamic logs;

- (void)reorder
{
    for (NTLog *log in self.logs) if (log.enabled) [log back];
}

#pragma mark Observing
// properties.active is changed by GroupController
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"active"])
    {
        if (![self.logs count]) return;
        
        [self.logs makeObjectsPerformSelector:@selector(setActive:) withObject:[NSNumber numberWithBool:[[change valueForKey:NSKeyValueChangeNewKey]boolValue]]];
        [self reorder];
    }
}

- (void)setupCanvas
{
    mainWindow = [[LogWindow alloc] initWithContentRect:<#(NSRect)contentRect#> styleMask:<#(unsigned int)styleMask#> backing:<#(NSBackingStoreType)backingType#> defer:<#(BOOL)flag#>
    [[NSWindowController alloc]initWithWindow:];
}
@end
