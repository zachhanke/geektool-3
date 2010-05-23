/*
 * NTImage.m
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

#import "NTImage.h"
#import "NTLog.h"
#import "LogTextField.h"
#import "LogWindow.h"

#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"


@implementation NTImage
#pragma mark Properties
- (NSString *)logTypeName
{
    return @"Image";
}

- (BOOL)needsDisplayUIBox
{
    return NO;
}

- (NSString *)preferenceNibName
{
    return @"imagePrefs";
}

- (NSString *)displayNibName
{
    return @"imageWindow";
}

- (NSDictionary *)defaultProperties
{    
    NSDictionary *defaultProperties = [[NSDictionary alloc]initWithObjectsAndKeys:
                                       NSLocalizedString(@"New image log",nil),@"name",
                                       [NSNumber numberWithBool:YES],@"enabled",
                                       
                                       [NSNumber numberWithInt:16],@"x",
                                       [NSNumber numberWithInt:38],@"y",
                                       [NSNumber numberWithInt:280],@"w",
                                       [NSNumber numberWithInt:150],@"h",
                                       [NSNumber numberWithBool:NO],@"alwaysOnTop",
                                       [NSNumber numberWithBool:NO],@"shadowWindow",
                                       [NSNumber numberWithBool:NO],@"sizeToScreen",
                                       
                                       [NSNumber numberWithInt:10],@"refresh",
                                       @"",@"imageURL",
                                       [NSNumber numberWithInt:TOP_LEFT],@"pictureAlignment",
                                       [NSNumber numberWithFloat:1.0],@"opacity",
                                       [NSNumber numberWithInt:PROPORTIONALLY],@"imageFit",
                                       nil];
    
    return [defaultProperties autorelease];
}

#pragma mark Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    [imageURL setEditable:YES];
    [refresh setEditable:YES];
    
    [refresh bind:@"value" toObject:bindee withKeyPath:@"selection.properties.refresh" options:nil];
    [imageURL bind:@"value" toObject:bindee withKeyPath:@"selection.properties.imageURL" options:nil];
    [alignment bind:@"selectedIndex" toObject:bindee withKeyPath:@"selection.properties.pictureAlignment" options:nil];
    [opacity bind:@"value" toObject:bindee withKeyPath:@"selection.properties.opacity" options:nil];
    [opacityText bind:@"value" toObject:bindee withKeyPath:@"selection.properties.opacity" options:nil];
    [scaling bind:@"selectedIndex" toObject:bindee withKeyPath:@"selection.properties.imageFit" options:nil];
}

- (void)destroyInterfaceBindings
{
    [refresh unbind:@"value"];
    [imageURL unbind:@"value"];
    [alignment unbind:@"value"];
    [opacity unbind:@"value"];
    [opacityText unbind:@"value"];
    [scaling unbind:@"value"];
}

#pragma mark Observing
- (void)setupPreferenceObservers
{
    [self addObserver:self forKeyPath:@"properties.refresh" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.imageURL" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.pictureAlignment" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.opacity" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.imageFit" options:0 context:NULL];
    [super setupPreferenceObservers];
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"properties.refresh"];
    [self removeObserver:self forKeyPath:@"properties.imageURL"];
    [self removeObserver:self forKeyPath:@"properties.pictureAlignment"];
    [self removeObserver:self forKeyPath:@"properties.opacity"];
    [self removeObserver:self forKeyPath:@"properties.imageFit"];
    [super removePreferenceObservers];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"properties.enabled"] || [keyPath isEqualToString:@"active"])
    {
        if (windowController) [self destroyLogProcess];
        if (![[self active]boolValue] || ![properties boolForKey:@"enabled"]) return;
        
        [self createLogProcess];
        [self updateWindowIncludingTimer:YES];
    }
    // check if our LogProcess is alive
    else if (!windowController) return;
    else if ([keyPath isEqualToString:@"properties.shadowWindow"] || [keyPath isEqualToString:@"properties.imageURL"] || [keyPath isEqualToString:@"properties.refresh"])
    {
        [self updateWindowIncludingTimer:YES];
    }
    else
    {
        [self updateWindowIncludingTimer:NO];
    }
    
    if (postActivationRequest)
    {
        postActivationRequest = NO;
        if(!highlightSender) return;
        [[self highlightSender]observeValueForKeyPath:@"selectedObjects" ofObject:self change:nil context:nil];
    }
}

#pragma mark Window Management
- (void)updateWindowIncludingTimer:(BOOL)updateTimer
{    
    [window setAlphaValue:[[properties valueForKey:@"opacity"]floatValue]];
    [[window imageView]setImageAlignment:[self imageAlignment]];
    [[window imageView]setImageScaling:[self imageFit]];
    
    [super updateWindowIncludingTimer:updateTimer];
}

#pragma mark Task
- (void)updateCommand:(NSTimer*)timer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    if (![properties objectForKey:@"imageURL"]) return;
    [NSThread detachNewThreadSelector:@selector(setImage:) toTarget:self withObject:[properties objectForKey:@"imageURL"]];            
    [pool release];
}

#pragma mark -
#pragma mark Local Methods
#pragma mark File handling
- (IBAction)fileChoose:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:YES];
    
    NSString *defaultDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    NSString *defaultFile = nil;
    NSURL *curURL = [NSURL URLWithString:[[self properties]objectForKey:@"imageURL"]];
    if ([curURL isFileURL] && [[NSFileManager defaultManager]fileExistsAtPath:[curURL path]])
    {
        defaultFile = [[curURL path]lastPathComponent];
        defaultDir = [[curURL path]stringByDeletingLastPathComponent];
    }
    [openPanel beginSheetForDirectory:defaultDir file:defaultFile types:nil modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];    
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [NSApp endSheet:sheet];
    if (returnCode == NSOKButton)
    {
        if (![[sheet filenames]count]) return;        
        [[self properties]setObject:[[[sheet URLs]objectAtIndex:0]absoluteString] forKey:@"imageURL"];
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn) [sheet close];
}

#pragma mark Image handling
- (void)setImage:(NSString*)urlStr
{    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    NSURL *tmp = [NSURL URLWithString:urlStr];
    NSImage *myImage = [[NSImage alloc]initWithContentsOfURL:tmp];
    [[window imageView]setImage:myImage];
    [myImage release];
    [pool release];
}

- (int)imageFit
{
    switch ([properties integerForKey:@"imageFit"])
    {
        case PROPORTIONALLY:
            return NSImageScaleProportionallyUpOrDown;
            break;
        case TO_FIT:
            return NSImageScaleAxesIndependently;
            break;
        case NONE:
            return NSImageScaleNone;
            break;
    }
    return NSScaleNone;
}

- (int)imageAlignment
{
    switch ([properties integerForKey:@"pictureAlignment"])
    {
        case TOP_LEFT:
            return NSImageAlignTopLeft;
            break;
        case TOP:
            return NSImageAlignTop;
            break;
        case TOP_RIGHT:
            return NSImageAlignTopRight;
            break;
        case LEFT:
            return NSImageAlignLeft;
            break;
        case CENTER:
            return NSImageAlignCenter;
            break;
        case RIGHT:
            return NSImageAlignRight;
            break;
        case BOTTOM_LEFT:
            return NSImageAlignBottomLeft;
            break;
        case BOTTOM:
            return NSImageAlignBottom;
            break;
        case BOTTOM_RIGHT:
            return NSImageAlignBottomRight;
            break;
    }
    return NSImageAlignTopLeft;
}

@end
