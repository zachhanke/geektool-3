//
//  NTDroppableTextField.m
//  NerdTool
//
//  Created by Kevin Nygaard on 7/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTDroppableTextField.h"

@implementation NTDroppableTextField

- (void)awakeFromNib
{
    if ([[[self delegate]logTypeName]isEqualToString:@"File"] || [[[self delegate]logTypeName]isEqualToString:@"Quartz"])
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,nil]];
    else if ([[[self delegate]logTypeName]isEqualToString:@"Image"])
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,nil]];

}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ([[pboard types]containsObject:NSFilenamesPboardType])
    {
        if (sourceDragMask & NSDragOperationLink)
            return NSDragOperationLink;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender 
{
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ([[pboard types]containsObject:NSFilenamesPboardType]) 
    {
        NSString *file = [[pboard propertyListForType:NSFilenamesPboardType]objectAtIndex:0];

        if (sourceDragMask & NSDragOperationLink)
        {
            if ([[[self delegate]logTypeName]isEqualToString:@"File"] || [[[self delegate]logTypeName]isEqualToString:@"Quartz"])
                [[[self delegate]properties]setObject:file forKey:@"file"];
            else if ([[[self delegate]logTypeName]isEqualToString:@"Image"])
                [[[self delegate]properties]setObject:[[NSURL fileURLWithPath:file]absoluteString] forKey:@"imageURL"];
        }
    }
    return YES;
}


@end
