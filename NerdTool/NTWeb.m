//
//  NTWeb.m
//  NerdTool
//
//  Created by Kevin Nygaard on 7/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTWeb.h"
#import <WebKit/WebKit.h>
#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"

@implementation NTWeb
#pragma mark Properties
- (NSString *)logTypeName
{
    return @"Web";
}

- (BOOL)needsDisplayUIBox
{
    return NO;
}

- (NSString *)preferenceNibName
{
    return @"webPrefs";
}

- (NSString *)displayNibName
{
    return @"webWindow";
}

- (NSDictionary *)defaultProperties
{    
    NSDictionary *defaultProperties = [[NSDictionary alloc]initWithObjectsAndKeys:
                                       NSLocalizedString(@"New web log",nil),@"name",
                                       [NSNumber numberWithBool:YES],@"enabled",
                                       
                                       [NSNumber numberWithInt:16],@"x",
                                       [NSNumber numberWithInt:38],@"y",
                                       [NSNumber numberWithInt:280],@"w",
                                       [NSNumber numberWithInt:150],@"h",
                                       [NSNumber numberWithBool:NO],@"alwaysOnTop",
                                       
                                       [NSNumber numberWithInt:10],@"refresh",
                                       @"",@"webURL",
                                       
                                       [NSNumber numberWithBool:NO],@"shadowWindow",
                                       nil];
    
    return [defaultProperties autorelease];
}

#pragma mark Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    // These can get turned off if you have the text field selected, and then change logs. When you go back to that log, things are screwed up. The setEditable: fixes this (as well as makes them tasty :P)
    [webURL setEditable:YES];
    [refresh setEditable:YES];
    
    [refresh bind:@"value" toObject:bindee withKeyPath:@"selection.properties.refresh" options:nil];    
    [webURL bind:@"value" toObject:bindee withKeyPath:@"selection.properties.webURL" options:nil];
}

- (void)destroyInterfaceBindings
{
    [refresh unbind:@"value"];
    [webURL unbind:@"value"];
}

#pragma mark Observing
- (void)setupPreferenceObservers
{
    [self addObserver:self forKeyPath:@"properties.refresh" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.webURL" options:0 context:NULL];
    [super setupPreferenceObservers];
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"properties.refresh"];
    [self removeObserver:self forKeyPath:@"properties.webURL"];
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
    else if ([keyPath isEqualToString:@"properties.shadowWindow"] || [keyPath isEqualToString:@"properties.webURL"])
    {
        [self setupLogWindowAndDisplay];
    }
    else if ([keyPath isEqualToString:@"properties.refresh"])
    {
        timerNeedsUpdate = YES;
        [self updateWindow];
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
    highlighted = NO;
    if ([[properties objectForKey:@"webURL"]isEqual:@""]) return;
    [[[window webView]mainFrame]loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[properties objectForKey:@"webURL"]]]];
    [[window webView]setFrameLoadDelegate:self];
    [[[window webView]windowScriptObject]evaluateWebScript:@"document.body.style.overflow='visible';"];
    [[[window webView]windowScriptObject]evaluateWebScript:@"document.body.style.overflow='hidden';"];
}
    
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if (![[window webView]windowScriptObject]) return;
    [[[window webView]windowScriptObject]evaluateWebScript:[NSString stringWithFormat:@"document.body.style.overflow='%@';",highlighted?@"visible":@"hidden"]];
}

- (void)updateWindow
{
    if (timerNeedsUpdate) [self updateTimer];
    [super updateWindow];
}

- (void)updateCommand:(NSTimer*)timer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    [[[window webView]mainFrame]reload];
    [pool release];
}

- (void)setHighlighted:(BOOL)val from:(id)sender
{
    highlighted = val;
    if (windowController) [[[window webView]windowScriptObject]evaluateWebScript:[NSString stringWithFormat:@"document.body.style.overflow='%@';",val?@"visible":@"hidden"]];
    [super setHighlighted:val from:sender];
}

@end
