//
//  NTRunOnly.m
//  NerdTool
//
//  Created by Kevin Nygaard on 7/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTRunOnly.h"
#import "NTGroup.h"

@implementation NTRunOnly

@synthesize activeGroup;

- (void)awakeFromNib
{
    [self loadDataFromDisk];
}

#pragma mark Loading
- (NSString *)pathForDataFile
{
    NSString *appSupportDir = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES) objectAtIndex:0]stringByAppendingPathComponent:@"NerdTool"];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:appSupportDir] == NO)
        [[NSFileManager defaultManager]createDirectoryAtPath:appSupportDir attributes:nil];
    
    return [appSupportDir stringByAppendingPathComponent:@"LogData.ntdata"];    
}

// if the resolution is changed, reload the active group
- (void)applicationDidChangeScreenParameters:(NSNotification *)aNotification
{
    [[activeGroup properties]setObject:[NSNumber numberWithBool:NO] forKey:@"active"];
    [[activeGroup properties]setObject:[NSNumber numberWithBool:YES] forKey:@"active"];
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    // cleanup processes
    [activeGroup release];
}  


- (void)loadDataFromDisk
{
    NSString *path = [self pathForDataFile];
    NSDictionary *rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    NSMutableArray *groupArray = [NSMutableArray arrayWithArray:[rootObject valueForKey:@"groups"]];

    for (NTGroup *tmp in groupArray)
        if ([[[tmp properties]objectForKey:@"active"]boolValue])
        {
            self.activeGroup = tmp;
            break;
        }
    
    [[activeGroup properties]setObject:[NSNumber numberWithBool:NO] forKey:@"active"];
    [[activeGroup properties]setObject:[NSNumber numberWithBool:YES] forKey:@"active"];
}


@end
