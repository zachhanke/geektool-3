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

#pragma mark Properties
// Subclasses would probably want to override the following methods
- (NSString *)logTypeName
{
    return @"Box";
}

- (BOOL)needsDisplayUIBox
{
    return YES;
}

- (NSString *)preferenceNibName
{
    return @"";
}

- (NSString *)displayNibName
{
    return @"";
}

- (NSDictionary *)defaultProperties
{
    return [NSDictionary dictionary];
}

- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    return;
}

- (void)destroyInterfaceBindings
{
    return;
}

#pragma mark Window Management
- (void)updateWindowIncludingTimer:(BOOL)updateTimer
{
    NSRect newRect = [self screenToRect:[self rect]];
    if ([properties boolForKey:@"sizeToScreen"]) newRect = [[[NSScreen screens]objectAtIndex:0]frame];
    
    [window setFrame:newRect display:NO];
    
    NSRect tmpRect = [self rect];
    tmpRect.origin = NSZeroPoint;
    
    [window setHasShadow:[self.shadowWindow boolValue]];
    [window setLevel:[self.alwaysOnTop intValue]?kCGMaximumWindowLevel:kCGDesktopWindowLevel];
    [window setSticky:![self.alwaysOnTop boolValue]];
    
    /*
    if ([self needsDisplayUIBox])
    {
        [window setTextRect:tmpRect]; 
        [window setTextBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"backgroundColor"]]];
        [[window textView]updateTextAttributesUsingProps:properties];
        
        if (![properties boolForKey:@"useAsciiEscapes"] || !lastRecievedString) [[window textView]applyAttributes:[[window textView]attributes]];
        else [[window textView]processAndSetText:lastRecievedString withEscapes:YES andCustomColors:[self customAnsiColors] insert:NO];
    }
    */
    
    if (![window isVisible])
    {
        [self front];
        [parentGroup reorder];
    }
    postActivationRequest = YES;
    
    if (updateTimer) [self updateTimer];
    
    [window display];
}

#pragma mark -
#pragma mark Log Container
#pragma mark -

- (id)initWithProperties:(NSDictionary*)newProperties
{
	if (!(self = [super init])) return nil;
    
    [self setProperties:[NSMutableDictionary dictionaryWithDictionary:newProperties]];
    [self setActive:[NSNumber numberWithBool:NO]];
    
    _loadedView = NO;
    windowController = nil;
    highlightSender = nil;
    lastRecievedString = nil;
    _visibleFrame = [[[NSScreen screens]objectAtIndex:0]frame];
    
    [self setupPreferenceObservers];
    return self;
}

- (id)init
{    
    return [self initWithProperties:[self defaultProperties]];
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
    
    if (![self needsDisplayUIBox]) return;
    [self addObserver:self forKeyPath:@"font" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"stringEncoding" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"textColor" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"backgroundColor" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"wrap" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"alignment" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"shadowText" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"useAsciiEscapes" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBlack" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgRed" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgGreen" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgYellow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBlue" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgMagenta" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgCyan" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgWhite" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBlack" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgRed" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgGreen" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgYellow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBlue" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgMagenta" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgCyan" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgWhite" options:0 context:NULL];    
    [self addObserver:self forKeyPath:@"fgBrightBlack" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightRed" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightGreen" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightYellow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightBlue" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightMagenta" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightCyan" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"fgBrightWhite" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightBlack" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightRed" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightGreen" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightYellow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightBlue" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightMagenta" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightCyan" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"bgBrightWhite" options:0 context:NULL];    
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
    
    if (![self needsDisplayUIBox]) return;
    [self removeObserver:self forKeyPath:@"font"];
    [self removeObserver:self forKeyPath:@"stringEncoding"];
    [self removeObserver:self forKeyPath:@"textColor"];
    [self removeObserver:self forKeyPath:@"backgroundColor"];
    [self removeObserver:self forKeyPath:@"wrap"];
    [self removeObserver:self forKeyPath:@"alignment"];
    [self removeObserver:self forKeyPath:@"shadowText"];
    [self removeObserver:self forKeyPath:@"useAsciiEscapes"];
    [self removeObserver:self forKeyPath:@"fgBlack"];
    [self removeObserver:self forKeyPath:@"fgRed"];
    [self removeObserver:self forKeyPath:@"fgGreen"];
    [self removeObserver:self forKeyPath:@"fgYellow"];
    [self removeObserver:self forKeyPath:@"fgBlue"];
    [self removeObserver:self forKeyPath:@"fgMagenta"];
    [self removeObserver:self forKeyPath:@"fgCyan"];
    [self removeObserver:self forKeyPath:@"fgWhite"];
    [self removeObserver:self forKeyPath:@"bgBlack"];
    [self removeObserver:self forKeyPath:@"bgRed"];
    [self removeObserver:self forKeyPath:@"bgGreen"];
    [self removeObserver:self forKeyPath:@"bgYellow"];
    [self removeObserver:self forKeyPath:@"bgBlue"];
    [self removeObserver:self forKeyPath:@"bgMagenta"];
    [self removeObserver:self forKeyPath:@"bgCyan"];
    [self removeObserver:self forKeyPath:@"bgWhite"];    
    [self removeObserver:self forKeyPath:@"fgBrightBlack"];
    [self removeObserver:self forKeyPath:@"fgBrightRed"];
    [self removeObserver:self forKeyPath:@"fgBrightGreen"];
    [self removeObserver:self forKeyPath:@"fgBrightYellow"];
    [self removeObserver:self forKeyPath:@"fgBrightBlue"];
    [self removeObserver:self forKeyPath:@"fgBrightMagenta"];
    [self removeObserver:self forKeyPath:@"fgBrightCyan"];
    [self removeObserver:self forKeyPath:@"fgBrightWhite"];
    [self removeObserver:self forKeyPath:@"bgBrightBlack"];
    [self removeObserver:self forKeyPath:@"bgBrightRed"];
    [self removeObserver:self forKeyPath:@"bgBrightGreen"];
    [self removeObserver:self forKeyPath:@"bgBrightYellow"];
    [self removeObserver:self forKeyPath:@"bgBrightBlue"];
    [self removeObserver:self forKeyPath:@"bgBrightMagenta"];
    [self removeObserver:self forKeyPath:@"bgBrightCyan"];
    [self removeObserver:self forKeyPath:@"bgBrightWhite"];    
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
    NSWindowController *winCtrl = [[NSWindowController alloc]initWithWindowNibName:[self displayNibName]];
    [self setWindowController:winCtrl];
    [self setWindow:(LogWindow *)[windowController window]];
    [window setParentLog:self];
    
    // append app support folder to shell PATH
    NSMutableDictionary *tmpEnv = [[NSMutableDictionary alloc]initWithDictionary:[[NSProcessInfo processInfo]environment]];
    NSString *appendedPath = [NSString stringWithFormat:@"%@:%@",[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES) objectAtIndex:0]stringByAppendingPathComponent:[[NSProcessInfo processInfo]processName]],[tmpEnv objectForKey:@"PATH"]];
    [tmpEnv setObject:appendedPath forKey:@"PATH"]; 
    [tmpEnv setObject:@"xterm-color" forKey:@"TERM"];
    [self setEnv:tmpEnv];
    
    [self setupProcessObservers];
    
    [winCtrl release];
    [tmpEnv release];
}

- (void)destroyLogProcess
{
    // removes process observers (they call notificationHandler:)
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [windowController close];
    [self setWindowController:nil];
    [self setEnv:nil];
    
    [self setArguments:nil];
    [self setTask:nil];
    [self setTimer:nil];
}

#pragma mark Observing
- (void)setupProcessObservers
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:@"NSLogViewMouseDown" object:window];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:NSWindowDidResizeNotification object:window];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:NSWindowDidMoveNotification object:window];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:@"NSLogViewMouseUp" object:window];
}

- (void)notificationHandler:(NSNotification *)notification
{    
    // when the resolution changes, don't change the window positions
    if (!NSEqualRects(_visibleFrame,[[[NSScreen screens]objectAtIndex:0]frame]))
    {
        _visibleFrame = [[[NSScreen screens]objectAtIndex:0]frame];
    }
    else if (([[notification name]isEqualToString:NSWindowDidResizeNotification] || [[notification name]isEqualToString:NSWindowDidMoveNotification]))
    {                
        NSRect newCoords = [self screenToRect:[[notification object]frame]];
        [properties setValue:[NSNumber numberWithInt:NSMinX(newCoords)] forKey:@"x"];
        [properties setValue:[NSNumber numberWithInt:NSMinY(newCoords)] forKey:@"y"];
        [properties setValue:[NSNumber numberWithInt:NSWidth(newCoords)] forKey:@"w"];
        [properties setValue:[NSNumber numberWithInt:NSHeight(newCoords)] forKey:@"h"];
    }
    else if ([[notification name]isEqualToString:@"NSLogViewMouseDown"])
        [self set_isBeingDragged:YES];
    else if ([[notification name]isEqualToString:@"NSLogViewMouseUp"])
        [self set_isBeingDragged:NO];
}

#pragma mark KVC
- (void)setTask:(NSTask*)newTask
{
    [task autorelease];
    if ([task isRunning]) [task terminate];
    task = [newTask retain];
}

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
    int refreshTime = [[self properties]integerForKey:@"refresh"];
    BOOL timerRepeats = refreshTime?YES:NO;
    
    [self setTimer:[NSTimer scheduledTimerWithTimeInterval:refreshTime target:self selector:@selector(updateCommand:) userInfo:nil repeats:timerRepeats]];
    [timer fire];
    
    if (timerRepeats) [self release]; // since timer repeats, self is retained. we don't want this
    else [self setTimer:nil];
}

#pragma mark Window Management
- (void)setHighlighted:(BOOL)val from:(id)sender
{
    highlightSender = sender;
    
    if (windowController) [[self window]setHighlighted:val];
    else postActivationRequest = YES;
}

- (void)front
{
    [window orderFront:self];
}

- (IBAction)attemptBestWindowSize:(id)sender
{
    NSSize bestFit = [[[window textView]attributedString] sizeForWidth:[properties boolForKey:@"wrap"]?NSWidth([window frame]):FLT_MAX height:FLT_MAX];
    [window setContentSize:bestFit];
    [[NSNotificationCenter defaultCenter]postNotificationName:NSWindowDidResizeNotification object:window];
    [window displayIfNeeded];
}

#pragma mark  
#pragma mark Convience
- (NSDictionary*)customAnsiColors
{
    NSDictionary *colors = [[NSDictionary alloc]initWithObjectsAndKeys:
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBlack"]],[NSNumber numberWithInt:SGRCodeFgBlack],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgRed"]],[NSNumber numberWithInt:SGRCodeFgRed],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgGreen"]],[NSNumber numberWithInt:SGRCodeFgGreen],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgYellow"]],[NSNumber numberWithInt:SGRCodeFgYellow],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBlue"]],[NSNumber numberWithInt:SGRCodeFgBlue],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgMagenta"]],[NSNumber numberWithInt:SGRCodeFgMagenta],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgCyan"]],[NSNumber numberWithInt:SGRCodeFgCyan],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgWhite"]],[NSNumber numberWithInt:SGRCodeFgWhite],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBlack"]],[NSNumber numberWithInt:SGRCodeBgBlack],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgRed"]],[NSNumber numberWithInt:SGRCodeBgRed],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgGreen"]],[NSNumber numberWithInt:SGRCodeBgGreen],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgYellow"]],[NSNumber numberWithInt:SGRCodeBgYellow],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBlue"]],[NSNumber numberWithInt:SGRCodeBgBlue],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgMagenta"]],[NSNumber numberWithInt:SGRCodeBgMagenta],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgCyan"]],[NSNumber numberWithInt:SGRCodeBgCyan],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgWhite"]],[NSNumber numberWithInt:SGRCodeBgWhite],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBrightBlack"]],[NSNumber numberWithInt:SGRCodeFgBrightBlack],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBrightRed"]],[NSNumber numberWithInt:SGRCodeFgBrightRed],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBrightGreen"]],[NSNumber numberWithInt:SGRCodeFgBrightGreen],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBrightYellow"]],[NSNumber numberWithInt:SGRCodeFgBrightYellow],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBrightBlue"]],[NSNumber numberWithInt:SGRCodeFgBrightBlue],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBrightMagenta"]],[NSNumber numberWithInt:SGRCodeFgBrightMagenta],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBrightCyan"]],[NSNumber numberWithInt:SGRCodeFgBrightCyan],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBrightWhite"]],[NSNumber numberWithInt:SGRCodeFgBrightWhite],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBrightBlack"]],[NSNumber numberWithInt:SGRCodeBgBrightBlack],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBrightRed"]],[NSNumber numberWithInt:SGRCodeBgBrightRed],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBrightGreen"]],[NSNumber numberWithInt:SGRCodeBgBrightGreen],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBrightYellow"]],[NSNumber numberWithInt:SGRCodeBgBrightYellow],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBrightBlue"]],[NSNumber numberWithInt:SGRCodeBgBrightBlue],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBrightMagenta"]],[NSNumber numberWithInt:SGRCodeBgBrightMagenta],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBrightCyan"]],[NSNumber numberWithInt:SGRCodeBgBrightCyan],
                            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBrightWhite"]],[NSNumber numberWithInt:SGRCodeBgBrightWhite],
                            nil];
    return [colors autorelease];
    
}

- (NSRect)screenToRect:(NSRect)appleCoordRect
{
    // remember, the coordinates we use are with respect to the top left corner (both window and screen), but the actual OS takes them with respect to the bottom left (both window and screen), so we must convert between these
    NSRect screenSize = [[[NSScreen screens]objectAtIndex:0]frame];
    return NSMakeRect(appleCoordRect.origin.x,(screenSize.size.height - appleCoordRect.origin.y - appleCoordRect.size.height),appleCoordRect.size.width,appleCoordRect.size.height);
}

- (NSRect)rect
{
    return NSMakeRect([properties integerForKey:@"x"],
                      [properties integerForKey:@"y"],
                      [properties integerForKey:@"w"],
                      [properties integerForKey:@"h"]);
}

- (BOOL)equals:(NTLog*)comp
{
    if ([[self properties]isEqualTo:[comp properties]]) return YES;
    else return NO;
}

- (NSString*)description
{
    return [NSString stringWithFormat: @"Log (%@):[%@]%@",[self logTypeName],[[[self properties]objectForKey:@"enabled"]boolValue]?@"X":@" ",[[self properties]objectForKey:@"name"]];
}

#pragma mark Copying
- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class]allocWithZone:zone]initWithProperties:[self properties]];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [self copyWithZone:zone];
}

#pragma mark Coding
- (id)initWithCoder:(NSCoder *)coder
{
    // allows object to change properties and still function properly. Old, unused properties are NOT deleted.
    id tmpObject = [self init];
    NSMutableDictionary *loadedProps = [coder decodeObjectForKey:@"properties"];
    [properties addEntriesFromDictionary:loadedProps];
    
    return tmpObject;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:properties forKey:@"properties"];
}
@end
