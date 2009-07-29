//
//  NTLog.m
//  NerdTool
//
//  Created by Kevin Nygaard on 7/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTLog.h"
#import "LogWindow.h"
#import "LogTextField.h"
#import "NTGroup.h"
#import "ANSIEscapeHelper.h"

#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"

@implementation NTLog

@synthesize properties;
@synthesize active;
@synthesize parentGroup;

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
@synthesize timerNeedsUpdate;

#pragma mark -
#pragma mark Most likely to subclass
#pragma mark -
#pragma mark Properties
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
    return @"shellPrefs";
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
                                       NSLocalizedString(@"New box log",nil),@"name",
                                       [NSNumber numberWithBool:YES],@"enabled",
                                       
                                       [NSNumber numberWithInt:16],@"x",
                                       [NSNumber numberWithInt:38],@"y",
                                       [NSNumber numberWithInt:280],@"w",
                                       [NSNumber numberWithInt:150],@"h",
                                       [NSNumber numberWithBool:NO],@"alwaysOnTop",
                                       
                                       font,@"font",
                                       textColorData,@"textColor",
                                       backgroundColorData,@"backgroundColor",
                                       [NSNumber numberWithBool:NO],@"wrap",
                                       [NSNumber numberWithBool:NO],@"shadowText",
                                       [NSNumber numberWithBool:NO],@"shadowWindow",
                                       [NSNumber numberWithBool:NO],@"useAsciiEscapes",
                                       [NSNumber numberWithInt:ALIGN_LEFT],@"alignment",
                                       
                                       [NSArchiver archivedDataWithRootObject:[NSColor blackColor]]  ,@"fgBlack",
                                       [NSArchiver archivedDataWithRootObject:[NSColor redColor]]    ,@"fgRed",
                                       [NSArchiver archivedDataWithRootObject:[NSColor greenColor]]  ,@"fgGreen",
                                       [NSArchiver archivedDataWithRootObject:[NSColor yellowColor]] ,@"fgYellow",
                                       [NSArchiver archivedDataWithRootObject:[NSColor blueColor]]   ,@"fgBlue",
                                       [NSArchiver archivedDataWithRootObject:[NSColor magentaColor]],@"fgMagenta",
                                       [NSArchiver archivedDataWithRootObject:[NSColor cyanColor]]   ,@"fgCyan",
                                       [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]]  ,@"fgWhite",
                                       [NSArchiver archivedDataWithRootObject:[NSColor blackColor]]  ,@"bgBlack",
                                       [NSArchiver archivedDataWithRootObject:[NSColor redColor]]    ,@"bgRed",
                                       [NSArchiver archivedDataWithRootObject:[NSColor greenColor]]  ,@"bgGreen",
                                       [NSArchiver archivedDataWithRootObject:[NSColor yellowColor]] ,@"bgYellow",
                                       [NSArchiver archivedDataWithRootObject:[NSColor blueColor]]   ,@"bgBlue",
                                       [NSArchiver archivedDataWithRootObject:[NSColor magentaColor]],@"bgMagenta",
                                       [NSArchiver archivedDataWithRootObject:[NSColor cyanColor]]   ,@"bgCyan",
                                       [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]]  ,@"bgWhite",
                                       nil];
    
    return [defaultProperties autorelease];
}

#pragma mark Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    return;
}

- (void)destroyInterfaceBindings
{
    return;
}

#pragma mark Observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"properties.enabled"] || [keyPath isEqualToString:@"active"])
    {
        if (windowController) [self destroyLogProcess];
        if (![[self active]boolValue] || ![properties boolForKey:@"enabled"]) return;
        
        [self createLogProcess];
        [self setEnv:nil];
        [self setupLogWindowAndDisplay];
    }
    // check if our LogProcess is alive
    else if (!windowController) return;
    else if ([keyPath isEqualToString:@"properties.shadowWindow"])
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
        [highlightSender observeValueForKeyPath:@"selectedObjects" ofObject:self change:nil context:nil];
    }
}

#pragma mark Window Management
- (void)createWindow
{        
    [window setHasShadow:[[self properties]boolForKey:@"shadowWindow"]];
}

- (void)updateWindow
{
    NSRect tmpRect = [self rect];
    [window setFrame:[self screenToRect:tmpRect] display:NO];
    
    tmpRect.origin.x = 0;
    tmpRect.origin.y = 0;
    
    [window setLevel:[[self properties]integerForKey:@"alwaysOnTop"]?[[self properties]integerForKey:@"alwaysOnTop"]:kCGDesktopWindowLevel];
    [window setSticky:![[self properties]boolForKey:@"alwaysOnTop"]];
    
    
    if ([self needsDisplayUIBox])
    {
        [window setTextRect:tmpRect]; 
        [window setTextBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"backgroundColor"]]];
        [[window textView]updateTextAttributesUsingProps:properties];
        
        if (![properties boolForKey:@"useAsciiEscapes"]) [[window textView]applyAttributes:[[window textView]attributes]];
        else [[[window textView]textStorage]setAttributedString:[[window textView]combineAttributes:[[window textView]attributes] withAttributedString:[[window textView]attributedString]]];
    }
    
    if (![window isVisible])
    {
        [self front];
        [parentGroup reorder];
    }
    postActivationRequest = YES;
}

#pragma mark Task
- (void)updateCommand:(NSTimer*)timer
{
    return;
}

- (void)processNewDataFromTask:(NSNotification*)aNotification
{
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
    
    [self addObserver:self forKeyPath:@"properties.name" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.enabled" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.group" options:0 context:NULL];
    
    [self addObserver:self forKeyPath:@"properties.x" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.y" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.w" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.h" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.alwaysOnTop" options:0 context:NULL];        
    [self addObserver:self forKeyPath:@"properties.shadowWindow" options:0 context:NULL];
    
    if (![self needsDisplayUIBox]) return;
    [self addObserver:self forKeyPath:@"properties.font" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.textColor" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.backgroundColor" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.wrap" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.alignment" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.shadowText" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.useAsciiEscapes" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.fgBlack" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.fgRed" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.fgGreen" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.fgYellow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.fgBlue" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.fgMagenta" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.fgCyan" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.fgWhite" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.bgBlack" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.bgRed" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.bgGreen" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.bgYellow" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.bgBlue" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.bgMagenta" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.bgCyan" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.bgWhite" options:0 context:NULL];    
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"active"];
    
    [self removeObserver:self forKeyPath:@"properties.name"];
    [self removeObserver:self forKeyPath:@"properties.enabled"];
    [self removeObserver:self forKeyPath:@"properties.group"];
    
    [self removeObserver:self forKeyPath:@"properties.x"];
    [self removeObserver:self forKeyPath:@"properties.y"];
    [self removeObserver:self forKeyPath:@"properties.w"];
    [self removeObserver:self forKeyPath:@"properties.h"];
    [self removeObserver:self forKeyPath:@"properties.alwaysOnTop"];
    [self removeObserver:self forKeyPath:@"properties.shadowWindow"];
    
    if (![self needsDisplayUIBox]) return;
    [self removeObserver:self forKeyPath:@"properties.font"];
    [self removeObserver:self forKeyPath:@"properties.textColor"];
    [self removeObserver:self forKeyPath:@"properties.backgroundColor"];
    [self removeObserver:self forKeyPath:@"properties.wrap"];
    [self removeObserver:self forKeyPath:@"properties.alignment"];
    [self removeObserver:self forKeyPath:@"properties.shadowText"];
    [self removeObserver:self forKeyPath:@"properties.useAsciiEscapes"];
    [self removeObserver:self forKeyPath:@"properties.fgBlack"];
    [self removeObserver:self forKeyPath:@"properties.fgRed"];
    [self removeObserver:self forKeyPath:@"properties.fgGreen"];
    [self removeObserver:self forKeyPath:@"properties.fgYellow"];
    [self removeObserver:self forKeyPath:@"properties.fgBlue"];
    [self removeObserver:self forKeyPath:@"properties.fgMagenta"];
    [self removeObserver:self forKeyPath:@"properties.fgCyan"];
    [self removeObserver:self forKeyPath:@"properties.fgWhite"];
    [self removeObserver:self forKeyPath:@"properties.bgBlack"];
    [self removeObserver:self forKeyPath:@"properties.bgRed"];
    [self removeObserver:self forKeyPath:@"properties.bgGreen"];
    [self removeObserver:self forKeyPath:@"properties.bgYellow"];
    [self removeObserver:self forKeyPath:@"properties.bgBlue"];
    [self removeObserver:self forKeyPath:@"properties.bgMagenta"];
    [self removeObserver:self forKeyPath:@"properties.bgCyan"];
    [self removeObserver:self forKeyPath:@"properties.bgWhite"];    
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
    [self removeProcessObservers];
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
        [self set_isBeingDragged:YES];
    else if ([[notification name]isEqualToString:@"NSLogViewMouseUp"])
        [self set_isBeingDragged:NO];
}

#pragma mark KVC
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
    timerNeedsUpdate = NO;
}

#pragma mark Window Management
- (void)setupLogWindowAndDisplay
{
    timerNeedsUpdate = YES;
    [self createWindow];
    [self updateWindow];
}

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

#pragma mark  
#pragma mark Convience
- (NSDictionary*)customAnsiColors
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBlack"]]  ,[NSNumber numberWithInt:SGRCodeFgBlack],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgRed"]]    ,[NSNumber numberWithInt:SGRCodeFgRed],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgGreen"]]  ,[NSNumber numberWithInt:SGRCodeFgGreen],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgYellow"]] ,[NSNumber numberWithInt:SGRCodeFgYellow],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgBlue"]]   ,[NSNumber numberWithInt:SGRCodeFgBlue],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgMagenta"]],[NSNumber numberWithInt:SGRCodeFgMagenta],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgCyan"]]   ,[NSNumber numberWithInt:SGRCodeFgCyan],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"fgWhite"]]  ,[NSNumber numberWithInt:SGRCodeFgWhite],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBlack"]]  ,[NSNumber numberWithInt:SGRCodeBgBlack],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgRed"]]    ,[NSNumber numberWithInt:SGRCodeBgRed],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgGreen"]]  ,[NSNumber numberWithInt:SGRCodeBgGreen],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgYellow"]] ,[NSNumber numberWithInt:SGRCodeBgYellow],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgBlue"]]   ,[NSNumber numberWithInt:SGRCodeBgBlue],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgMagenta"]],[NSNumber numberWithInt:SGRCodeBgMagenta],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgCyan"]]   ,[NSNumber numberWithInt:SGRCodeBgCyan],
            [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"bgWhite"]]  ,[NSNumber numberWithInt:SGRCodeBgWhite],
            nil];
    
}

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
