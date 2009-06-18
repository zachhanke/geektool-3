//
//  GroupController.m
//  GeektoolPreferencePane
//
//  Created by Kevin Nygaard on 3/17/09.
//  Copyright 2009 AllocInit. All rights reserved.
//

#import "GroupController.h"

@implementation GroupController

#pragma mark UI
- (IBAction)showGroupsCustomization:(id)sender
{
    [NSApp beginSheet: groupsSheet
       modalForWindow: [NSApp mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    [NSApp runModalForWindow: [NSApp mainWindow]];
    // Sheet is up here
    [NSApp endSheet: groupsSheet];
    [groupsSheet orderOut: self];
}

- (IBAction)groupsSheetClose:(id)sender
{
    // select only the first object in the list so we don't screw up making objects
    [self setSelectionIndex:[self selectionIndex]];
    
    // close the sheet and refresh our menu
    [NSApp stopModal];
}

#pragma mark Methods
- (IBAction)duplicateSelectedGroup:(id)sender
{
    // just in case this gets called with nothing selected...
    if ([self selectionIndex] != NSNotFound)
    {
        // copy the selection (potentially multiple items)
        NSArray *copyGroups = [[NSArray alloc]initWithArray:[self selectedObjects] copyItems:YES];

        NSMutableDictionary *tmpDictionary = nil;
        
        for (NTGroup *tmpGroup in copyGroups)
        {
            tmpDictionary = [tmpGroup properties];
            [[tmpGroup properties] setObject:[self duplicateCheck:[tmpDictionary objectForKey:@"name"]]
                                      forKey: @"name"];
        }
        
        // add our duplicate groups to the controller
        [self addObjects:copyGroups];
        
        [copyGroups release];
    }
}

#pragma mark Checks
- (NSString*)duplicateCheck:(NSString*)myGroupName
{
    // add a new group, but don't allow duplicates
    NSString *newGroupName = [NSString stringWithString: myGroupName];
    NSArray *splitName = [newGroupName componentsSeparatedByString:@" "];
    NSMutableArray *mutableSplitName = [splitName mutableCopy];
    
    BOOL needsCopy = YES;
    
    for (NSString *tmpString in mutableSplitName)
        if([tmpString isEqualToString: @"copy"]) needsCopy = NO;
    
    if (needsCopy) [mutableSplitName addObject:@"copy"];
    else
    {
        NSInteger count = [[mutableSplitName lastObject]integerValue];
        if (count != 0) [mutableSplitName removeLastObject];
        count++;
        [mutableSplitName addObject:[NSString stringWithFormat:@"%i",count]];
    }
    
    NSString *returnString = [mutableSplitName componentsJoinedByString:@" "]; 
    [mutableSplitName release];
    
    return returnString;
}

#pragma mark Convience
- (id)selectedObject
{
    int selectionIndex = [self selectionIndex];       
    if (selectionIndex != NSNotFound)
        return [[self selectedObjects] objectAtIndex:0];
    else
        return nil;
}
@end
