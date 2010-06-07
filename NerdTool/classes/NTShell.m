/*
 * NTShell.m
 * NerdTool
 * Created by Kevin Nygaard on 7/16/09.
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

#import "NTShell.h"
#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"

#import "NTLog.h"
#import "LogWindow.h"
#import "LogTextField.h"
#import "ANSIEscapeHelper.h"


@implementation NTShell

@dynamic command;
@dynamic printMode;
@dynamic refresh;

// Called when object is created
- (void)awakeFromInsert
{
    self.isLeaf = [NSNumber numberWithBool:YES];
    [super awakeFromInsert];	
}

// Called when object is loaded
- (void)awakeFromFetch
{
    [super awakeFromFetch];
    NSLog(@"awakeFromFetch");
}

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

- (void)createLogProcess
{
    [super createLogProcess];
    oldPrintMode = [self.printMode intValue];
}

#pragma mark Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    // These can get turned off if you have the text field selected, and then change logs. When you go back to that log, things are screwed up. The setEditable: fixes this (as well as makes them tasty :P)
    [commandOutlet setEditable:YES];
    [refreshOutlet setEditable:YES];
    
    [commandOutlet bind:@"value" toObject:bindee withKeyPath:@"selection.command" options:nil];
    [refreshOutlet bind:@"value" toObject:bindee withKeyPath:@"selection.refresh" options:nil];
    [printModeOutlet bind:@"selectedIndex" toObject:bindee withKeyPath:@"selection.printMode" options:nil];
}

- (void)destroyInterfaceBindings
{
    [commandOutlet unbind:@"value"];
    [refreshOutlet unbind:@"value"];
    [printModeOutlet unbind:@"selectedIndex"];
}

#pragma mark Observing
- (void)setupPreferenceObservers
{
    [super setupPreferenceObservers];

    [self addObserver:self forKeyPath:@"command" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"refresh" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"printMode" options:0 context:NULL];    
}

- (void)removePreferenceObservers
{
    [super removePreferenceObservers];

    [self removeObserver:self forKeyPath:@"command"];
    [self removeObserver:self forKeyPath:@"refresh"];
    [self removeObserver:self forKeyPath:@"printMode"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // if we aren't enabled, we don't need to bother with the rest: they are for updating the log window
    if (!self.enabled) return;
    else if ([keyPath isEqualToString:@"command"] || [keyPath isEqualToString:@"refresh"] || [keyPath isEqualToString:@"printMode"])
    {
        [self updateWindowIncludingTimer:YES];
    }
    else if ([keyPath isEqualToString:@"useAsciiEscapes"] || [keyPath isEqualToString:@"stringEncoding"])
    {
        if (self.windowController && self.timer) [timer fire];
    }    
    else
    {
        [self updateWindowIncludingTimer:NO];
        [self updatePreviewText];
    }
}

#pragma mark Window Management
- (void)updateWindowIncludingTimer:(BOOL)updateTimer
{    
    [super updateWindowIncludingTimer:updateTimer];
    
    if (updateTimer)
    {
        self.arguments = [NSArray arrayWithObjects:@"-l",@"-c",self.command,nil];
        [[window textView] setString:@""];
        [self updateTimer];
    }    
}

#pragma mark Timer
- (void)setTimer:(NSTimer*)newTimer
{
    [timer autorelease];
    if ([timer isValid])
    {
        [self retain]; // to counter our balancing done in updateTimer
        [timer invalidate];
    }
    timer = [newTimer retain];
}

- (void)killTimer
{
    if (!timer) return;
    [self setTimer:nil];
}

- (void)updateTimer
{
    int refreshTime = [self.refresh intValue];
    BOOL timerRepeats = refreshTime ? YES : NO;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:refreshTime target:self selector:@selector(updateCommand:) userInfo:nil repeats:timerRepeats];
    [timer fire];
    
    if (timerRepeats) [self release]; // since timer repeats, self is retained. we don't want this
    else self.timer = nil;
}

#pragma mark Task
- (void)updateCommand:(NSTimer*)timer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (task && [task isRunning])
    {
        if ([[task arguments] isEqualToArray:[self arguments]] && [self.printMode intValue] == oldPrintMode) return;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:nil];
        [task terminate];
    }
    [self setTask:[[[NSTask alloc] init] autorelease]];
    NSPipe *pipe = [NSPipe pipe];
    
    oldPrintMode = [self.printMode intValue];
    
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:[self arguments]];
    [task setEnvironment:[self env]];
    [task setStandardInput:[NSPipe pipe]]; // needed to keep xcode's console working
    [task setStandardOutput:pipe];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNewDataFromTask:) name:NSFileHandleReadToEndOfFileCompletionNotification object:[pipe fileHandleForReading]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNewDataFromTask:) name:NSFileHandleDataAvailableNotification object:[pipe fileHandleForReading]];

    if ([self.printMode intValue] == NTWaitForData) [[pipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
    else [[pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
    
    [task launch];    
    [pool release];
}

- (void)processNewDataFromTask:(NSNotification*)aNotification
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];

    NSFileHandle *fh = [aNotification object];
    
    NSData *newData;
    
    if ([[aNotification name] isEqual:NSFileHandleReadToEndOfFileCompletionNotification])
    {
        newData = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:fh];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:fh];        
    }
    else newData = [fh availableData];

    NSMutableString *newString = [[[NSMutableString alloc] initWithData:newData encoding:[self.stringEncoding intValue]] autorelease];
    
    if (!newString || [newString isEqualTo:@""])
    {
        return;
    }
    
    [self setLastRecievedString:newString];
    [(LogTextField*)[window textView] processAndSetText:newString withEscapes:[self.useAsciiEscapes boolValue] andCustomColors:[self customAnsiColors] insert:([self.printMode intValue] == NTAppendData)];
    [(LogTextField*)[window textView] scrollEnd];
    
    if ([self.printMode intValue] == NTWaitForData) [fh readToEndOfFileInBackgroundAndNotify];
    else [fh waitForDataInBackgroundAndNotify];

    [window display];
    [pool release];
}

- (void)notificationHandler:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:NSWindowDidResizeNotification]) [(LogTextField *)[window textView] scrollEnd];
    [super notificationHandler:notification];
}

#pragma mark Interface
/*
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
}*/

@end
