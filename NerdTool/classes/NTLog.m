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
#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"
#import "NTTextBasedLog.h"
#import "NSWindow+StickyWindow.h"

#import "NTGroup.h"
#import "LogWindow.h"
#import "LogTextField.h"
#import "ANSIEscapeHelper.h"


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

// Standard Properties
@synthesize windowController;
@synthesize window;

@synthesize prefsView;

@synthesize arguments;
@synthesize env;
@synthesize timer;
@synthesize task;

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
- (void)updateWindowIncludingTimer:(BOOL)updateTimer
{
    // exit if we don't have a window
    if (!self.windowController) {NSLog(@"[%@] >> Updating window failed. No window controller.",self); return;}
    if (![self.windowController window]) {NSLog(@"[%@] >> Updating window failed. No window.",self); return;}
    
    // change the window size
    NSRect newRect = [self screenToRect:[self rect]];
    if ([self.sizeToScreen boolValue]) newRect = [[[NSScreen screens] objectAtIndex:0] frame];
    [self.window setFrame:newRect display:NO];
        
    // set various attributes
    [self.window setHasShadow:[self.shadowWindow boolValue]];
    [self.window setLevel:[self.alwaysOnTop boolValue] ? kCGMaximumWindowLevel : kCGDesktopIconWindowLevel];
    [self.window setSticky:![self.alwaysOnTop boolValue]];
}

#pragma mark -
- (void)awakeFromInsert
{
    [super awakeFromFetch];

    [self createLog];
}

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    
    [self createLog];
}

// this function as the -init method. This represents a log that is ready to go and interacted with, though not necessarily selected, enabled, or visible. For that, see -createLogProcess
- (void)createLog
{
    self.windowController = nil;
    _loadedView = NO;
    _visibleFrame = [[[NSScreen screens] objectAtIndex:0] frame];
    
    // the following are not in -setupPreferenceObservers because they should be always active as long as the log is
    //[self addObserver:self forKeyPath:@"name" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"effectiveEnabled" options:0 context:NULL];
}

- (void)destroyLog
{
    //[self removeObserver:self forKeyPath:@"name"];
    [self removeObserver:self forKeyPath:@"effectiveEnabled"];
    [self destroyLogProcess];
}

#pragma mark Interface
- (NSView *)loadPrefsViewAndBind:(id)bindee
{
    // return nil if we have already loaded the prefs
    if (_loadedView) return nil;
    if (!prefsView) [NSBundle loadNibNamed:[self preferenceNibName] owner:self];
    
    [self setupInterfaceBindingsWithObject:bindee];
        
    _loadedView = YES;
    return prefsView;
}

- (NSView *)unloadPrefsViewAndUnbind
{
    // if we don't have any prefs to unbind, return nil
    if (!_loadedView) return nil;
    
    [self destroyInterfaceBindings];
    
    _loadedView = NO;
    return prefsView;
}

- (void)setupPreferenceObservers
{    
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
#pragma mark Process Creation/Destruction
- (BOOL)createLogProcess
{   
    NSLog(@"[%@] Creating log process.",self);
    if (![self createWindow]) {NSLog(@"[%@] >> Log process creation failed. Window already created.",self); return FALSE;} // if we didn't create a window, bail
    [self createEnv];
    [self setupProcessObservers];
    
    return TRUE;
}

- (BOOL)destroyLogProcess
{    
    NSLog(@"[%@] Destroying log process",self);
    if (![self destroyWindow]) {NSLog(@"[%@] >> Log process destruction failed. Window already destroyed.",self); return FALSE;} // if we didn't destroy a window, bail
    [self destroyEnv];
    [self removeProcessObservers];
    
    self.arguments = nil;
    self.task = nil;
    self.timer = nil;
    return TRUE;
}

#pragma mark Window Creation/Destruction

// create a window for the log to use. 
- (BOOL)createWindow
{
    if (self.windowController) return FALSE;
    self.windowController = [[NSWindowController alloc] initWithWindowNibName:[self displayNibName]];    
    self.window = (LogWindow *)[windowController window];
    window.parentLog = self;
    [self.window display];
    
    NSLog(@"[%@] >> Window created.", self);
    return TRUE;
}

- (BOOL)destroyWindow
{
    if (!self.windowController) return FALSE;
    [windowController close];
    self.windowController = nil;
    
    NSLog(@"[%@] >> Window destroyed.", self);
    return TRUE;
}

#pragma mark Environment Creation/Destruction
- (void)createEnv
{
    NSProcessInfo *info = [NSProcessInfo processInfo];
    NSMutableDictionary *tmpEnv = [[info environment] mutableCopy];
    NSString *appendedPath = [NSString stringWithFormat:@"%@:%@",[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[info processName]],[tmpEnv objectForKey:@"PATH"]];
    [tmpEnv setObject:appendedPath forKey:@"PATH"]; 
    [tmpEnv setObject:@"xterm-color" forKey:@"TERM"];
    [tmpEnv setObject:@"1" forKey:@"NERDTOOL"];
    
    self.env = tmpEnv;
    [tmpEnv release];
}

- (void)destroyEnv
{
    self.env = nil;
}

#pragma mark Observing Creation/Destruction
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

- (void)removeProcessObservers
{
    // removes process observers (they call notificationHandler:)
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark KVC
- (void)setTask:(NSTask*)newTask
{
    [task autorelease];
    if ([task isRunning]) [task terminate];
    task = [newTask retain];
}

#pragma mark Window Management
- (BOOL)setHighlighted:(BOOL)val from:(id)sender
{
    if (!self.windowController) return FALSE;
    [[self window] setHighlighted:val];
    return TRUE;
}

- (BOOL)front
{
    if (!self.windowController) return FALSE;
    [self.window orderFront:self];
    return TRUE;
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
