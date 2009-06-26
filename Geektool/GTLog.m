//
//  GTLog.m
//  GeekTool
//
//  Created by Yann Bizeul on Sun Jan 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GTLog.h"
#import "LogController.h"
#import "defines.h"

// GTLog is a class that is responsible for storing and handling all information
// pertaining to the log displayed on the screen. It sets up and interacts with
// other objects such as NSViews to display, update, and manage its graphical
// representation
@implementation GTLog

// initialize the log with defaults
- (id)init
{    
    NSData *textColorData = [NSArchiver archivedDataWithRootObject: [NSColor blackColor]];
    NSData *backgroundColorData = [NSArchiver archivedDataWithRootObject: [NSColor clearColor]]; 
    
    NSMutableDictionary *defaultProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                              @"New log", @"name",
                                              [NSNumber numberWithInt:TYPE_SHELL], @"type",
                                              [NSNumber numberWithBool:YES], @"enabled",
                                              @"Default", @"group",
                                              
                                              @"Monaco", @"fontName",
                                              [NSNumber numberWithInt:12], @"fontSize",
                                              
                                              @"", @"file",
                                              @"", @"quartzFile",
                                              
                                              @"", @"command",
                                              [NSNumber numberWithInt:10], @"refresh",
                                              
                                              textColorData, @"textColor",
                                              backgroundColorData, @"backgroundColor",
                                              [NSNumber numberWithBool:NO], @"wrap",
                                              [NSNumber numberWithBool:NO], @"shadowText",
                                              [NSNumber numberWithBool:NO], @"shadowWindow",
                                              [NSNumber numberWithBool:NO], @"alignment",
                                              
                                              [NSNumber numberWithInt:-1], @"windowLevel",
                                              
                                              [NSNumber numberWithInt:TOP_LEFT], @"pictureAlignment",
                                              @"", @"imageURL",
                                              [NSNumber numberWithInt:100], @"transparency",
                                              [NSNumber numberWithInt:PROPORTIONALLY], @"imageFit",
                                              
                                              [NSNumber numberWithInt:0], @"x",
                                              [NSNumber numberWithInt:0], @"y",
                                              [NSNumber numberWithInt:150], @"w",
                                              [NSNumber numberWithInt:150], @"h",
                                              
                                              [NSNumber numberWithBool:NO], @"alwaysOnTop",
                                              nil];
    
    return [self initWithProperties:defaultProperties];
}

- (id)initWithProperties:(NSDictionary*)newProperties
{
	if (!(self = [super init])) return nil;
    
    canDisplay = FALSE;
    
    [self setProperties:[NSMutableDictionary dictionaryWithDictionary:newProperties]];
    
    NSString *appSupp = [[NSString stringWithString: @"~/Library/Application Support/NerdTool/"] stringByExpandingTildeInPath];
    NSMutableDictionary *tempEnv = [NSMutableDictionary dictionaryWithDictionary: [[NSProcessInfo processInfo] environment]];
    NSString *path = [tempEnv objectForKey: @"PATH"];
    [tempEnv setObject: [NSString stringWithFormat: @"%@:%@",appSupp,path] forKey: @"PATH"];
    
    env = [tempEnv copy];
    
    canDisplay = TRUE;
    [self setupObservers];
    [self createWindow];
    return self;
}

- (void)setupObservers
{
    // watch all these variables and run the observeValueForKeyPath function below each time any change
    [self addObserver:self forKeyPath:@"properties.name" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.type" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.enabled" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.group" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.fontName" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.fontSize" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.file" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.quartzFile" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.command" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.refresh" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.textColor" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.backgroundColor" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.wrap" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.shadowText" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.shadowWindow" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.alignment" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.windowLevel" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.pictureAlignment" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.imageURL" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.transparency" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.imageFit" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.x" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.y" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.w" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.h" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:self forKeyPath:@"properties.alwaysOnTop" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    // if the selection changes, highlight
    // anything else, just save
    if (([keyPath isEqualToString:@"properties.shadowWindow"] ||
        [keyPath isEqualToString:@"properties.file"] ||
        [keyPath isEqualToString:@"properties.command"] ||
        [keyPath isEqualToString:@"properties.type"] ||
        [keyPath isEqualToString:@"properties.enabled"] &&
        ![[change objectForKey:@"old"] isEqual: [change objectForKey:@"new"]]) ||
        !windowController)
    {
        
        [self terminate];
        [self createWindow];
    }
    else
    {
        keepTimers = YES;
        [self updateWindow];
    }
    
    // for some reason, this makes an error occur...
    //[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc
{
    [properties release];
    [env release];
    [self terminate];
    [super dealloc];
}

- (void)terminate
{
    if (task)
    {
        [task terminate];
        [task release];
    }
    
    /*
    if (windowController)
    {
        [[windowController window] close];
        [windowController release];
    }
    */
    if (timer)
    {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    
    if (arguments)
    {
        [arguments release];
    }
}

#pragma mark -
#pragma mark KVC
- (void)setProperties:(NSDictionary *)newProperties
{
    if (properties != newProperties)
    {
        [properties autorelease];
        properties = [[NSMutableDictionary alloc] initWithDictionary:newProperties];
    }
}

- (NSMutableDictionary *)properties
{
    return properties;
}

#pragma mark -
#pragma mark Convience Accessors
- (NSRect)realRect
{
    return [self screenToRect: [self rect]];
}

- (NSRect)screenToRect:(NSRect)var
{
    // remember, our coordinates are with respect to the
    // top left corner (both window and screen), but
    // the actual OS takes them with respect to the
    // bottom left (both window and screen), so we must convert between these
    // NSLog(@"%f,%f",rect.origin.y,rect.size.height);
    NSRect screenSize = [[NSScreen mainScreen] frame];
    return NSMakeRect(var.origin.x, (-var.origin.y + screenSize.size.height) - var.size.height, var.size.width,var.size.height);
}

- (NSRect)rect
{
    return NSMakeRect([properties integerForKey:@"x"],
                      [properties integerForKey:@"y"],
                      [properties integerForKey:@"w"],
                      [properties integerForKey:@"h"]);
}

- (int)NSImageFit
{
    switch ([properties integerForKey:@"imageFit"])
    {
        case PROPORTIONALLY:
            return NSScaleProportionally;
            break;
        case TO_FIT:
            return NSScaleToFit;
            break;
        case NONE:
            return NSScaleNone;
            break;
    }
    return NSScaleNone;
}

- (int)NSPictureAlignment
{
    switch ([properties integerForKey:@"pictureAlignment"])
    {
        case TOP_LEFT:
            return NSImageAlignTopLeft;
            break;
        case TOP:
            return NSImageAlignTop;
            break;
        case TOP_RIGHT:
            return NSImageAlignTopRight;
            break;
        case LEFT:
            return NSImageAlignLeft;
            break;
        case CENTER:
            return NSImageAlignCenter;
            break;
        case RIGHT:
            return NSImageAlignRight;
            break;
        case BOTTOM_LEFT:
            return NSImageAlignBottomLeft;
            break;
        case BOTTOM:
            return NSImageAlignBottom;
            break;
        case BOTTOM_RIGHT:
            return NSImageAlignBottomRight;
            break;
    }
    return NSImageAlignTopLeft;
}

- (NSFont*)font
{
    if (font) [font release];
    font = [NSFont fontWithName:[properties objectForKey:@"fontName"] size:[[properties objectForKey:@"fontSize"]floatValue]];
    return [font retain];
}

#pragma mark -
#pragma mark Window operations
- (void)front
{
    [[windowController window] orderFront: self];
}

- (void)setImage:(NSString*)urlStr
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableString *myUrl = [NSMutableString stringWithString: urlStr];
    
    if (NSEqualRanges([myUrl rangeOfString: @"?"], NSMakeRange(NSNotFound, 0)))
        [myUrl appendString: @"?GTTIME="];
    else
        [myUrl appendString: @"&GTTIME="];
    [myUrl appendString: [[NSNumber numberWithLong:random()] stringValue]];
    
    NSURL *url = [NSURL URLWithString: myUrl];
    NSImage *myImage = [[NSImage alloc] initWithData: [url resourceDataUsingCache:NO]];
    if ([urlStr isEqual: [properties objectForKey:@"imageURL"]])
        [windowController setImage: myImage];
    [myImage release];
    [pool release];
}

- (void)setHighlighted:(BOOL)myHighlight
{
    [windowController setHighlighted: myHighlight];
}

- (void)setSticky:(BOOL)flag
{
    [windowController setSticky: flag];
}

#pragma mark Window Creation/Management
// Gets called when initializing a log for viewing
// All initialization for all log types should occur here
- (void)createWindow
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSPipe *pipe;
    
    // we will be executing functions to get an output soon work only if our
    // window controller doesn't exist(?) and enabled 
    // looks like one window per window controller
    if ([properties boolForKey:@"enabled"])
    {
        // initialize our window controller
        if (windowController == nil)
            windowController = [[LogWindowController alloc] initWithWindowNibName: @"logWindow"];
        [windowController setType: [properties integerForKey:@"type"]];
                
        // we have to do this here instead of in the nib because we get an "invalid drawable"
        // error if its done via the nib
        [[windowController quartzView] setHidden:TRUE];
                
        //[[windowController window] setAutodisplay: YES];
        [windowController setHasShadow: [properties boolForKey:@"shadowWindow"]];
        
        switch ([properties integerForKey:@"type"])
        {
                // If the type is FILE, we need to do some things to get it set up
                // Specifically, it sets up a pipe to watch the output of a file,
                // however, I don't see it as too useful, as you would probably want to
                // pipe the information somewhere else before displaying it.
                // nevertheless, it does have it's uses
                //
                // more importantly, we do this initialization here because we only need
                // to do this once, and this function is the only one that gets executed
                // once when the window is created. Otherwise, we would be recreating
                // this command when we are updating (a la SHELL)                
            case TYPE_FILE:
                // if no file is specified, don't do anything
                if ([[properties objectForKey:@"file"] isEqual: @""])
                    return;
                
                // The following NSTask reads the command file (to 50 lines?)
                // The -F file makes sure the file keeps getting read even if it
                // hits the EOF or the file name is changed
                task = [[NSTask alloc] init];
                
                [task setLaunchPath: @"/usr/bin/tail"];
                [task setArguments: [NSArray arrayWithObjects:
                                     @"-n",@"50",
                                     @"-F", [properties objectForKey:@"file"],
                                     nil]];
                [task setEnvironment: env];
                
                pipe = [NSPipe pipe];
                [task setStandardOutput: pipe];
                
                // We set up observers here to handle constant reading of the
                // file, esp. that file is modified in any way
                [[NSNotificationCenter defaultCenter] addObserver: self
                                                         selector: @selector(newLines:)
                                                             name: @"NSFileHandleReadCompletionNotification"
                                                           object: [pipe fileHandleForReading]];
                
                [[NSNotificationCenter defaultCenter] addObserver: self
                                                         selector: @selector(newLines:)
                                                             name: @"NSFileHandleDataAvailableNotification"
                                                           object: [pipe fileHandleForReading]];
                
                // I'm guessing this just means we do the notifications above
                [[pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
                
                // Be sure to tell whoever wants to know when we are done with our task
                [[NSNotificationCenter defaultCenter] addObserver: self
                                                         selector: @selector(taskEnd:)
                                                             name: @"NSTaskDidTerminateNotification"
                                                           object: task];         
                
                // Get the ball rolling
                [task launch];
                
                break;
                
            case TYPE_QUARTZ:
                // we need some way to bridge our GTLog and AIQuartzView.
                // LogWindowController is going to help through this `ident'
                [windowController setIdent:[properties integerForKey:@"refresh"]];
                
                [[windowController quartzView] setHidden:FALSE];
                
                // load the quartz comp if possible and start rendering
                if (![[properties objectForKey:@"quartzFile"] isEqual: @""] && 
                    [[windowController quartzView] loadCompositionFromFile:[properties objectForKey:@"quartzFile"]])
                    [[windowController quartzView] setAutostartsRendering:TRUE];                
                break;
                
            default:
                break;
        }
        
        [self updateWindow];
        [windowController showWindow: self];
    }
    else if (![properties boolForKey:@"enabled"])
        [self terminate];
    
    [pool release];
}

// This function just updates the window. It really isn't as hot as I once 
// thought. updateCommand on the other hand...
// Called after a window is created or a log's dictionary is changed (some
// aspect is changed, like the command or size)
- (void)updateWindow
{
    //==Pre-init==
    NSWindow *window = [windowController window];
    
    // set a few attributes pertaining to how the window appears
    [windowController setLevel: [properties integerForKey:@"windowLevel"]];
    [self setSticky: [properties integerForKey:@"windowLevel"] == kCGDesktopWindowLevel];
    [windowController setPictureAlignment: [self NSPictureAlignment]];
    
    // make it's size and make it unclickable
    [window setFrame: [self realRect] display: NO];
    //[window setFrame: [self rect] display: NO];

    [(LogWindow*)window setClickThrough: YES];
    
    // commit our rect. rememeber, this is with respect to the log window, hence
    // why our x,y are going to be like 0,0. a bounds rect, if you will
    NSRect tmpRect = [self rect];
    tmpRect.origin.x = 0;
    tmpRect.origin.y = 0;
    [windowController setTextRect: tmpRect]; 

    //==Init==
    // set up stuff specific to the type of log
    switch ([properties integerForKey:@"type"])
    {
        case TYPE_FILE:
            [self updateTextAttributes];
            
            // scroll the text so we stay fresh in the output
            [windowController scrollEnd];
            break;
            
        case TYPE_SHELL:
            [self updateTextAttributes];
            
            // if we need new timers
            if (!keepTimers)
            {
                arguments = [[NSArray alloc] initWithObjects: @"-c",[properties objectForKey:@"command"], nil];
                NSString *tmp = @"";
                
                [windowController addText: tmp clear: YES];
                [self updateTimer];
            }
            
            // scroll the text so we stay fresh in the output
            [windowController scrollEnd];
            break;
            
        case TYPE_IMAGE:
            // make a nice environment for the image
            [windowController setTextBackgroundColor: [NSColor clearColor]];
            // TODO: Transparency may be flipped (ie its opacity)
            [[windowController window] setAlphaValue: ([properties integerForKey:@"transparency"])];
            [windowController setFit: [properties integerForKey:@"imageFit"]];
            if (!keepTimers) [self updateTimer];
            break;
            
        case TYPE_QUARTZ:
            if (!keepTimers) [self updateTimer];
            break;
            
        default:
            break;
    }
    
    //==Post-Init==
    // display window (though autodisplay should take care of this)
    [windowController display];
    
    // default this back to 0, so we always update our timers
    keepTimers = NO;
}

// every timer hits this fn every X seconds. make it lean and mean
- (void)updateCommand:(NSTimer*)timer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    BOOL free = YES;
    NSPipe *pipe;
    
    switch ([properties integerForKey:@"type"])
    {            
        case TYPE_SHELL:
            // if the task is still running, don't try to read from it
            // (ie the output is indeterminable)
            if ([task isRunning]) free = NO;
            
            // if we have a controller and the command is done launching...
            if (windowController && free)
            {
                // make another task! hah! you thought you were done?!
                task = [[NSTask alloc] init];
                [task setLaunchPath: @"/bin/sh"];
                [task setArguments: arguments];
                [task setEnvironment: env];
                
                pipe = [[NSPipe alloc] init];
                
                // read stuff until its all gone
                [[NSNotificationCenter defaultCenter] addObserver: self
                                                         selector: @selector(newLines:)
                                                             name: @"NSFileHandleReadToEndOfFileCompletionNotification"
                                                           object: [pipe fileHandleForReading]];
                [[pipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
                
                [task setStandardOutput: pipe];
                
                [[NSNotificationCenter defaultCenter] addObserver: self
                                                         selector: @selector(taskEnd:)
                                                             name: @"NSTaskDidTerminateNotification"
                                                           object: task];
                
                // punch it chewie
                [task launch];
                
                // grrrrrwwwahhhhhhh
                [pipe release];
            }
            break;
            
            // if its an image, concern yourself only with looking at the itemage
        case TYPE_IMAGE:
            [NSThread detachNewThreadSelector: @selector(setImage:)
                                     toTarget: self
                                   withObject: [properties objectForKey:@"imageURL"]];            
            break;
            
            // if its quartz, we just tell AIQuartzView we want a render. notice that
            // we must send information about ourself so we can render a specific log
            // (instead of rendering all quartz objects)
        case TYPE_QUARTZ:
            /*
             [[NSDistributedNotificationCenter defaultCenter] postNotificationName: @"GTLogUpdate"
             object: @"GeekTool"
             userInfo: [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[properties objectForKey:@"refresh"]]
             forKey:@"ident"]
             deliverImmediately: NO];
             */
            break;
            // notice we don't have a case for FILE because it does not need to be
            // updated
    }
    [pool release];
}

#pragma mark Convenience Helpers
// updates look and formatting of text
- (void)updateTextAttributes
{
    // get the colors right
    [windowController setTextBackgroundColor: [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"backgroundColor"]]];
    [windowController setShadowText: [properties boolForKey:@"shadowText"]];
    
    // Paragraph style
    NSMutableParagraphStyle *myParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    switch ([properties integerForKey:@"alignment"])
    {
        case ALIGN_LEFT:
            [myParagraphStyle setAlignment: NSLeftTextAlignment];
            break;
        case ALIGN_CENTER:
            [myParagraphStyle setAlignment: NSCenterTextAlignment];
            break;
        case ALIGN_RIGHT:
            [myParagraphStyle setAlignment: NSRightTextAlignment];
            break;
        case ALIGN_JUSTIFIED:
            [myParagraphStyle setAlignment: NSJustifiedTextAlignment];
            break;
    }
    if ([properties boolForKey:@"wrap"])
        [myParagraphStyle setLineBreakMode: NSLineBreakByCharWrapping];
    else
        [myParagraphStyle setLineBreakMode: NSLineBreakByClipping];
    
    if (attributes)
        [attributes release];
    
    // here is where we override the scheme of the text. if you wanted
    // to keep colors through the shell, here is where you would check for it
    attributes = [[NSDictionary dictionaryWithObjectsAndKeys:
                   myParagraphStyle, NSParagraphStyleAttributeName,
                   [self font],      NSFontAttributeName,
                   [NSUnarchiver unarchiveObjectWithData:[properties objectForKey:@"textColor"]], NSForegroundColorAttributeName,nil] retain];
    [myParagraphStyle release];
    [windowController setAttributes: attributes];    
}

// recreate the timer by destroying the old one (you must make checks to `keepTimers' yourself)
- (void)updateTimer
{
    // if we have a timer, kill it
    if (timer)
    {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    
    timer = [[NSTimer scheduledTimerWithTimeInterval: [properties integerForKey:@"refresh"]
                                              target: self
                                            selector: @selector(updateCommand:)
                                            userInfo: nil
                                             repeats: YES]retain];
    
    [timer fire];
}

#pragma mark -
#pragma mark Window notifications

// this grabs lines from an NSTask output, specifically from the openWindow
// task for a file. Whenever the observed file is modified, this function
// takes care of reading it.
// This also is used for reading shell output
- (void)newLines:(NSNotification*)aNotification
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSData *newLines;
    NSString *newLinesString;
    
    if ([[aNotification name] isEqual : @"NSFileHandleReadToEndOfFileCompletionNotification"])
    {
        newLines = [[aNotification userInfo] objectForKey: @"NSFileHandleNotificationDataItem"];
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: [aNotification name]
                                                      object: nil];        
    }
    else
        newLines = [[aNotification object] availableData];
    
    newLinesString = [[NSString alloc] initWithData: newLines encoding:NSASCIIStringEncoding];
    if (![newLinesString isEqualTo: @""] || [properties integerForKey:@"type"] == TYPE_FILE)
    {
        [windowController addText: newLinesString clear: ([properties integerForKey:@"type"] != TYPE_IMAGE)];
        
        if ([properties integerForKey:@"type"] == TYPE_SHELL)
        {
            [windowController scrollEnd];
            [[aNotification object] waitForDataInBackgroundAndNotify];
        }
        
        //[windowController setFont: [self font]];
        [windowController setAttributes: attributes];
    }

    [windowController display];
    [newLinesString release];
    [pool release];
}

- (void)taskEnd:(NSNotification*)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: [aNotification name]
                                                  object: nil];
    if ([properties integerForKey:@"type"] == TYPE_FILE)
    {
        [self terminate];
    }
    
    //[windowController display];
    [task release];
    task = nil;
    return;
}

#pragma mark -
#pragma mark Misc
- (BOOL)equals:(GTLog*)comp
{
    if ([[self properties] isEqualTo: [comp properties]]) return YES;
    else return NO;
}

- (NSString*)description
{
    return [NSString stringWithFormat: @"Log:%@\nEnabled:%@",
            [[self properties]objectForKey:@"name"],
            [[self properties]objectForKey:@"enabled"]
    ];
}

#pragma mark -
#pragma mark Copying
- (id)copyWithZone:(NSZone *)zone
{
    id result = [[[self class] allocWithZone:zone] init];
    
    [result setProperties:[self properties]];
    
    return result;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [self copyWithZone: zone];
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
#pragma mark 

@implementation NSDictionary (intBoolValues)
- (int)integerForKey:(NSString *)key
{
    return [[self objectForKey:key]intValue];
}

- (BOOL)boolForKey:(NSString *)key
{
    return [[self objectForKey:key]boolValue];
}
@end
