/*
 * NTRunOnly.m
 * NerdTool
 * Created by Kevin Nygaard on 7/20/09.
 * Copyright 2009 MutableCode. All rights reserved.
 *
 * This file is part of NerdTool.
 * 
 * NerdTool is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * NerdTool is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with NerdTool.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "NTRunOnly.h"
#import "NTGroup.h"

@implementation NTRunOnly

@synthesize activeGroup;

- (void)awakeFromNib
{
    [self loadDataFromDisk];
    
    // register for wake notifications
    [[[NSWorkspace sharedWorkspace]notificationCenter]addObserver:self selector:@selector(receiveWakeNote) name: NSWorkspaceDidWakeNotification object:NULL];
}

- (void)receiveWakeNote
{
    // refresh everything on wake
    [[activeGroup properties]setObject:[NSNumber numberWithBool:NO] forKey:@"active"];
    [[activeGroup properties]setObject:[NSNumber numberWithBool:YES] forKey:@"active"];
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
