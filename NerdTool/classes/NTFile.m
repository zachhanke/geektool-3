//
//  NTFile.m
//  NerdTool
//
//  Created by Kevin Nygaard on 7/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTFile.h"
#import "LogWindow.h"
#import "LogTextField.h"
#import "NTGroup.h"

#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"

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
    NSData *textColorData = [NSArchiver archivedDataWithRootObject:[NSColor blackColor]];
    NSData *backgroundColorData = [NSArchiver archivedDataWithRootObject:[NSColor clearColor]]; 
    NSData *font = [NSArchiver archivedDataWithRootObject:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    
    NSDictionary *defaultProperties = [[NSDictionary alloc]initWithObjectsAndKeys:
                                       NSLocalizedString(@"New file log",nil),@"name",
                                       [NSNumber numberWithBool:YES],@"enabled",
                                       
                                       [NSNumber numberWithInt:16],@"x",
                                       [NSNumber numberWithInt:38],@"y",
                                       [NSNumber numberWithInt:280],@"w",
                                       [NSNumber numberWithInt:150],@"h",
                                       [NSNumber numberWithBool:NO],@"alwaysOnTop",
                                       
                                       @"",@"file",
                                       
                                       font,@"font",
                                       textColorData,@"textColor",
                                       backgroundColorData,@"backgroundColor",
                                       [NSNumber numberWithBool:NO],@"wrap",
                                       [NSNumber numberWithBool:NO],@"shadowText",
                                       [NSNumber numberWithBool:NO],@"shadowWindow",
                                       [NSNumber numberWithBool:NO],@"useAsciiEscapes",
                                       [NSNumber numberWithInt:ALIGN_LEFT],@"alignment",
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
        [self setupLogWindowAndDisplay];
    }
    // check if our LogProcess is alive
    else if (!windowController) return;
    else if ([keyPath isEqualToString:@"properties.shadowWindow"] || [keyPath isEqualToString:@"properties.file"])
    {
        [self setupLogWindowAndDisplay];
    }
    else
    {
        timerNeedsUpdate = NO;
        [self updateWindow];
    }
    
    if (postActivationRequest)
    {
        postActivationRequest = NO;
        if(!highlightSender) return;
        [[self highlightSender]observeValueForKeyPath:@"selectedObjects" ofObject:self change:nil context:nil];
    }
}

#pragma mark Window Management
- (void)createWindow
{        
    [super createWindow];

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

- (void)updateWindow
{
    [super updateWindow];
}

#pragma mark Task
- (void)updateCommand:(NSTimer*)timer
{
    [super updateCommand:timer];
}

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
    
    NSMutableString *newString = [[[NSMutableString alloc]initWithData:newData encoding:NSASCIIStringEncoding]autorelease];
    
    if ([newString isEqualTo:@""])
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
    [openPanel beginSheetForDirectory:@"/var/log/" file:@"system.log" types:nil modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];    
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