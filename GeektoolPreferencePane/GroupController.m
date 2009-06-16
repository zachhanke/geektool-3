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
    // close the sheet and refresh our menu
    [NSApp stopModal];
}

#pragma mark Methods
- (IBAction)duplicateSelectedGroup:(id)sender
{
    // just in case this gets called with nothing selected...
    if ([self selectionIndex] != NSNotFound)
    {
        // get our selection (potentially multiple items)
        NSArray *selectedObjects = [self selectedObjects];
        NSEnumerator *e = [selectedObjects objectEnumerator];
       
        NSDictionary *currentGroup = nil;
        NSString *currentGroupString = nil;
        NSDictionary *newGroup = nil;
        NSString *newGroupString = nil;
        
        // loop for however many items in the set
        while (currentGroup = [e nextObject])
        {
            // grab the logs from g_logs
            currentGroupString = [currentGroup valueForKey:@"group"];
            
            // make our new objects for the duplicate object
            newGroup = [self duplicateCheck:currentGroupString];
            newGroupString = [newGroup valueForKey:@"group"];
            
            // all the logs we intend to duplicate
            NSMutableArray *origGroup = [[preferencesController g_logs]objectForKey:currentGroupString];
            NSEnumerator *f = [origGroup objectEnumerator];
            NSMutableArray *copyGroup = [NSMutableArray array];
            GTLog *origLog = nil;
            GTLog *copyLog = nil;

            // loop through all logs we wish to duplicate
            while (origLog = [f nextObject])
            {
                copyLog = [[GTLog alloc]initWithDictionary:[origLog dictionary]];
                [copyGroup addObject:copyLog];
            }
            
            // on that copy, change the groups of the logs
            [copyGroup makeObjectsPerformSelector:@selector(setGroup:) withObject:newGroupString];
            
            // put the array of objects back into g_logs under the duplicate name
            [[preferencesController g_logs] setObject:copyGroup forKey:newGroupString];
            
            // let us know about the new group too
            [self addObject:newGroup];
        }
    }
}

#pragma mark Checks
- (BOOL)groupExists:(NSString*)myGroupName
{
    return [[self content] containsObject:[NSDictionary dictionaryWithObject:myGroupName forKey:@"group"]];
}

// TODO: make more sophisticated like how finder does it
// folder -> folder copy -> folder copy 2 -> folder copy 3 -> ...
- (NSMutableDictionary*)duplicateCheck:(NSString*)myGroupName
{
    // add a new group, but don't allow duplicates
    NSString *newGroupName = [NSString stringWithString: myGroupName];
    if ([self groupExists: myGroupName])
    {
        int i = 2;
        while ([self groupExists: [NSString stringWithFormat: @"%@ %i", myGroupName,i]])
            i++;
        newGroupName = [NSString stringWithFormat: @"%@ %i", myGroupName,i];
    }
    //[[self content] addObject: [NSDictionary dictionaryWithObject:newGroupName forKey:@"group"]];
    return [NSMutableDictionary dictionaryWithObject:newGroupName forKey:@"group"];
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
