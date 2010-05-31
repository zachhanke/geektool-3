/*
 * NTLog.m
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

#import "NTLog.h"
#import "LogWindow.h"
#import "LogTextField.h"
#import "NTGroup.h"
#import "ANSIEscapeHelper.h"

#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"
#import "NS(Attributed)String+Geometrics.h"
#import "NTTextBasedLog.h"
#import "NSWindow+StickyWindow.h"

@implementation NTLog


// Core Data Properties
@dynamic alwaysOnTop;
@dynamic name;
@dynamic shadowWindow;
@dynamic sizeToScreen;
@dynamic h;
@dynamic w;
@dynamic x;
@dynamic y;

@synthesize windowController;
@synthesize window;

@synthesize prefsView;

@synthesize highlightSender;
@synthesize postActivationRequest;
@synthesize _isBeingDragged;

@synthesize arguments;
@synthesize env;
@synthesize timer;
@synthesize task;

@synthesize lastRecievedString;

#pragma mark Properties (Subclass these)
// Subclasses must overwrite the following methods
- (NSString *)logTypeName
{
    NSAssert(YES,@"Method was not overwritten: `logTypeName'");
    return @"";
}

- (NSString *)preferenceNibName
{
    NSAssert(YES,@"Method was not overwritten: `preferenceNibName'");
    return @"";
}

- (NSString *)displayNibName
{
    NSAssert(YES,@"Method was not overwritten: `displayNibName'");
    return @"";
}

- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    NSAssert(YES,@"Method was not overwritten: `setupInterfaceBindingsWithObject:'");
    return;
}

- (void)destroyInterfaceBindings
{
    NSAssert(YES,@"Method was not overwritten: `destroyInterfaceBindings'");
    return;
}

#pragma mark Window Management
- (NSWindow*)window
{
    return [windowController window];
}

- (void)updateWindowIncludingTimer:(BOOL)updateTimer
{
    // change the window size
    NSRect newRect = [self screenToRect:[self rect]];
    if ([self.sizeToScreen boolValue]) newRect = [[[NSScreen screens] objectAtIndex:0] frame];
    [window setFrame:newRect display:NO];
        
    // set various attributes
    [self.window setHasShadow:[self.shadowWindow boolValue]];
    [self.window setLevel:[self.alwaysOnTop boolValue] ? kCGMaximumWindowLevel : kCGDesktopWindowLevel];
    [self.window setSticky:![self.alwaysOnTop boolValue]];
        
    postActivationRequest = YES;

    // display window. Window should be loaded since we have been calling [winCtrl window] all the time
    [self.window display];
}

#pragma mark -
#pragma mark Log Container
#pragma mark -

- (void)awakeFromInsert
{
    _loadedView = NO;
    windowController = nil;
    highlightSender = nil;
    lastRecievedString = nil;
    _visibleFrame = [[[NSScreen screens] objectAtIndex:0] frame];
    
    [self setupPreferenceObservers];
}

- (void)dealloc
{
    [self removePreferenceObservers];
    [self destroyLogProcess];
    [properties release];
    [active release];
    [super dealloc];
}

#pragma mark Interface
- (NSView *)loadPrefsViewAndBind:(id)bindee
{
    if (_loadedView) return nil;
    if (!prefsView) [NSBundle loadNibNamed:[self preferenceNibName] owner:self];
    
    [self setupInterfaceBindingsWithObject:bindee];
        
    _loadedView = YES;
    return prefsView;
}

- (NSView *)unloadPrefsViewAndUnbind
{
    if (!_loadedView) return nil;
    
    [self destroyInterfaceBindings];
    
    _loadedView = NO;
    return prefsView;
}

- (void)setupPreferenceObservers
{
    [self addObserver:self forKeyPath:@"active" options:0 context:NULL];
    
    [self addObserver:self forKeyPath:@"name" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"enabled" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"group" options:0 context:NULL];
    
    [self addObserver:self forKeyPath:@"x" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"y" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"w" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"h" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"alwaysOnTop" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"sizeToScreen" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"shadowWindow" options:0 context:NULL];
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"active"];
    
    [self removeObserver:self forKeyPath:@"name"];
    [self removeObserver:self forKeyPath:@"enabled"];
    [self removeObserver:self forKeyPath:@"group"];
    
    [self removeObserver:self forKeyPath:@"x"];
    [self removeObserver:self forKeyPath:@"y"];
    [self removeObserver:self forKeyPath:@"w"];
    [self removeObserver:self forKeyPath:@"h"];
    [self removeObserver:self forKeyPath:@"alwaysOnTop"];
    [self removeObserver:self forKeyPath:@"sizeToScreen"];
    [self removeObserver:self forKeyPath:@"shadowWindow"];
}

#pragma mark KVC
- (void)set_isBeingDragged:(BOOL)var
{
    static BOOL needCoordObservers = NO;
    _isBeingDragged = var;
    if (_isBeingDragged && !needCoordObservers)
    {
        [self removeObserver:self forKeyPath:@"x"];
        [self removeObserver:self forKeyPath:@"y"];
        [self removeObserver:self forKeyPath:@"w"];
        [self removeObserver:self forKeyPath:@"h"];
        needCoordObservers = YES;
    }
    else if (needCoordObservers)
    {
        [self addObserver:self forKeyPath:@"x" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        [self addObserver:self forKeyPath:@"y" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        [self addObserver:self forKeyPath:@"w" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        [self addObserver:self forKeyPath:@"h" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        needCoordObservers = NO;
    }
}

#pragma mark -
#pragma mark Log Process
#pragma mark -
#pragma mark Management
- (void)createLogProcess
{   
    self.windowController = [[NSWindowController alloc] initWithWindowNibName:[self displayNibName]];
    self.windowController.window = [windowController window];
    //[self.windowController window]; // this is only to make sure that the window is loaded. may not need t odo this
    
    self.window = (LogWindow *)[windowController window];
    window.parentLog = self;
    
    // TODO: make this env the same as a login env, with all the paths from approprite rc files
    // append app support folder to shell PATH
    NSProcessInfo *info = [NSProcessInfo processInfo];
    NSMutableDictionary *tmpEnv = [[info environment] mutableCopy];
    NSString *appendedPath = [NSString stringWithFormat:@"%@:%@",[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[info processName]],[tmpEnv objectForKey:@"PATH"]];
    [tmpEnv setObject:appendedPath forKey:@"PATH"]; 
    [tmpEnv setObject:@"xterm-color" forKey:@"TERM"];
    
    self.env = tmpEnv;
    
    [self setupProcessObservers];
    
    [tmpEnv release];
}

- (void)destroyLogProcess
{
    // removes process observers (they call notificationHandler:)
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [windowController close];
    self.windowController = nil;
    self.env = nil;
    
    self.arguments = nil;
    self.task = nil;
    self.timer = nil;
}

#pragma mark Observing
- (void)setupProcessObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:@"NSLogViewMouseDown" object:window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:NSWindowDidResizeNotification object:window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:NSWindowDidMoveNotification object:window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:@"NSLogViewMouseUp" object:window];
}

- (void)notificationHandler:(NSNotification *)notification
{    
    // when the resolution changes, don't change the window positions
    if (!NSEqualRects(_visibleFrame, [[[NSScreen screens] objectAtIndex:0] frame]))
    {
        _visibleFrame = [[[NSScreen screens] objectAtIndex:0] frame];
    }
    else if (([[notification name] isEqualToString:NSWindowDidResizeNotification] || [[notification name] isEqualToString:NSWindowDidMoveNotification]))
    {                
        NSRect newCoords = [self screenToRect:[[notification object] frame]];
        self.x = [NSNumber numberWithInt:NSMinX(newCoords)];
        self.y = [NSNumber numberWithInt:NSMinY(newCoords)];
        self.w = [NSNumber numberWithInt:NSWidth(newCoords)];
        self.h = [NSNumber numberWithInt:NSHeight(newCoords)];
    }
    else if ([[notification name] isEqualToString:@"NSLogViewMouseDown"])
        [self set_isBeingDragged:YES];
    else if ([[notification name] isEqualToString:@"NSLogViewMouseUp"])
        [self set_isBeingDragged:NO];
}

#pragma mark KVC
- (void)setTask:(NSTask*)newTask
{
    [task autorelease];
    if ([task isRunning]) [task terminate];
    task = [newTask retain];
}

#pragma mark Window Management
- (void)setHighlighted:(BOOL)val from:(id)sender
{
    highlightSender = sender;
    
    if (windowController) [[self window] setHighlighted:val];
    else postActivationRequest = YES;
}

- (void)front
{
    [window orderFront:self];
}

- (IBAction)attemptBestWindowSize:(id)sender
{
    NSSize bestFit = [[[window textView] attributedString] sizeForWidth:(([properties boolForKey:@"wrap"]) ? NSWidth([window frame]) : FLT_MAX) height:FLT_MAX];
    [window setContentSize:bestFit];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResizeNotification object:window];
    [window displayIfNeeded];
}

#pragma mark  
#pragma mark Convience
- (NSRect)screenToRect:(NSRect)appleCoordRect
{
    // remember, the coordinates we use are with respect to the top left corner (both window and screen), but the actual OS takes them with respect to the bottom left (both window and screen), so we must convert between these
    NSRect screenSize = [[[NSScreen screens] objectAtIndex:0] frame];
    return NSMakeRect(appleCoordRect.origin.x,(screenSize.size.height - appleCoordRect.origin.y - appleCoordRect.size.height),appleCoordRect.size.width,appleCoordRect.size.height);
}

- (NSRect)rect
{
    return NSMakeRect([self.x intValue],
                      [self.y intValue],
                      [self.w intValue],
                      [self.h intValue]);
}
@end
