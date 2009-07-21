//
//  NTFontDisplay.m
//  NerdTool
//
//  Created by Kevin Nygaard on 7/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTFontDisplay.h"
#import "NTLog.h"
#import "defines.h"

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
    
    if ([[logController selectedObjects]count])
    {    
        printLabel = YES;
        NTLog *firstLog = [[logController selectedObjects]objectAtIndex:0];

        for (NTLog *log in [logController selectedObjects])
        {        
            if (![log needsDisplayUIBox])
            {
                stringToPrint = [NSString stringWithString:NSLocalizedString(@"Not Applicable",nil)];
                printLabel = NO;
                break;
            }
            else if(![[[firstLog properties]valueForKey:@"font"]isEqual:[[log properties]valueForKey:@"font"]])
            {
                stringToPrint = [NSString stringWithString:NSLocalizedString(@"Multiple Values",nil)];
                printLabel = NO;
                break;
            }
        }
        if (printLabel)
        {
            font = [NSUnarchiver unarchiveObjectWithData:[[firstLog properties]valueForKey:@"font"]];
            backgroundColor = [NSUnarchiver unarchiveObjectWithData:[[firstLog properties]valueForKey:@"backgroundColor"]];
            textColor = [NSUnarchiver unarchiveObjectWithData:[[firstLog properties]valueForKey:@"textColor"]];
            if ([[[firstLog properties]valueForKey:@"shadowText"]boolValue])
            {
                defShadow = [[NSShadow alloc]init];
                [defShadow setShadowOffset:(NSSize){SHADOW_W,SHADOW_H}];
                [defShadow setShadowBlurRadius:SHADOW_RADIUS];
            }
            stringToPrint = [NSString stringWithFormat:@"%@",[font displayName]];
        }
    }
    
    // Do the actual drawing
    NSRect myBounds = [self bounds];
    NSDrawLightBezel(myBounds,myBounds);
    
    [backgroundColor set];
    NSRectFillUsingOperation(NSInsetRect(myBounds,2,2),NSCompositeSourceOver);
    
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,textColor,NSForegroundColorAttributeName,[defShadow autorelease],NSShadowAttributeName,nil];
    NSAttributedString *attrString = [[[NSAttributedString alloc]initWithString:stringToPrint attributes:attrsDictionary]autorelease];
    NSSize attrSize = [attrString size];
    
    [attrString drawAtPoint:NSMakePoint(((attrSize.width / -2) + myBounds.size.width / 2),(attrSize.height / -2) + (myBounds.size.height / 2))];
    
    if (!printLabel) return;
    NSDictionary *labelDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont labelFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,[NSColor grayColor],NSForegroundColorAttributeName,nil];
    NSAttributedString *labelString = [[[NSAttributedString alloc]initWithString:[NSString stringWithFormat:@"%@ %.1f pt.",[font displayName],[font pointSize]] attributes:labelDict]autorelease];
    NSSize labelSize = [labelString size];        
    
    NSRect labelBounds = NSInsetRect(NSMakeRect(0,0,myBounds.size.width,labelSize.height + 1),2,2);
    [[NSColor whiteColor]set];
    NSRectFill(labelBounds);
    [labelString drawAtPoint:NSMakePoint(((labelSize.width / -2) + myBounds.size.width / 2),1)];
    
}

- (void)mouseDown:(NSEvent *)theEvent
{
    for (NTLog *log in [logController selectedObjects])
        if (![log needsDisplayUIBox]) return;
    
    NTLog *selectedLog = [[logController selectedObjects]objectAtIndex:0];
    NSFont *font = [NSUnarchiver unarchiveObjectWithData:[[selectedLog properties]valueForKey:@"font"]];
	if (!font) font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    
	[[NSFontManager sharedFontManager]setSelectedFont:font isMultiple:NO];
    [[NSFontManager sharedFontManager]orderFrontFontPanel:self];
	
	// Set window as firstResponder so we get changeFont: messages
    [[[NSApplication sharedApplication]mainWindow]setDelegate:self];
    [[[NSApplication sharedApplication]mainWindow]makeFirstResponder:[[NSApplication sharedApplication]mainWindow]];    
}

- (void)changeFont:(id)sender
{
	NSFont *selectedFont = [[NSFontManager sharedFontManager]selectedFont];
	if (!selectedFont) selectedFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    
	NSFont *panelFont = [[NSFontManager sharedFontManager]convertFont:selectedFont];
    
    for (NTLog *log in [logController selectedObjects])
        [[log properties]setValue:[NSArchiver archivedDataWithRootObject:panelFont] forKey:@"font"];
}

- (void)awakeFromNib
{
    [logController addObserver:self forKeyPath:@"selection.properties.textColor" options:0 context:nil];
    [logController addObserver:self forKeyPath:@"selection.properties.backgroundColor" options:0 context:nil];
    [logController addObserver:self forKeyPath:@"selection.properties.font" options:0 context:nil];
    [logController addObserver:self forKeyPath:@"selection.properties.shadowText" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self setNeedsDisplay:YES];
}

- (void)dealloc
{
	[logController removeObserver:self forKeyPath:@"selection.properties.textColor"];
	[logController removeObserver:self forKeyPath:@"selection.properties.backgroundColor"];
	[logController removeObserver:self forKeyPath:@"selection.properties.font"];
	[logController removeObserver:self forKeyPath:@"selection.properties.shadowText"];
	
	[super dealloc];	
}

@end
