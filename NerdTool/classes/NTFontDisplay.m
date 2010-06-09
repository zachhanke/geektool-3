/*
 * NTFontDisplay.m
 * NerdTool
 * Created by Kevin Nygaard on 7/13/09.
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

#import "NTFontDisplay.h"
#import "defines.h"

#import "NTGroup.h"
#import "NTLog.h"
#import "NTTextBasedLog.h"

@implementation NTFontDisplay
- (BOOL)isOpaque
{
    return NO;
}

- (void)drawRect:(NSRect)rect
{   
    NSFont *font = [NSFont systemFontOfSize:20.0];
    NSColor *backgroundColor = [NSColor blackColor];
    NSColor *textColor = [NSColor whiteColor];
    NSShadow *defShadow = nil;    
    NSString *stringToPrint = [NSString stringWithString:NSLocalizedString(@"No Selection",nil)];
    
    BOOL printLabel = NO;
    id firstItem = nil;
    
    BOOL uniformFont = YES;
    BOOL uniformShadow = YES;
    BOOL uniformTextColor = YES;
    BOOL uniformBackgroundColor = YES;
    
    // do we have something selected?
    if ([[treeController selectedObjects] count])
    {
        printLabel = YES;
        firstItem = [[treeController selectedObjects] objectAtIndex:0];
    }
    
    // pulling attributes from selection and handling multiple selections 
    for (NTTreeNode *item in [treeController selectedObjects])
    {
        // have we selected a group?
        if ([item isKindOfClass:[NTGroup class]])
        {
            stringToPrint = [NSString stringWithString:NSLocalizedString(@"Not Applicable",nil)];
            printLabel = NO;
            break;
        }
        
        // have we selected a text-based log?
        if (![item isKindOfClass:[NTTextBasedLog class]])
        {
            stringToPrint = [NSString stringWithString:NSLocalizedString(@"Not Applicable",nil)];
            printLabel = NO;
            break;
        }
        
        // check font consistancy
        if (uniformFont && ![[firstItem valueForKey:@"font"] isEqual:[item valueForKey:@"font"]])
        {
            uniformFont = NO;
            stringToPrint = [NSString stringWithString:NSLocalizedString(@"Multiple Fonts",nil)];
        }
                
        // check shadow consistancy
        if (uniformShadow && [[firstItem valueForKey:@"textDropShadow"] boolValue] != [[item valueForKey:@"textDropShadow"] boolValue])
        {
            uniformShadow = NO;
        }
        
        // check text color consistancy
        if (uniformTextColor && ![[firstItem valueForKey:@"textColor"] isEqual:[item valueForKey:@"textColor"]])
        {
            uniformTextColor = NO;
        }
        
        // check background color consistancy
        if (uniformBackgroundColor && ![[firstItem valueForKey:@"backgroundColor"] isEqual:[item valueForKey:@"backgroundColor"]])
        {
            uniformBackgroundColor = NO;
        }        
        
    }
    
    if (printLabel)
    {
        if (uniformFont)
        {
            font = [firstItem valueForKey:@"font"];
            stringToPrint = [NSString stringWithFormat:@"%@",[font displayName]];
        }
        if (uniformTextColor) textColor = [firstItem valueForKey:@"textColor"];
        if (uniformBackgroundColor) backgroundColor = [firstItem valueForKey:@"backgroundColor"];
        if (uniformShadow && [[firstItem valueForKey:@"textDropShadow"] boolValue])
        {
            defShadow = [[NSShadow alloc] init];
            [defShadow setShadowOffset:(NSSize){SHADOW_W,SHADOW_H}];
            [defShadow setShadowBlurRadius:SHADOW_RADIUS];
        }
    }
    
    
    // Do the actual drawing
    NSRect myBounds = [self bounds];
    NSDrawLightBezel(myBounds,myBounds);
    
    [backgroundColor set];
    NSRectFillUsingOperation(NSInsetRect(myBounds,2,2),NSCompositeSourceOver);
    
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,textColor,NSForegroundColorAttributeName,[defShadow autorelease],NSShadowAttributeName,nil];
    NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:stringToPrint attributes:attrsDictionary] autorelease];
    NSSize attrSize = [attrString size];
    
    [attrString drawAtPoint:NSMakePoint(((attrSize.width / -2) + myBounds.size.width / 2),(attrSize.height / -2) + (myBounds.size.height / 2))];
    
    if (!printLabel) return;
    NSDictionary *labelDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont labelFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,[NSColor grayColor],NSForegroundColorAttributeName,nil];
    NSAttributedString *labelString = [[[NSAttributedString alloc]initWithString:[NSString stringWithFormat:@"%@ %.1f pt.",[font displayName],[font pointSize]] attributes:labelDict] autorelease];
    NSSize labelSize = [labelString size];        
    
    NSRect labelBounds = NSInsetRect(NSMakeRect(0,0,myBounds.size.width,labelSize.height + 1),2,2);
    [[NSColor whiteColor] set];
    NSRectFill(labelBounds);
    [labelString drawAtPoint:NSMakePoint(((labelSize.width / -2) + myBounds.size.width / 2),1)];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    for (id item in [treeController selectedObjects])
    {
        // have we selected a group?
        if ([item isKindOfClass:[NTGroup class]]) return;
        
        // can the selected items share the preference view?
        if (![item isKindOfClass:[NTTextBasedLog class]]) return;
    }
        
    NTTextBasedLog *selectedLog = [[treeController selectedObjects] objectAtIndex:0];
    NSFont *font = (selectedLog.font) ? selectedLog.font : [NSFont systemFontOfSize:[NSFont systemFontSize]];
    
	[[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
	
	// Set window as firstResponder so we get changeFont: messages
    [[[NSApplication sharedApplication] mainWindow] setDelegate:self];
    [[[NSApplication sharedApplication] mainWindow] makeFirstResponder:[[NSApplication sharedApplication] mainWindow]];    
}

- (void)changeFont:(id)sender
{
	NSFont *selectedFont = ([[NSFontManager sharedFontManager] selectedFont]) ? [[NSFontManager sharedFontManager] selectedFont] : [NSFont systemFontOfSize:[NSFont systemFontSize]];
    
	NSFont *panelFont = [[NSFontManager sharedFontManager] convertFont:selectedFont];
    
    for (id item in [treeController selectedObjects])
    {
        // have we selected a group?
        if ([item isKindOfClass:[NTGroup class]]) return;
        
        // can the selected items share the preference view?
        if (![item isKindOfClass:[NTTextBasedLog class]]) return;
        
        ((NTTextBasedLog*)item).font = panelFont;
    }    
}

- (void)awakeFromNib
{
    [treeController addObserver:self forKeyPath:@"selection.textColor" options:0 context:nil];
    [treeController addObserver:self forKeyPath:@"selection.backgroundColor" options:0 context:nil];
    [treeController addObserver:self forKeyPath:@"selection.font" options:0 context:nil];
    [treeController addObserver:self forKeyPath:@"selection.textDropShadow" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self setNeedsDisplay:YES];
}

- (void)dealloc
{
	[treeController removeObserver:self forKeyPath:@"selection.textColor"];
	[treeController removeObserver:self forKeyPath:@"selection.backgroundColor"];
	[treeController removeObserver:self forKeyPath:@"selection.font"];
	[treeController removeObserver:self forKeyPath:@"selection.textDropShadow"];
	
	[super dealloc];	
}

@end
