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
                                       [NSNumber numberWithBool:NO],@"sizeToScreen",
                                       
                                       [NSNumber numberWithInt:10],@"refresh",
                                       @"",@"webURL",
                                       [NSNumber numberWithFloat:1.0],@"opacity",
                                       
                                       [NSNumber numberWithInt:0],@"scrollX",
                                       [NSNumber numberWithInt:0],@"scrollY",
                                       
                                       [NSNumber numberWithBool:NO],@"shadowWindow",
                                       nil];
    
    return [defaultProperties autorelease];
}

- (void)dealloc
{
    if(!windowController) [[window webView]stopLoading:nil];
    [super dealloc];
}

#pragma mark Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    // These can get turned off if you have the text field selected, and then change logs. When you go back to that log, things are screwed up. The setEditable: fixes this (as well as makes them tasty :P)
    [webURL setEditable:YES];
    [refresh setEditable:YES];
    
    [refresh bind:@"value" toObject:bindee withKeyPath:@"selection.properties.refresh" options:nil];    
    [webURL bind:@"value" toObject:bindee withKeyPath:@"selection.properties.webURL" options:nil];
    [opacity bind:@"value" toObject:bindee withKeyPath:@"selection.properties.opacity" options:nil];
    [opacityText bind:@"value" toObject:bindee withKeyPath:@"selection.properties.opacity" options:nil];
}

- (void)destroyInterfaceBindings
{
    [refresh unbind:@"value"];
    [webURL unbind:@"value"];
    [opacity unbind:@"value"];
    [opacityText unbind:@"value"];
}

#pragma mark Observing
- (void)setupPreferenceObservers
{
    [self addObserver:self forKeyPath:@"properties.refresh" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.webURL" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.opacity" options:0 context:NULL];
    [super setupPreferenceObservers];
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"properties.refresh"];
    [self removeObserver:self forKeyPath:@"properties.webURL"];
    [self removeObserver:self forKeyPath:@"properties.opacity"];
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
    else if ([keyPath isEqualToString:@"properties.webURL"])
    {
        [self configureLog];
        [self updateWindowIncludingTimer:YES];
    }
    else if ([keyPath isEqualToString:@"properties.refresh"])
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
- (void)configureLog
{        
    highlighted = NO;
    if ([[properties objectForKey:@"webURL"]isEqual:@""]) return;
    [[window webView]setFrameLoadDelegate:self];
    [[window scrollView]setDocumentView:[window webView]];
    needsScroll = YES;
    [[[window webView]mainFrame]loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[properties objectForKey:@"webURL"]]]];
}
    
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if (!windowController || ![[window webView]windowScriptObject]) return;
    if (needsScroll && [[[NSProcessInfo processInfo]processName]isEqual:@"NerdToolRO"])
    {
        NSRect frame = [[[[[window webView]mainFrame]frameView]documentView]frame];
        [[window webView]setFrame:frame];
        NSPoint bounds = NSMakePoint([[properties valueForKey:@"scrollX"]intValue],NSHeight(frame) - [[properties valueForKey:@"scrollY"]intValue] - NSHeight([window frame]));
        [[window scrollView]scrollPoint:NSZeroPoint];
        [[window scrollView]scrollPoint:bounds];
        [[[[window webView]mainFrame]frameView]setAllowsScrolling:NO];
    }
    else if (needsScroll)
    {
        NSScrollView *scrollView = [[[[[window webView]mainFrame]frameView]documentView]enclosingScrollView];
        NSPoint bounds = NSMakePoint([[properties valueForKey:@"scrollX"]intValue],[[properties valueForKey:@"scrollY"]intValue]);
        //bounds = [[[[[window webView]mainFrame]frameView]documentView] convertPoint:bounds toView:scrollView];
        [[scrollView documentView]scrollPoint:bounds];    
    }
    needsScroll = NO;
    [[[window webView]windowScriptObject]evaluateWebScript:[NSString stringWithFormat:@"document.body.style.overflow='%@';",highlighted?@"visible":@"hidden"]];
}

- (IBAction)setScrollLocation:(id)sender
{
    if (!windowController) return;
    NSScrollView *scrollView = [[[[[window webView]mainFrame]frameView]documentView]enclosingScrollView];
    NSPoint bounds = [[scrollView contentView]bounds].origin;
    [properties setValue:[NSNumber numberWithInt:bounds.x] forKey:@"scrollX"];
    [properties setValue:[NSNumber numberWithInt:bounds.y] forKey:@"scrollY"];    
}

- (void)updateWindowIncludingTimer:(BOOL)updateTimer
{
    [window setAlphaValue:[[properties valueForKey:@"opacity"]floatValue]];
    [super updateWindowIncludingTimer:updateTimer];
}

- (void)updateCommand:(NSTimer*)timer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    if (![[window webView]isLoading])[[[window webView]mainFrame]reload];
    [pool release];
}

- (void)setHighlighted:(BOOL)val from:(id)sender
{
    if (windowController) [[[window webView]windowScriptObject]evaluateWebScript:[NSString stringWithFormat:@"document.body.style.overflow='%@';",val?@"visible":@"hidden"]];
    highlighted = val;
    [super setHighlighted:val from:sender];
}

@end
