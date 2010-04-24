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

#import "ANSIEscapeHelper.h"


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
                                       [NSNumber numberWithBool:NO],@"sizeToScreen",
                                       
                                       @"date",@"command",
                                       [NSNumber numberWithInt:10],@"refresh",
                                       [NSNumber numberWithInt:NTWaitForData],@"printMode",

                                       [NSArchiver archivedDataWithRootObject:[NSFont systemFontOfSize:[NSFont systemFontSize]]],@"font",
                                       [NSNumber numberWithInt:NSASCIIStringEncoding],@"stringEncoding",
                                       [[NSUserDefaults standardUserDefaults]objectForKey:@"defaultFgColor"],@"textColor",
                                       [[NSUserDefaults standardUserDefaults]objectForKey:@"defaultBgColor"],@"backgroundColor",
                                       [NSNumber numberWithBool:NO],@"wrap",
                                       [NSNumber numberWithBool:NO],@"shadowText",
                                       [NSNumber numberWithBool:NO],@"shadowWindow",
                                       [NSNumber numberWithBool:NO],@"useAsciiEscapes",
                                       [NSNumber numberWithInt:ALIGN_LEFT],@"alignment",
                                       
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBlack],@"fgBlack",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgRed],@"fgRed",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgGreen],@"fgGreen",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgYellow],@"fgYellow",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBlue],@"fgBlue",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgMagenta],@"fgMagenta",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgCyan],@"fgCyan",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgWhite],@"fgWhite",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBlack],@"bgBlack",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgRed],@"bgRed",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgGreen],@"bgGreen",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgYellow],@"bgYellow",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBlue],@"bgBlue",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgMagenta],@"bgMagenta",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgCyan],@"bgCyan",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgWhite],@"bgWhite",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightBlack],@"fgBrightBlack",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightRed],@"fgBrightRed",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightGreen],@"fgBrightGreen",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightYellow],@"fgBrightYellow",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightBlue],@"fgBrightBlue",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightMagenta],@"fgBrightMagenta",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightCyan],@"fgBrightCyan",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightWhite],@"fgBrightWhite",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightBlack],@"bgBrightBlack",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightRed],@"bgBrightRed",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightGreen],@"bgBrightGreen",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightYellow],@"bgBrightYellow",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightBlue],@"bgBrightBlue",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightMagenta],@"bgBrightMagenta",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightCyan],@"bgBrightCyan",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightWhite],@"bgBrightWhite",
                                       nil];
    
    return [defaultProperties autorelease];
}

- (void)createLogProcess
{
    [super createLogProcess];
    oldPrintMode = [properties integerForKey:@"printMode"];
}

#pragma mark Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    // These can get turned off if you have the text field selected, and then change logs. When you go back to that log, things are screwed up. The setEditable: fixes this (as well as makes them tasty :P)
    [command setEditable:YES];
    [refresh setEditable:YES];
    
    [command bind:@"value" toObject:bindee withKeyPath:@"selection.properties.command" options:nil];
    [refresh bind:@"value" toObject:bindee withKeyPath:@"selection.properties.refresh" options:nil];
    [printMode bind:@"selectedIndex" toObject:bindee withKeyPath:@"selection.properties.printMode" options:nil];
}

- (void)destroyInterfaceBindings
{
    [command unbind:@"value"];
    [refresh unbind:@"value"];
    [printMode unbind:@"selectedIndex"];
}

#pragma mark Observing
- (void)setupPreferenceObservers
{
    [self addObserver:self forKeyPath:@"properties.command" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.refresh" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.printMode" options:0 context:NULL];
    [super setupPreferenceObservers];
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"properties.command"];
    [self removeObserver:self forKeyPath:@"properties.refresh"];
    [self removeObserver:self forKeyPath:@"properties.printMode"];
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
    else if ([keyPath isEqualToString:@"properties.command"] || [keyPath isEqualToString:@"properties.refresh"] || [keyPath isEqualToString:@"properties.printMode"])
    {
        [self updateWindowIncludingTimer:YES];
    }
    else if ([keyPath isEqualToString:@"properties.useAsciiEscapes"] || [keyPath isEqualToString:@"properties.stringEncoding"])
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
    if (task && [task isRunning])
    {
        if ([[task arguments]isEqualToArray:[self arguments]] && [properties integerForKey:@"printMode"] == oldPrintMode) return;
        [[NSNotificationCenter defaultCenter]removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:nil];
        [[NSNotificationCenter defaultCenter]removeObserver:self name:NSFileHandleDataAvailableNotification object:nil];
        [task terminate];
    }
    [self setTask:[[[NSTask alloc]init]autorelease]];
    NSPipe *pipe = [NSPipe pipe];
    
    oldPrintMode = [properties integerForKey:@"printMode"];
    
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:[self arguments]];
    [task setEnvironment:[self env]];
    // needed to keep xcode's console working
    [task setStandardInput:[NSPipe pipe]];
    [task setStandardOutput:pipe];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:NSFileHandleReadToEndOfFileCompletionNotification object:[pipe fileHandleForReading]];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:NSFileHandleDataAvailableNotification object:[pipe fileHandleForReading]];

    if ([properties integerForKey:@"printMode"] == NTWaitForData) [[pipe fileHandleForReading]readToEndOfFileInBackgroundAndNotify];
    else [[pipe fileHandleForReading]waitForDataInBackgroundAndNotify];
    
    [task launch];    
    [pool release];
}

- (void)processNewDataFromTask:(NSNotification*)aNotification
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];

    NSFileHandle *fh = [aNotification object];
    
    NSData *newData;
    
    if ([[aNotification name]isEqual:NSFileHandleReadToEndOfFileCompletionNotification])
    {
        newData = [[aNotification userInfo]objectForKey:NSFileHandleNotificationDataItem];
        [[NSNotificationCenter defaultCenter]removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:fh];
        [[NSNotificationCenter defaultCenter]removeObserver:self name:NSFileHandleDataAvailableNotification object:fh];        
    }
    else
        newData = [fh availableData];

    NSMutableString *newString = [[[NSMutableString alloc]initWithData:newData encoding:[properties integerForKey:@"stringEncoding"]]autorelease];
    
    if (!newString || [newString isEqualTo:@""])
    {
        return;
    }
    
    [self setLastRecievedString:newString];
    [(LogTextField*)[window textView]processAndSetText:newString withEscapes:[[self properties]boolForKey:@"useAsciiEscapes"] andCustomColors:[self customAnsiColors] insert:([properties integerForKey:@"printMode"] == NTAppendData)];
    [(LogTextField*)[window textView]scrollEnd];
    
    if ([properties integerForKey:@"printMode"] == NTWaitForData) [fh readToEndOfFileInBackgroundAndNotify];
    else [fh waitForDataInBackgroundAndNotify];

    [window display];
    [pool release];
}

- (void)notificationHandler:(NSNotification *)notification
{
    if ([[notification name]isEqualToString:NSWindowDidResizeNotification]) [(LogTextField *)[window textView]scrollEnd];
    [super notificationHandler:notification];
}

#pragma mark Interface
- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector
{
    BOOL result = NO;
    
    if (commandSelector == @selector(insertNewline:))
    {
        // new line action:
        // always insert a line-break character and don’t cause the receiver to end editing
        [textView insertNewlineIgnoringFieldEditor:self];
        result = YES;
    }
    else if (commandSelector == @selector(insertTab:))
    {
        // tab action:
        // always insert a tab character and don’t cause the receiver to end editing
        [textView insertTabIgnoringFieldEditor:self];
        result = YES;
    }
    
    return result;
}

@end
