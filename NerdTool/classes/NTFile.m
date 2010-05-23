/*
 * NTFile.m
 * NerdTool
 * Created by Kevin Nygaard on 7/20/09.
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

#import "NTFile.h"
#import "LogWindow.h"
#import "LogTextField.h"
#import "NTGroup.h"

#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"

#import "ANSIEscapeHelper.h"


@implementation NTFile

#pragma mark Properties
- (NSString *)logTypeName
{
    return @"File";
}

- (BOOL)needsDisplayUIBox
{
    return YES;
}

- (NSString *)preferenceNibName
{
    return @"filePrefs";
}

- (NSString *)displayNibName
{
    return @"shellWindow";
}

- (NSDictionary *)defaultProperties
{
    NSData *textColorData = [[NSUserDefaults standardUserDefaults]objectForKey:@"defaultFgColor"];
    NSData *backgroundColorData = [[NSUserDefaults standardUserDefaults]objectForKey:@"defaultBgColor"]; 
    NSData *font = [NSArchiver archivedDataWithRootObject:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    
    NSDictionary *defaultProperties = [[NSDictionary alloc]initWithObjectsAndKeys:
                                       NSLocalizedString(@"New file log",nil),@"name",
                                       [NSNumber numberWithBool:YES],@"enabled",
                                       
                                       [NSNumber numberWithInt:16],@"x",
                                       [NSNumber numberWithInt:38],@"y",
                                       [NSNumber numberWithInt:280],@"w",
                                       [NSNumber numberWithInt:150],@"h",
                                       [NSNumber numberWithBool:NO],@"alwaysOnTop",
                                       [NSNumber numberWithBool:NO],@"sizeToScreen",
                                       
                                       @"",@"file",
                                       
                                       font,@"font",
                                       textColorData,@"textColor",
                                       backgroundColorData,@"backgroundColor",
                                       [NSNumber numberWithInt:NSASCIIStringEncoding],@"stringEncoding",
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

#pragma mark Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    // These can get turned off if you have the text field selected, and then change logs. When you go back to that log, things are screwed up. The setEditable: fixes this (as well as makes them tasty :P)
    [file setEditable:YES];
    [file bind:@"value" toObject:bindee withKeyPath:@"selection.properties.file" options:nil];
}

- (void)destroyInterfaceBindings
{
    [file unbind:@"value"];
}

#pragma mark Observing
- (void)setupPreferenceObservers
{
    [self addObserver:self forKeyPath:@"properties.file" options:0 context:NULL];
    [super setupPreferenceObservers];
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"properties.file"];
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
        [self updateWindowIncludingTimer:NO];
    }
    // check if our LogProcess is alive
    else if (!windowController) return;
    else if ([keyPath isEqualToString:@"properties.file"])
    {
        [self configureLog];
        [self updateWindowIncludingTimer:NO];
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
    if ([[properties objectForKey:@"file"]isEqual:@""]) return;
    
    // Read file to 50 lines. The -F file makes sure the file keeps getting read even if it hits the EOF or the file name is changed            
    [self setTask:[[[NSTask alloc]init]autorelease]];
    NSPipe *pipe = [NSPipe pipe];
    
    [task setLaunchPath:@"/usr/bin/tail"];
    [task setArguments:[NSArray arrayWithObjects:@"-n",@"50",@"-F",[properties objectForKey:@"file"],nil]];
    [task setEnvironment:env];
    [task setStandardOutput:pipe];
    
    [[window textView]setString:@""];
    if (![[NSFileManager defaultManager]fileExistsAtPath:[properties objectForKey:@"file"]]) return;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:NSFileHandleReadCompletionNotification object:[pipe fileHandleForReading]];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:NSFileHandleDataAvailableNotification object:[pipe fileHandleForReading]];
    
    [[pipe fileHandleForReading]waitForDataInBackgroundAndNotify];
    
    [task launch];        
}

#pragma mark Task
- (void)processNewDataFromTask:(NSNotification*)aNotification
{
    NSData *newData;
    
    if ([[aNotification name]isEqual:NSFileHandleReadToEndOfFileCompletionNotification])
    {
        newData = [[aNotification userInfo]objectForKey:NSFileHandleNotificationDataItem];
        [[NSNotificationCenter defaultCenter]removeObserver:self name:[aNotification name] object:nil];        
    }
    else
        newData = [[aNotification object]availableData];
    
    NSMutableString *newString = [[[NSMutableString alloc]initWithData:newData encoding:[[properties valueForKey:@"stringEncoding"]intValue]]autorelease];
    
    if (!newString || [newString isEqualTo:@""])
    {
        [[NSNotificationCenter defaultCenter]removeObserver:self name:[aNotification name] object:nil];
        return;
    }
    
    [[window textView]processAndSetText:newString withEscapes:[[self properties]boolForKey:@"useAsciiEscapes"] andCustomColors:[self customAnsiColors] insert:YES];
    [(LogTextField*)[window textView]scrollEnd];
    
    [[aNotification object]waitForDataInBackgroundAndNotify];
    [window display];
}

- (void)notificationHandler:(NSNotification *)notification
{
    if ([[notification name]isEqualToString:NSWindowDidResizeNotification]) [(LogTextField *)[window textView]scrollEnd];
    [super notificationHandler:notification];
}

#pragma mark -
#pragma mark Local Methods
#pragma mark File handling
- (IBAction)fileChoose:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:YES];
    
    NSString *defaultDir = @"/var/log/";
    NSString *defaultFile = @"system.log";
    NSString *curPath = [[self properties]objectForKey:@"file"];
    if ([[NSFileManager defaultManager]fileExistsAtPath:curPath])
    {
        defaultFile = [curPath lastPathComponent];
        defaultDir = [curPath stringByDeletingLastPathComponent];
    }
    [openPanel beginSheetForDirectory:defaultDir file:defaultFile types:nil modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];    
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [NSApp endSheet:sheet];
    if (returnCode == NSOKButton)
    {
        if (![[sheet filenames]count]) return;
        NSString *fileToOpen = [[sheet filenames]objectAtIndex:0];
        
        [[self properties]setObject:fileToOpen forKey:@"file"];
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn) [sheet close];
}

@end
