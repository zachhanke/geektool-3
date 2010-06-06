/*
 * NTQuartz.m
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

#import "NTQuartz.h"
#import "NTLog.h"
#import "LogTextField.h"
#import "LogWindow.h"
#import "AIQuartzView.h"

#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"

@implementation NTQuartz

#pragma mark Properties
- (NSString *)logTypeName
{
    return @"Quartz";
}

- (BOOL)needsDisplayUIBox
{
    return NO;
}

- (NSString *)preferenceNibName
{
    return @"quartzPrefs";
}

- (NSString *)displayNibName
{
    return @"quartzWindow";
}

- (NSDictionary *)defaultProperties
{    
    NSDictionary *defaultProperties = [[NSDictionary alloc]initWithObjectsAndKeys:
                                       NSLocalizedString(@"New quartz log",nil),@"name",
                                       [NSNumber numberWithBool:YES],@"enabled",
                                       
                                       [NSNumber numberWithInt:16],@"x",
                                       [NSNumber numberWithInt:38],@"y",
                                       [NSNumber numberWithInt:280],@"w",
                                       [NSNumber numberWithInt:150],@"h",
                                       [NSNumber numberWithBool:NO],@"alwaysOnTop",
                                       [NSNumber numberWithBool:NO],@"shadowWindow",
                                       [NSNumber numberWithBool:NO],@"sizeToScreen",
                                       
                                       [NSNumber numberWithInt:10],@"refresh",
                                       @"",@"quartzFile",
                                       [NSNumber numberWithFloat:1.0],@"framerate",
                                       nil];
    
    return [defaultProperties autorelease];
}

#pragma mark Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    [quartzFile setEditable:YES];
    [refresh setEditable:YES];
    
    [quartzFile bind:@"value" toObject:bindee withKeyPath:@"selection.properties.quartzFile" options:nil];
    [refresh bind:@"value" toObject:bindee withKeyPath:@"selection.properties.refresh" options:nil];
    [framerateText bind:@"value" toObject:bindee withKeyPath:@"selection.properties.framerate" options:nil];
    [framerateSlider bind:@"value" toObject:bindee withKeyPath:@"selection.properties.framerate" options:nil];
}

- (void)destroyInterfaceBindings
{
    [quartzFile unbind:@"value"];
    [refresh unbind:@"value"];
    [framerateText unbind:@"value"];
    [framerateSlider unbind:@"value"];
}

#pragma mark Observing
- (void)setupPreferenceObservers
{
    [self addObserver:self forKeyPath:@"properties.refresh" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.quartzFile" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.framerate" options:0 context:NULL];
    [super setupPreferenceObservers];
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"properties.refresh"];
    [self removeObserver:self forKeyPath:@"properties.quartzFile"];
    [self removeObserver:self forKeyPath:@"properties.framerate"];
    [super removePreferenceObservers];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"properties.enabled"] || [keyPath isEqualToString:@"active"])
    {
        if (windowController) [self destroyLogProcess];
        if (![[self active]boolValue] || ![properties boolForKey:@"enabled"]) return;
        
        [self createLogProcess];
        [self configureLog];
        [self updateWindowIncludingTimer:YES];
    }
    // check if our LogProcess is alive
    else if (!windowController) return;
    else if ([keyPath isEqualToString:@"properties.quartzFile"])
    {
        [self configureLog];
        [self updateWindowIncludingTimer:YES];
    }
    else if ([keyPath isEqualToString:@"properties.refresh"])
    {
        [self updateWindowIncludingTimer:YES];
    }    
    else if ([keyPath isEqualToString:@"properties.framerate"])
    {
        float newFramerate = [framerateSlider floatValue];
        [[window quartzView]setMaxRenderingFrameRate:newFramerate];
        [[window quartzView]setUnlock:(newFramerate == 1.0)?FALSE:TRUE];
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
- (void)configureLog
{
    float newFramerate = [[properties objectForKey:@"framerate"]floatValue];
    [[window quartzView]setMaxRenderingFrameRate:newFramerate];
    [[window quartzView]setUnlock:(newFramerate == 1.0)?FALSE:TRUE];  
    
    if ([[properties objectForKey:@"quartzFile"]isEqual:@""]) return;
    if ([[window quartzView]loadCompositionFromFile:[properties objectForKey:@"quartzFile"]]) [[window quartzView]setAutostartsRendering:TRUE];
}

#pragma mark Task
- (void)updateCommand:(NSTimer*)timer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    [[window quartzView]requestRender];
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
    
    NSString *defaultDir = nil;
    NSString *defaultFile = nil;
    NSString *curPath = [[self properties]objectForKey:@"quartzFile"];
    if ([[NSFileManager defaultManager]fileExistsAtPath:curPath])
    {
        defaultFile = [curPath lastPathComponent];
        defaultDir = [curPath stringByDeletingLastPathComponent];
    }
    [openPanel beginSheetForDirectory:defaultDir file:defaultFile types:[NSArray arrayWithObjects:@"qtz",nil] modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];    
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [NSApp endSheet:sheet];
    if (returnCode == NSOKButton)
    {
        if (![[sheet filenames]count]) return;    
        NSString *fileToOpen = [[sheet filenames]objectAtIndex:0];
        [[self properties]setObject:fileToOpen forKey:@"quartzFile"];
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn) [sheet close];
}
@end
