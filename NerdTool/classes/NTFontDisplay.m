//
//  NTFontDisplay.m
//  NerdTool
//
//  Created by Kevin Nygaard on 7/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTFontDisplay.h"
#import "GTLog.h"

@implementation NTFontDisplay
- (BOOL)isOpaque
{
    return NO;
}

- (void)drawRect:(NSRect)rect
{        
    if (![[logController selectedObjects]count])
    {
        NSRect myBounds = [self bounds];

        NSDrawLightBezel(myBounds,myBounds);
        
        [[NSColor blackColor]set];
        NSRectFill(NSInsetRect(myBounds,2,2));
        
        NSFont *defaultFont = [NSFont systemFontOfSize:20.0];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:defaultFont,NSFontAttributeName,[NSColor whiteColor],NSForegroundColorAttributeName,nil];
        NSAttributedString *attrString = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"No Selection",nil) attributes:attrsDictionary];
        NSSize attrSize = [attrString size];
        
        [attrString drawAtPoint:NSMakePoint(((attrSize.width / -2) + myBounds.size.width / 2),(attrSize.height / -2) + (myBounds.size.height / 2))];
        [attrString release];
        return;
    }
    
    GTLog *selectedLog = [[logController selectedObjects]objectAtIndex:0];
	
    NSString *fontName = [[selectedLog properties]valueForKey:@"fontName"];
	float fontSize = [[[selectedLog properties]valueForKey:@"fontSize"]floatValue];
	
    NSFont *font = [NSFont fontWithName:fontName size:fontSize];
	NSColor *backgroundColor = [NSUnarchiver unarchiveObjectWithData:[[selectedLog properties]valueForKey:@"backgroundColor"]];
    NSColor *textColor = [NSUnarchiver unarchiveObjectWithData:[[selectedLog properties]valueForKey:@"textColor"]];
	
	// Do the actual drawing
	NSRect myBounds = [self bounds];
	NSDrawLightBezel(myBounds,myBounds);
    
	[backgroundColor set];
	NSRectFillUsingOperation(NSInsetRect(myBounds,2,2),NSCompositeSourceOver);
	
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,textColor,NSForegroundColorAttributeName,nil];
    NSString *stringToPrint = [NSString stringWithFormat:@"%@ - %.1fpt",fontName,fontSize];
	NSAttributedString *attrString = [[NSAttributedString alloc]initWithString:stringToPrint attributes:attrsDictionary];
	NSSize attrSize = [attrString size];
    
    [attrString drawAtPoint:NSMakePoint(((attrSize.width / -2) + myBounds.size.width / 2),(attrSize.height / -2) + (myBounds.size.height / 2))];
    [attrString release];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    GTLog *selectedLog = [[logController selectedObjects]objectAtIndex:0];
    NSFont *font = [NSFont fontWithName:[[selectedLog properties]objectForKey:@"fontName"] size:[[[selectedLog properties]objectForKey:@"fontSize"]floatValue]];
	if (!font) font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    
	[[NSFontManager sharedFontManager]setSelectedFont:font isMultiple:NO];
    [[NSFontManager sharedFontManager]orderFrontFontPanel:self];
	
	// Set window as firstResponder so we get changeFont: messages
    [[[NSApplication sharedApplication]mainWindow]setDelegate:self];
    [[[NSApplication sharedApplication]mainWindow]makeFirstResponder:[[NSApplication sharedApplication]mainWindow]];    
}

- (void)changeFont:(id)sender
{
    GTLog *selectedLog = [[logController selectedObjects]objectAtIndex:0];
    
	NSFont *selectedFont = [[NSFontManager sharedFontManager]selectedFont];
	if (!selectedFont) selectedFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    
	NSFont *panelFont = [[NSFontManager sharedFontManager]convertFont:selectedFont];
	
	[[selectedLog properties]setValue:[panelFont fontName] forKey:@"fontName"];
	[[selectedLog properties]setValue:[NSNumber numberWithFloat:[panelFont pointSize]] forKey:@"fontSize"];
}

- (void)awakeFromNib
{
    [logController addObserver:self forKeyPath:@"selection.properties.textColor" options:0 context:nil];
    [logController addObserver:self forKeyPath:@"selection.properties.backgroundColor" options:0 context:nil];
    [logController addObserver:self forKeyPath:@"selection.properties.fontName" options:0 context:nil];
    [logController addObserver:self forKeyPath:@"selection.properties.fontSize" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self setNeedsDisplay:YES];
}

- (void)dealloc
{
	[logController removeObserver:self forKeyPath:@"selection.properties.textColor"];
	[logController removeObserver:self forKeyPath:@"selection.properties.backgroundColor"];
	[logController removeObserver:self forKeyPath:@"selection.properties.fontName"];
	[logController removeObserver:self forKeyPath:@"selection.properties.fontSize"];
	
	[super dealloc];	
}

@end
