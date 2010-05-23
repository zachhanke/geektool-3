/*
 * NTDroppableTextField.m
 * NerdTool
 * Created by Kevin Nygaard on 7/21/09.
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
