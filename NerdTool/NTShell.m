//
//  NTShell.m
//  NerdTool
//
//  Created by Kevin Nygaard on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTShell.h"
#import "LogWindow.h"
#import "LogTextField.h"
#import "NTGroup.h"

#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"

@implementation NTShell

@synthesize properties;
@synthesize parentGroup;
@synthesize active;
@synthesize _isBeingDragged;

@synthesize _windowController;
@synthesize window;
@synthesize _env;
@synthesize _arguments;
@synthesize _task;
@synthesize _timer;

#pragma mark Protocol Methods
- (BOOL)needsDisplayUIBox
{
    return YES;
}

- (NSView *)loadPrefsViewAndBind:(id)bindee
{
    if (_loadedView) return nil;
    if (!prefsView) [NSBundle loadNibNamed:@"shellPrefs" owner:self];
    
    // These can get turned off if you have the text field selected, and then change logs. When you go back to that log, things are screwed up. The setEditable: fixes this (as well as makes them tasty :P)
    [command setEditable:YES];
    [refresh setEditable:YES];

    [command bind:@"value" toObject:bindee withKeyPath:@"selection.properties.command" options:nil];
    [refresh bind:@"value" toObject:bindee withKeyPath:@"selection.properties.refresh" options:nil];
    
    _loadedView = YES;
    return prefsView;
}

- (NSView *)unloadPrefsViewAndUnbind
{
    if (!_loadedView) return nil;
    [command unbind:@"value"];
    [refresh unbind:@"value"];
    
    _loadedView = NO;
    return prefsView;
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
    _windowController = nil;
    [self setupPreferenceObservers];
    return self;
}

- (id)init
{    
    NSData *textColorData = [NSArchiver archivedDataWithRootObject:[NSColor blackColor]];
    NSData *backgroundColorData = [NSArchiver archivedDataWithRootObject:[NSColor clearColor]]; 
    
    NSMutableDictionary *defaultProperties = [[[NSMutableDictionary alloc]initWithObjectsAndKeys:
                                               NSLocalizedString(@"New log",nil),@"name",
                                               [NSNumber numberWithInt:TYPE_SHELL],@"type",
                                               [NSNumber numberWithBool:YES],@"enabled",
                                               NSLocalizedString(@"Default",nil),@"group",
                                               
                                               @"Monaco",@"fontName",
                                               [NSNumber numberWithFloat:12],@"fontSize",
                                               
                                               @"date",@"command",
                                               [NSNumber numberWithInt:10],@"refresh",
                                               
                                               textColorData,@"textColor",
                                               backgroundColorData,@"backgroundColor",
                                               [NSNumber numberWithBool:NO],@"wrap",
                                               [NSNumber numberWithBool:NO],@"shadowText",
                                               [NSNumber numberWithBool:NO],@"shadowWindow",
                                               [NSNumber numberWithBool:NO],@"useAsciiEscapes",
                                               [NSNumber numberWithInt:ALIGN_LEFT],@"alignment",
                                               
                                               [NSNumber numberWithInt:16],@"x",
                                               [NSNumber numberWithInt:38],@"y",
                                               [NSNumber numberWithInt:280],@"w",
                                               [NSNumber numberWithInt:150],@"h",
                                               
                                               [NSNumber numberWithBool:NO],@"alwaysOnTop",
                                               nil]autorelease];    
    
    return [self initWithProperties:defaultProperties];;
}    

- (void)dealloc
{
    [self removePreferenceObservers];    
    [self destroyLogProcess];
    [properties release];
    [active release];
    [super dealloc];
}

#pragma mark Observing
- (void)setupPreferenceObservers
{
    [self addObserver:self forKeyPath:@"active" options:0 context:NULL];
    
    [self addObserver:self forKeyPath:@"properties.name" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.enabled" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.group" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.fontName" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.fontSize" options:0 context:NULL];
    
    [self addObserver:self forKeyPath:@"properties.command" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.refresh" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.textColor" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.backgroundColor" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.wrap" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.alignment" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.shadowText" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.shadowWindow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.useAsciiEscapes" options:0 context:NULL];
    
    [self addObserver:self forKeyPath:@"properties.x" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.y" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.w" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.h" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.alwaysOnTop" options:0 context:NULL];        
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"active"];
    
    [self removeObserver:self forKeyPath:@"properties.name"];
    [self removeObserver:self forKeyPath:@"properties.enabled"];
    [self removeObserver:self forKeyPath:@"properties.group"];
    [self removeObserver:self forKeyPath:@"properties.fontName"];
    [self removeObserver:self forKeyPath:@"properties.fontSize"];
    
    [self removeObserver:self forKeyPath:@"properties.command"];
    [self removeObserver:self forKeyPath:@"properties.refresh"];
    [self removeObserver:self forKeyPath:@"properties.textColor"];
    [self removeObserver:self forKeyPath:@"properties.backgroundColor"];
    [self removeObserver:self forKeyPath:@"properties.wrap"];
    [self removeObserver:self forKeyPath:@"properties.alignment"];
    [self removeObserver:self forKeyPath:@"properties.shadowText"];
    [self removeObserver:self forKeyPath:@"properties.shadowWindow"];
    [self removeObserver:self forKeyPath:@"properties.useAsciiEscapes"];
    
    [self removeObserver:self forKeyPath:@"properties.x"];
    [self removeObserver:self forKeyPath:@"properties.y"];
    [self removeObserver:self forKeyPath:@"properties.w"];
    [self removeObserver:self forKeyPath:@"properties.h"];
    [self removeObserver:self forKeyPath:@"properties.alwaysOnTop"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"properties.enabled"] || [keyPath isEqualToString:@"active"])
    {
        if (_windowController) [self destroyLogProcess];
        if (![[self active]boolValue] || ![properties boolForKey:@"enabled"]) return;
        
        [self createLogProcess];
        [self setupLogWindowAndDisplay];
    }
    // check if our LogProcess is alive
    else if (!_windowController) return;
    else if ([keyPath isEqualToString:@"properties.shadowWindow"] || [keyPath isEqualToString:@"properties.command"])
    {
        [self setupLogWindowAndDisplay];
    }
    else if ([keyPath isEqualToString:@"properties.refresh"])
    {
        _timerNeedsUpdate = YES;
        [self updateWindow];
    }
    else
    {
        _timerNeedsUpdate = NO;
        [self updateWindow];
    }
    
    if (_postActivationRequest)
    {
        _postActivationRequest = NO;
        [_highlightSender observeValueForKeyPath:@"selectedObjects" ofObject:self change:nil context:nil];
    }
}

#pragma mark KVC
- (void)set_isBeingDragged:(BOOL)var
{
    static BOOL needCoordObservers = NO;
    _isBeingDragged = var;
    if (_isBeingDragged && !needCoordObservers)
    {
        [self removeObserver:self forKeyPath:@"properties.x"];
        [self removeObserver:self forKeyPath:@"properties.y"];
        [self removeObserver:self forKeyPath:@"properties.w"];
        [self removeObserver:self forKeyPath:@"properties.h"];
        needCoordObservers = YES;
    }
    else if (needCoordObservers)
    {
        [self addObserver:self forKeyPath:@"properties.x" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        [self addObserver:self forKeyPath:@"properties.y" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        [self addObserver:self forKeyPath:@"properties.w" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        [self addObserver:self forKeyPath:@"properties.h" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        needCoordObservers = NO;
    }
}

#pragma mark -
#pragma mark Log Process
#pragma mark -
- (void)createLogProcess
{    
    [self set_windowController:[[[NSWindowController alloc]initWithWindowNibName:@"shellWindow"]autorelease]];
    [self setWindow:(LogWindow *)[_windowController window]];
    [window setParentLog:self];
    
    // append app support folder to shell PATH
    NSMutableDictionary *tmpEnv = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo]environment]];
    NSString *appendedPath = [NSString stringWithFormat:@"%@:%@",[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES) objectAtIndex:0]stringByAppendingPathComponent:[[NSProcessInfo processInfo]processName]],[tmpEnv objectForKey:@"PATH"]];
    [tmpEnv setObject:appendedPath forKey:@"PATH"]; 
    [tmpEnv setObject:@"xterm-color" forKey:@"TERM"];
    [self set_env:tmpEnv];
    
    [self setupProcessObservers];
}

- (void)destroyLogProcess
{
    [self removeProcessObservers];
    [_windowController close];
    [self set_windowController:nil];
    [self set_env:nil];
    
    [self set_arguments:nil];
    [self set_task:nil];
    [self set_timer:nil];
}

#pragma mark Observing
- (void)setupProcessObservers
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:@"NSLogViewMouseDown" object:window];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:NSWindowDidResizeNotification object:window];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:NSWindowDidMoveNotification object:window];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:@"NSLogViewMouseUp" object:window];
}

- (void)removeProcessObservers
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)notificationHandler:(NSNotification *)notification
{
    if (([[notification name]isEqualToString:NSWindowDidResizeNotification] || [[notification name]isEqualToString:NSWindowDidMoveNotification]))
    {
        // this happens on init, which screws things up
        if (!_isBeingDragged) return;
        
        NSRect newCoords = [self screenToRect:[[notification object]frame]];
        [properties setValue:[NSNumber numberWithInt:NSMinX(newCoords)] forKey:@"x"];
        [properties setValue:[NSNumber numberWithInt:NSMinY(newCoords)] forKey:@"y"];
        [properties setValue:[NSNumber numberWithInt:NSWidth(newCoords)] forKey:@"w"];
        [properties setValue:[NSNumber numberWithInt:NSHeight(newCoords)] forKey:@"h"];
    }
    else if ([[notification name]isEqualToString:@"NSLogViewMouseDown"])
        self._isBeingDragged = YES;
    else if ([[notification name]isEqualToString:@"NSLogViewMouseUp"])
        self._isBeingDragged = NO;
}

#pragma mark KVC
- (void)set_timer:(NSTimer*)newTimer
{
    [_timer autorelease];
    if ([_timer isValid])
    {
        [self retain]; // to counter our balancing done in updateTimer
        [_timer invalidate];
    }
    _timer = [newTimer retain];
}

- (void)killTimer
{
    if (!_timer) return;
    [self set_timer:nil];
}

- (void)updateTimer
{
    int refreshTime = [[self properties]integerForKey:@"refresh"];
    BOOL timerRepeats = refreshTime?YES:NO;
    
    [self set_timer:[NSTimer scheduledTimerWithTimeInterval:refreshTime target:self selector:@selector(updateCommand:) userInfo:nil repeats:timerRepeats]];
    [_timer fire];

    if (timerRepeats) [self release]; // since timer repeats, self is retained. we don't want this
    else [self set_timer:nil];
    _timerNeedsUpdate = NO;
}

#pragma mark Window Creation/Management
- (void)setupLogWindowAndDisplay
{
    _timerNeedsUpdate = YES;
    [self createWindow];
    [self updateWindow];
}

- (void)createWindow
{        
    [window setHasShadow:[[self properties]boolForKey:@"shadowWindow"]];
}

- (void)updateWindow
{
    //==Pre-init==
    NSRect tmpRect = [self rect];
    [window setFrame:[self screenToRect:tmpRect] display:NO];
    
    tmpRect.origin.x = 0;
    tmpRect.origin.y = 0;
    [window setTextRect:tmpRect]; 
    
    [window setLevel:(([[self properties]integerForKey:@"alwaysOnTop"])?[[self properties]integerForKey:@"alwaysOnTop"]:kCGDesktopWindowLevel)];
    [window setSticky:(![[self properties]boolForKey:@"alwaysOnTop"])];
    
    //==Init==
    [window setTextBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"backgroundColor"]]];
    [[window textView]updateTextAttributesUsingProps:properties];
    if (![properties boolForKey:@"useAsciiEscapes"]) [[window textView]applyAttributes:[[window textView]attributes]];
    else
    {
        NSMutableAttributedString *attrStr = [[[[window textView]attributedString]mutableCopy]autorelease];
        for (NSString *key in [[window textView]attributes])
        {
            if ([key isEqualToString:NSForegroundColorAttributeName]) continue;
            [attrStr addAttribute:key value:[[[window textView]attributes] valueForKey:key] range:NSMakeRange(0,[[attrStr string]length])];
        }
        [[[window textView]textStorage]setAttributedString:attrStr];
    }
    
    if (_timerNeedsUpdate)
    {
        [self set_arguments:[[[NSArray alloc]initWithObjects:@"-c",[[self properties]objectForKey:@"command"],nil]autorelease]];
        
        [[window textView]setString:@""];
        [self updateTimer];
    }
    
    //==Post-Init==
    if (![window isVisible])
    {
        [self front];
        [parentGroup reorder];
    }
    _postActivationRequest = YES;
}

#pragma mark Task
- (void)updateCommand:(NSTimer*)timer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    if (_task && [_task isRunning]) return;
    
    [self set_task:[[[NSTask alloc]init]autorelease]];
    NSPipe *pipe = [NSPipe pipe];
    
    [_task setLaunchPath:@"/bin/sh"];
    [_task setArguments:_arguments];
    [_task setEnvironment:_env];
    [_task setStandardOutput:pipe];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:NSFileHandleReadToEndOfFileCompletionNotification object:[pipe fileHandleForReading]];
    
    [[pipe fileHandleForReading]readToEndOfFileInBackgroundAndNotify];
    
    [_task launch];
    [pool release];
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
    
    if ([newString isEqualTo:@""]) return;
    
    [[window textView]processAndSetText:newString withEscapes:[[self properties]boolForKey:@"useAsciiEscapes"]];
    [[window textView]scrollEnd];
    
    [[aNotification object]readInBackgroundAndNotify];
    [window display];
}
#pragma mark Window operations
- (void)front
{
    [window orderFront:self];
}

#pragma mark Convience
- (NSRect)screenToRect:(NSRect)appleCoordRect
{
    // remember, the coordinates we use are with respect to the top left corner (both window and screen), but the actual OS takes them with respect to the bottom left (both window and screen), so we must convert between these
    NSRect screenSize = [[NSScreen mainScreen] frame];
    return NSMakeRect(appleCoordRect.origin.x,(screenSize.size.height - appleCoordRect.origin.y - appleCoordRect.size.height),appleCoordRect.size.width,appleCoordRect.size.height);
}

- (NSRect)rect
{
    return NSMakeRect([properties integerForKey:@"x"],
                      [properties integerForKey:@"y"],
                      [properties integerForKey:@"w"],
                      [properties integerForKey:@"h"]);
}

#pragma mark Misc
- (void)setHighlighted:(BOOL)val from:(id)sender
{
    _highlightSender = sender;
    
    if (_windowController) [[self window]setHighlighted:val];
    else _postActivationRequest = YES;
}

- (BOOL)equals:(NTShell*)comp
{
    if ([[self properties]isEqualTo:[comp properties]]) return YES;
    else return NO;
}

- (NSString*)description
{
    return [NSString stringWithFormat: @"Log:[%@]%@",[[[self properties]objectForKey:@"enabled"]boolValue]?@"X":@" ",[[self properties]objectForKey:@"name"]];
}

#pragma mark  
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
    return [self initWithProperties:[coder decodeObjectForKey:@"properties"]];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:properties forKey:@"properties"];
}

@end
