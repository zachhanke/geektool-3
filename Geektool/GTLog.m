//
//  GTLog.m
//  GeekTool
//
//  Created by Yann Bizeul on Sun Jan 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GTLog.h"
#import "defines.h"

// GTLog is a class that is responsible for storing and handling all information
// pertaining to the log displayed on the screen. It sets up and interacts with
// other objects such as NSViews to display, update, and manage its graphical
// representation
@implementation GTLog

// initialize the log with defaults
- (id)init
{
	if (!(self = [super init])) return nil;
    
    NSData *textColorData = [NSArchiver archivedDataWithRootObject: [NSColor blackColor]];
    NSData *backgroundColorData = [NSArchiver archivedDataWithRootObject: [NSColor clearColor]]; 
    
    properties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                              @"New log", @"name",
                              @"0", @"type",
                              @"1", @"enabled",
                              @"Default", @"group",
                              
                              @"Monaco", @"fontName",
                              @"12", @"fontSize",
                              
                              @"", @"file",
                              @"", @"quartzFile",
                              
                              @"", @"command",
                              @"10", @"refresh",
                              
                              textColorData, @"textColor",
                              backgroundColorData, @"backgroundColor",
                              @"0", @"wrap",
                              @"0", @"shadowText",
                              @"0", @"shadowWindow",
                              @"0", @"alignment",
                                                            
                              @"0", @"pictureAlignment",
                              @"", @"imageURL",
                              @"100", @"transparency",
                              @"0", @"imageFit",
                              
                              @"0", @"x",
                              @"0", @"y",
                              @"150", @"w",
                              @"100", @"h",
                              
                              @"0", @"alwaysOnTop",
                              nil];
    return self;
}

- (void)dealloc
{
    [properties release];
    //TODO: uncomment this //[self terminate];
    [super dealloc];
}


#pragma mark -
#pragma mark Binding

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

/*
- (id)initWithDictionary:(NSDictionary*)dictionary;
{
	if (!(self = [super init])) return nil;
    
    [self init];
    properties = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    NSString *appSupp = [[NSString stringWithString: @"~/Library/Application Support/GeekTool Scripts"] stringByExpandingTildeInPath];
    NSMutableDictionary *tempEnv = [NSMutableDictionary dictionaryWithDictionary:
                                    [[NSProcessInfo processInfo] environment]];
    NSString *path = [tempEnv objectForKey: @"PATH"];
    [tempEnv setObject: [NSString stringWithFormat: @"%@:%@",appSupp,path] forKey: @"PATH"];
    
    env =  [tempEnv copy];
    [properties setObject:[NSNumber numberWithInt:-1] forKey:@"windowLevel"];
    return self;
}

// set the dictionary, but do so as efficiently as possible
- (void)setPropertiesEfficiently:(NSDictionary*)aDictionary
{
    // terminate/recreate the log window only if we have to
    // so this if statement will contain all information that requires a reset of the window
    BOOL close = NO;
    if (([aDictionary objectForKey: @"shadowWindow"] != [properties objectForKey:@"shadowWindow"])
        || (![[aDictionary objectForKey: @"file"] isEqual: [properties objectForKey:@"file"]])
        || (![[aDictionary objectForKey: @"command"] isEqual: [properties objectForKey:@"command"]])
        || (![[aDictionary objectForKey: @"type"] isEqual: [properties objectForKey:@"type"]])
        || (![[aDictionary objectForKey: @"enabled"] isEqual: [properties objectForKey:@"enabled"]]))
        close = YES;
    
    [self setProperties:aDictionary];
    
    if (close)
    {
        [self terminate];
        [self openWindow];
    }
    else
    {
        keepTimers = YES;
        [self updateWindow];
    }
}

#pragma mark -
#pragma mark Convience Accessors
- (NSRect)realRect
{
    return [self screenToRect: [self rect]];
}

- (NSRect)rect
{
    return NSMakeRect([self x],
                      [self y],
                      [self w],
                      [self h]);
}

- (int)NSImageFit
{
    switch ([self imageFit])
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
    switch ([self pictureAlignment])
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
    NSFont* newFont = [NSFont fontWithName:fontName size:fontSize];
    return [[newFont retain] autorelease];
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
    if ([urlStr isEqual: [self imageURL]])
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

// Gets called when initializing a log for viewing
- (void)openWindow
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSPipe *pipe;
    
    // we will be executing functions to get an output soon work only if our
    // window controller doesn't exist(?) and enabled 
    // looks like one window per window controller
    if ([self enabled] && !windowController)
    {
        // initialize our window controller
        windowController = [[LogWindowController alloc] initWithWindowNibName: @"logWindow"];
        [windowController setType: [self type]];
        
        [windowController showWindow: self];
        [[windowController window] setAutodisplay: YES];
        
        // we need some way to bridge our GTLog and AIQuartzView.
        // LogWindowController is going to help through this `ident'
        [windowController setIdent:[self refresh]];
        
        // set the quartz view to be hidden at the moment
        [[windowController quartzView] setHidden:TRUE];
        
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
        if ([self type] == TYPE_FILE)
        {
            // if no file is specified, don't do anything
            if ([[self file] isEqual: @""])
                return;
            
            // The following NSTask reads the command file (to 50 lines?)
            // The -F file makes sure the file keeps getting read even if it
            // hits the EOF or the file name is changed
            task = [[NSTask alloc] init];
            
            [task setLaunchPath: @"/usr/bin/tail"];
            [task setArguments: [NSArray arrayWithObjects: @"-n",@"50",@"-F", [self file], nil]];
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
        }
        else if ([self type] == TYPE_QUARTZ)
        {
            [[windowController quartzView] setHidden:FALSE];
            if (![[self quartzFile] isEqual: @""] && 
                [[windowController quartzView] loadCompositionFromFile:[self quartzFile]])
                [[windowController quartzView] setAutostartsRendering:TRUE];
        }

        [self updateWindow];
    }
    else if (![self enabled] && windowController)
        [self terminate];

    [pool release];
}

// every timer hits this fn every X seconds. make it lean and mean
- (void)updateCommand:(NSTimer*)timer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    BOOL free = YES;
    NSPipe *pipe;
    
    
    switch ([self type])
    {
        case TYPE_SHELL:
            // if the task is still running, don't try to read from it
            // (ie the output is indeterminable)
            if ([task isRunning]) free = NO;
            
            // if we have a controller and the command is done launching...
            if (windowController != nil && free)
            {
                // make another task! hah! you thought you were done?!
                task = [[NSTask alloc] init];
                [task setLaunchPath: @"/bin/sh"];
                [task setArguments: arguments];
                [task setEnvironment: env];
                clear = YES;
                
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
                                   withObject: [self imageURL]];            
            break;
            
        // if its quartz, we just tell AIQuartzView we want a render. notice that
        // we must send information about ourself so we can render a specific log
        // (instead of rendering them all)
        case TYPE_QUARTZ:
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName: @"GTLogUpdate"
                                                                           object: @"GeekTool"
                                                                         userInfo: [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[self refresh]]
                                                                                                               forKey:@"ident"]
                                                               deliverImmediately: NO];
            break;
        // notice we don't have a case for FILE because it does not need to be
        // updated
    }
    [pool release];
}

// This function just updates the window. It really isn't as hot as I once 
// thought. updateCommand on the other hand...
// Called after a window is created or a log's dictionary is changed (some
// aspect is changed, like the command or size)
- (void)updateWindow
{
    NSWindow *window = [windowController window];
    
    // set a few attributes pertaining to how the window appears
    [windowController setHasShadow: [self shadowWindow]];
    [windowController setLevel: [self windowLevel]];
    [self setSticky: [self windowLevel] == kCGDesktopWindowLevel];
    [windowController setPictureAlignment: [self NSPictureAlignment]];
    
    // make it's size and make it unclickable
    [[windowController window] setFrame: [self realRect] display: NO];
    [(LogWindow*)window setClickThrough: YES];
    
    // continue only for file and shell
    if ([self type] == TYPE_FILE || [self type] == TYPE_SHELL)
    {
        // get the colors right
        [windowController setTextBackgroundColor: [NSUnarchiver unarchiveObjectWithData:[self backgroundColor]]];
        [windowController setShadowText: [self shadowText]];
        
        // Paragraph style
        NSMutableParagraphStyle *myParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        switch ([self alignment])
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
        if ([self wrap])
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
                       [NSUnarchiver unarchiveObjectWithData:[self textColor]], NSForegroundColorAttributeName,nil] retain];
        [myParagraphStyle release];
        [windowController setAttributes: attributes];
    }

    
    // commit our rect. rememeber, this is with respect to the log window, hence
    // why our x,y are going to be like 0,0. a bounds rect, if you will
    NSRect tmpRect = [self rect];
    tmpRect.origin.x = 0;
    tmpRect.origin.y = 0;
    [windowController setTextRect: tmpRect]; 
    
    // sometimes, we just wanted to update the way the window looks, and not
    // destroy our precious timers. this logic will do just that
    if(!([self type] == TYPE_SHELL && keepTimers))
    {
        // setup some timer stuff
        if ([self type] == TYPE_SHELL ||
            [self type] == TYPE_IMAGE ||
            [self type] == TYPE_QUARTZ)
        {
            if ([self type] == TYPE_SHELL)
            {
                arguments = [[NSArray alloc] initWithObjects: @"-c",[self command], nil];
                clear = YES;
                NSString *tmp = @"";

                [windowController addText: tmp clear: YES];
            }
            else if ([self type] == TYPE_IMAGE)
            {
                // make a nice environment for the image
                [windowController setTextBackgroundColor: [NSColor clearColor]];
                // TODO: Transparency may be flipped (ie its opacity)
                [[windowController window] setAlphaValue: ([self transparency]*100)];
                [windowController setFit: [self imageFit]];
            }
            
            // if we have a timer, kill it
            if (timer)
            {
                [timer invalidate];
                [timer release];
                timer = nil;
            }
            
            timer = [[NSTimer scheduledTimerWithTimeInterval: [self refresh]
                                                      target: self
                                                    selector: @selector(updateCommand:)
                                                    userInfo: nil
                                                     repeats: YES] retain];
            
            [timer fire];
        }
    }
    // scroll the text so we stay fresh in the output
    if (([self type] == TYPE_FILE) || ([self type] == TYPE_SHELL))
        [windowController scrollEnd];
    
    // display our badass window
    [windowController display];
    
    // default this back to 0, so we always update our timers
    keepTimers = NO;
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
    if (![newLinesString isEqualTo: @""] || [self type] == TYPE_FILE)
    {
        [windowController addText: newLinesString clear: ([self type] != TYPE_IMAGE)];
        
        if ([self type] == TYPE_SHELL)
        {
            [windowController scrollEnd];
            [[aNotification object] waitForDataInBackgroundAndNotify];
        }
        
        //[windowController setFont: [self font]];
        [windowController setAttributes: attributes];
    }
    clear = NO;
    [windowController display];
    [newLinesString release];
    [pool release];
}

- (void)taskEnd:(NSNotification*)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: [aNotification name]
                                                  object: nil];
    if ([self type] == TYPE_FILE)
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

- (NSRect)screenToRect:(NSRect)var
{
    //  NSLog(@"%f,%f",rect.origin.y,rect.size.height);
    NSRect screenSize = [[NSScreen mainScreen] frame];
    return NSMakeRect(var.origin.x, (-var.origin.y + screenSize.size.height) - var.size.height, var.size.width,var.size.height);
}

#pragma mark -
#pragma mark Standard object methods

- (id)copyWithZone:(NSZone *)zone
{
    GTLog *copy = [[[self class] allocWithZone: zone]
                   initWithDictionary:[self dictionary]];
    
    return copy;
}

- (bool)equals:(GTLog*)comp
{
    if ([[self dictionary] isEqualTo: [comp dictionary]]) return YES;
    else return NO;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [self copyWithZone: zone];
}

- (NSString*)description
{
    return [NSString stringWithFormat: @"%@",[self dictionary]];
}


- (void)terminate
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    if (task)
    {
        [task terminate];
        [task release];
        //[pipe release];
        task = nil;
    }
    
    if (windowController)
    {
        [[windowController window] close];
        windowController=nil;
    }
    
    if (timer)
    {
        [timer invalidate];
        [timer release];
        timer=nil;
    }
    if (arguments)
    {
        [arguments release];
        arguments = nil;
    }
}
 */
#pragma mark Coding
- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        [self setProperties:[coder decodeObjectForKey:@"properties"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:properties forKey:@"properties"];
}

@end
