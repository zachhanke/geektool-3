//
//  NTShell.m
//  NerdTool
//
//  Created by Kevin Nygaard on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTShell.h"
#import "NTLog.h"
#import "LogTextField.h"

#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"

@implementation NTShell

#pragma mark Properties
- (NSString *)logTypeName
{
    return NSLocalizedString(@"Shell",nil);
}

- (BOOL)needsDisplayUIBox
{
    return YES;
}

- (NSString *)preferenceNibName
{
    return @"shellPrefs";
}

- (NSString *)displayNibName
{
    return @"shellWindow";
}

- (NSDictionary *)defaultProperties
{
    NSDictionary *defaultProperties = [[NSDictionary alloc]initWithObjectsAndKeys:
                                       NSLocalizedString(@"New shell log",nil),@"name",
                                       [NSNumber numberWithBool:YES],@"enabled",
                                       
                                       [NSNumber numberWithInt:16],@"x",
                                       [NSNumber numberWithInt:38],@"y",
                                       [NSNumber numberWithInt:280],@"w",
                                       [NSNumber numberWithInt:150],@"h",
                                       [NSNumber numberWithBool:NO],@"alwaysOnTop",
                                       
                                       @"date",@"command",
                                       [NSNumber numberWithInt:10],@"refresh",

                                       [NSArchiver archivedDataWithRootObject:[NSFont systemFontOfSize:[NSFont systemFontSize]]],@"font",
                                       [NSArchiver archivedDataWithRootObject:[NSColor blackColor]],@"textColor",
                                       [NSArchiver archivedDataWithRootObject:[NSColor clearColor]],@"backgroundColor",
                                       [NSNumber numberWithBool:NO],@"wrap",
                                       [NSNumber numberWithBool:NO],@"shadowText",
                                       [NSNumber numberWithBool:NO],@"shadowWindow",
                                       [NSNumber numberWithBool:NO],@"useAsciiEscapes",
                                       [NSNumber numberWithInt:ALIGN_LEFT],@"alignment",
                                       
                                       [NSArchiver archivedDataWithRootObject:[NSColor blackColor]],@"fgBlack",
                                       [NSArchiver archivedDataWithRootObject:[NSColor redColor]],@"fgRed",
                                       [NSArchiver archivedDataWithRootObject:[NSColor greenColor]],@"fgGreen",
                                       [NSArchiver archivedDataWithRootObject:[NSColor yellowColor]],@"fgYellow",
                                       [NSArchiver archivedDataWithRootObject:[NSColor blueColor]],@"fgBlue",
                                       [NSArchiver archivedDataWithRootObject:[NSColor magentaColor]],@"fgMagenta",
                                       [NSArchiver archivedDataWithRootObject:[NSColor cyanColor]],@"fgCyan",
                                       [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]],@"fgWhite",
                                       [NSArchiver archivedDataWithRootObject:[NSColor blackColor]],@"bgBlack",
                                       [NSArchiver archivedDataWithRootObject:[NSColor redColor]],@"bgRed",
                                       [NSArchiver archivedDataWithRootObject:[NSColor greenColor]],@"bgGreen",
                                       [NSArchiver archivedDataWithRootObject:[NSColor yellowColor]],@"bgYellow",
                                       [NSArchiver archivedDataWithRootObject:[NSColor blueColor]],@"bgBlue",
                                       [NSArchiver archivedDataWithRootObject:[NSColor magentaColor]],@"bgMagenta",
                                       [NSArchiver archivedDataWithRootObject:[NSColor cyanColor]],@"bgCyan",
                                       [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]],@"bgWhite",                                       
                                       nil];
    
    return [defaultProperties autorelease];
}

#pragma mark Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    // These can get turned off if you have the text field selected, and then change logs. When you go back to that log, things are screwed up. The setEditable: fixes this (as well as makes them tasty :P)
    [command setEditable:YES];
    [refresh setEditable:YES];
    
    [command bind:@"value" toObject:bindee withKeyPath:@"selection.properties.command" options:nil];
    [refresh bind:@"value" toObject:bindee withKeyPath:@"selection.properties.refresh" options:nil];
}

- (void)destroyInterfaceBindings
{
    [command unbind:@"value"];
    [refresh unbind:@"value"];
}

#pragma mark Observing
- (void)setupPreferenceObservers
{
    [self addObserver:self forKeyPath:@"properties.command" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.refresh" options:0 context:NULL];
    [super setupPreferenceObservers];
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"properties.command"];
    [self removeObserver:self forKeyPath:@"properties.refresh"];
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
    else if ([keyPath isEqualToString:@"properties.command"] || [keyPath isEqualToString:@"properties.refresh"])
    {
        [self updateWindowIncludingTimer:YES];
    }
    else if ([keyPath isEqualToString:@"properties.useAsciiEscapes"])
    {
        if (windowController && timer) [timer fire];
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
    if (updateTimer)
    {
        [self setArguments:[[[NSArray alloc]initWithObjects:@"-c",[[self properties]objectForKey:@"command"],nil]autorelease]];
        [[window textView]setString:@""];
    }
    
    [super updateWindowIncludingTimer:updateTimer];
}

#pragma mark Task
- (void)updateCommand:(NSTimer*)timer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    if (task && [task isRunning]) return;
    
    [self setTask:[[[NSTask alloc]init]autorelease]];
    NSPipe *pipe = [NSPipe pipe];
    
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:[self arguments]];
    [task setEnvironment:[self env]];
    // needed to keep xcode's console working
    [task setStandardInput:[NSPipe pipe]];
    [task setStandardOutput:pipe];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:NSFileHandleReadToEndOfFileCompletionNotification object:[pipe fileHandleForReading]];
    
    [[pipe fileHandleForReading]readToEndOfFileInBackgroundAndNotify];
    
    [task launch];
    [pool release];
}

- (void)processNewDataFromTask:(NSNotification*)aNotification
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    NSData *newData;
    
    if ([[aNotification name]isEqual:NSFileHandleReadToEndOfFileCompletionNotification])
    {
        newData = [[aNotification userInfo]objectForKey:NSFileHandleNotificationDataItem];
        [[NSNotificationCenter defaultCenter]removeObserver:self name:[aNotification name] object:nil];        
    }
    else
        newData = [[aNotification object]availableData];
    
    NSMutableString *newString = [[[NSMutableString alloc]initWithData:newData encoding:NSUTF8StringEncoding]autorelease];
    
    if ([newString isEqualTo:@""]) return;
    
    
    [self setLastRecievedString:newString];
    [(LogTextField*)[window textView]processAndSetText:newString withEscapes:[[self properties]boolForKey:@"useAsciiEscapes"] andCustomColors:[self customAnsiColors] insert:NO];
    [(LogTextField*)[window textView]scrollEnd];
    
    [[aNotification object]readInBackgroundAndNotify];

    [window display];
    [pool release];
}

- (void)notificationHandler:(NSNotification *)notification
{
    if ([[notification name]isEqualToString:NSWindowDidResizeNotification]) [(LogTextField *)[window textView]scrollEnd];
    [super notificationHandler:notification];
}

@end
