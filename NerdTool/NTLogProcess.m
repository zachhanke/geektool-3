//
//  NTLogProcess.m
//  NerdTool
//
//  Created by Kevin Nygaard on 6/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTLogProcess.h"
#import "LogWindow.h"
#import "GTLog.h"
#import "LogTextField.h"
#import "AIQuartzView.h"
#import "NSDictionary+IntAndBoolAccessors.h"
#import "defines.h"

@implementation NTLogProcess

@synthesize windowController;
@synthesize window;
@synthesize parentLog;
@synthesize parentProperties;
@synthesize attributes;
@synthesize arguments;
@synthesize timerNeedsUpdate;

- (id)initWithParentLog:(id)parent
{
    if (!(self = [super init])) return nil;
    
    windowController = [[NSWindowController alloc]initWithWindowNibName:@"logWindow"];
    window = (LogWindow*)[windowController window];
    task = nil;
        
    // append app support folder to shell PATH
    NSMutableDictionary *tmpEnv = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo]environment]];
    NSString *appendedPath = [NSString stringWithFormat:@"%@:%@",[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES) objectAtIndex:0]stringByAppendingPathComponent:[[NSProcessInfo processInfo]processName]],[tmpEnv objectForKey:@"PATH"]];
    [tmpEnv setObject:appendedPath forKey:@"PATH"];  
    env = [tmpEnv copy];
    
    [self setParentLog:parent];
    [self setupObservers];
    
    return self;
}

- (id)init
{
    return [self initWithParentLog:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [windowController close];
    [windowController release];
    [env release];
    [task release];
    [self killTimer];
    [super dealloc];
}

#pragma mark Observing
- (void)setupObservers
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:@"NSLogViewMouseDown" object:window];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:NSWindowDidResizeNotification object:window];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:NSWindowDidMoveNotification object:window];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notificationHandler:) name:@"NSLogViewMouseUp" object:window];
}

- (void)notificationHandler:(NSNotification *)notification
{
    if (([[notification name]isEqualToString:NSWindowDidResizeNotification] || [[notification name]isEqualToString:NSWindowDidMoveNotification]))
    {
        // this happens on init, which screws things up
        if (![parentLog isBeingDragged]) return;
        NSRect newCoords = [self screenToRect:[[notification object]frame]];
        [parentProperties setValue:[NSNumber numberWithInt:NSMinX(newCoords)] forKey:@"x"];
        [parentProperties setValue:[NSNumber numberWithInt:NSMinY(newCoords)] forKey:@"y"];
        [parentProperties setValue:[NSNumber numberWithInt:NSWidth(newCoords)] forKey:@"w"];
        [parentProperties setValue:[NSNumber numberWithInt:NSHeight(newCoords)] forKey:@"h"];
    }
    else if ([[notification name]isEqualToString:@"NSLogViewMouseDown"])
        [parentLog setIsBeingDragged:YES];
    else if ([[notification name]isEqualToString:@"NSLogViewMouseUp"])
        [parentLog setIsBeingDragged:NO];
}

#pragma mark KVC
- (void)setParentLog:(GTLog*)log;
{
    parentLog = log;
    [self setParentProperties:[parentLog properties]];
    [window setParentLog:parentLog];
}

#pragma mark Window Creation/Management
- (void)setupLogWindowAndDisplay
{
    timerNeedsUpdate = YES;
    [self createWindow];
    [self updateWindow];
}

// Gets called when initializing a log for viewing. All initialization for all log types should occur here
- (void)createWindow
{        
    // we have to do this here instead of in the nib because we get an "invalid drawable" error if its done via the nib
    // it would actually turns out that the window MUST be drawn before doing anything with anything that pertains to OpenGL, which includes the custom quartz window
    [windowController showWindow:nil];
    [[window quartzView]setHidden:TRUE];
    [window setHasShadow:[parentProperties boolForKey:@"shadowWindow"]];
    
    if (task) [task release];
    
    switch ([parentProperties integerForKey:@"type"])
    {
        case TYPE_FILE:
            if ([[parentProperties objectForKey:@"file"]isEqual:@""]) return;
            
            // Read file to 50 lines. The -F file makes sure the file keeps getting read even if it hits the EOF or the file name is changed
            task = [[NSTask alloc]init];
            NSPipe *pipe = [NSPipe pipe];
            
            [task setLaunchPath:@"/usr/bin/tail"];
            [task setArguments:[NSArray arrayWithObjects:@"-n",@"50",@"-F",[parentProperties objectForKey:@"file"],nil]];
            [task setEnvironment:env];
            [task setStandardOutput:pipe];

            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:NSFileHandleReadCompletionNotification object:[pipe fileHandleForReading]];
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:NSFileHandleDataAvailableNotification object:[pipe fileHandleForReading]];
                        
            [[pipe fileHandleForReading]waitForDataInBackgroundAndNotify];
            
            [task launch];
            break;
            
        case TYPE_QUARTZ:
            [[window textView]setHidden:YES];
            [[window quartzView]setHidden:FALSE];
            
            if ([[parentProperties objectForKey:@"quartzFile"]isEqual:@""]) break;
            if ([[window quartzView]loadCompositionFromFile:[parentProperties objectForKey:@"quartzFile"]]) [[window quartzView]setAutostartsRendering:TRUE];                
            break;
    }
}

- (void)updateWindow
{
    //==Pre-init==    
    [window setFrame:[self screenToRect:[self rect]] display:NO];
    
    NSRect tmpRect = [self rect];
    tmpRect.origin.x = 0;
    tmpRect.origin.y = 0;
    [window setTextRect:tmpRect]; 
    
    [window setLevel:(([parentProperties integerForKey:@"alwaysOnTop"])?[parentProperties integerForKey:@"alwaysOnTop"]:kCGDesktopWindowLevel)];
    [window setSticky:(![parentProperties boolForKey:@"alwaysOnTop"])];
    
    //==Init==
    switch ([parentProperties integerForKey:@"type"])
    {
        case TYPE_FILE:
            [[window textView]setHidden:NO];
            
            [self updateTextAttributes];
            [[window textView]scrollEnd];
            break;
            
        case TYPE_SHELL:
            [[window textView]setHidden:NO];
            
            [self updateTextAttributes];
            if (timerNeedsUpdate)
            {
                [self setArguments:[[[NSArray alloc]initWithObjects:@"-c",[parentProperties objectForKey:@"command"],nil]autorelease]];
                
                [[window textView]addText:@"" clear:YES];
                [self updateTimer];
            }
            [[window textView]scrollEnd];
            break;
            
        case TYPE_IMAGE:
            [[window textView]addText:@"" clear:YES];
            [[window textView]setHidden:YES];
            [window setTextBackgroundColor:[NSColor clearColor]];
            
            [[window imageView]setImageAlignment:[self imageAlignment]];
            [[window imageView]setImageScaling:[self imageFit]];
            if (timerNeedsUpdate) [self updateTimer];
            break;
            
        case TYPE_QUARTZ:
            if (timerNeedsUpdate) [self updateTimer];
            break;
    }
    //==Post-Init==
    [window display];
    
    timerNeedsUpdate = NO;
}

#pragma mark Task
- (void)updateCommand:(NSTimer*)timer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    switch ([parentProperties integerForKey:@"type"])
    {            
        case TYPE_SHELL:
            if ([task isRunning]) return;
                        
            if (task) [task release];
            task = [[NSTask alloc]init];
            NSPipe *pipe = [[NSPipe alloc]init];

            [task setLaunchPath:@"/bin/sh"];
            [task setArguments:arguments];
            [task setEnvironment:env];
            [task setStandardOutput:pipe];
            
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:NSFileHandleReadToEndOfFileCompletionNotification object:[pipe fileHandleForReading]];
            [[pipe fileHandleForReading]readToEndOfFileInBackgroundAndNotify];

            [task launch];
            
            [pipe release];
            break;
            
        case TYPE_IMAGE:
            [NSThread detachNewThreadSelector:@selector(setImage:) toTarget:self withObject:[parentProperties objectForKey:@"imageURL"]];            
            break;
            
        case TYPE_QUARTZ:
            [[window quartzView]requestRender];
            break;
    }
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
    
    NSString *newString = [[NSString alloc]initWithData:newData encoding:NSASCIIStringEncoding];
    
    if (![newString isEqualTo:@""] || [parentProperties integerForKey:@"type"] == TYPE_FILE)
    {
        [[window textView]addText:newString clear:([parentProperties integerForKey:@"type"] != TYPE_IMAGE)];
        
        if ([parentProperties integerForKey:@"type"] == TYPE_SHELL)
        {
            [[window textView]scrollEnd];
            [[aNotification object]waitForDataInBackgroundAndNotify];
        }
        [[window textView]setAttributes:attributes];
    }
    
    [window display];
    [newString release];
}

#pragma mark Update
- (void)updateTimer
{
    [self killTimer];
    int refresh = [parentProperties integerForKey:@"refresh"];
    timerRepeats = refresh?YES:NO;
    
    timer = [[NSTimer scheduledTimerWithTimeInterval:refresh target:self selector:@selector(updateCommand:) userInfo:nil repeats:timerRepeats]retain];
    [timer fire];
    
    if (timerRepeats) [self release]; // when the timer is added to the runloop, we are retained. we don't want to be.
    else [timer release];
}

- (void)killTimer
{
    if (!timer) return;
    if (!timerRepeats) return;
        
    [self retain];
    [timer invalidate];
    [timer release];
}

- (void)updateTextAttributes
{
    // get the colors right
    [window setTextBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[parentProperties objectForKey:@"backgroundColor"]]];
    [[window textView] setShadowText:[parentProperties boolForKey:@"shadowText"]];
    
    // Paragraph style
    NSMutableParagraphStyle *myParagraphStyle = [[NSMutableParagraphStyle alloc]init];
    [myParagraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    
    if ([parentProperties boolForKey:@"wrap"]) [myParagraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
    else [myParagraphStyle setLineBreakMode:NSLineBreakByClipping];
    
    switch ([parentProperties integerForKey:@"alignment"])
    {
        case ALIGN_LEFT: [myParagraphStyle setAlignment:NSLeftTextAlignment]; break;
        case ALIGN_CENTER: [myParagraphStyle setAlignment:NSCenterTextAlignment]; break;
        case ALIGN_RIGHT: [myParagraphStyle setAlignment:NSRightTextAlignment]; break;
        case ALIGN_JUSTIFIED: [myParagraphStyle setAlignment:NSJustifiedTextAlignment]; break;
    }
        
    NSFont *tmpFont = [NSFont fontWithName:[parentProperties objectForKey:@"fontName"] size:[[parentProperties objectForKey:@"fontSize"]floatValue]];    
    
    // here is where we override the scheme of the text. if you wanted to keep colors through the shell, here is where you would check for it
    NSDictionary *tmpAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [myParagraphStyle autorelease], NSParagraphStyleAttributeName,
                                   tmpFont, NSFontAttributeName,
                                   [NSUnarchiver unarchiveObjectWithData:[parentProperties objectForKey:@"textColor"]], NSForegroundColorAttributeName,
                                   nil];
    
    [self setAttributes:tmpAttributes];
    [[window textView]setAttributes:attributes];
}

#pragma mark -
#pragma mark Window operations
- (void)front
{
    [window orderFront:self];
}

- (void)setImage:(NSString*)urlStr
{    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    NSImage *myImage = [[NSImage alloc]initByReferencingURL:[NSURL URLWithString:urlStr]];
    [[window imageView]setImage:myImage];
    [myImage release];
    [pool release];
}

#pragma mark Accessors
- (NSRect)screenToRect:(NSRect)appleCoordRect
{
    // remember, the coordinates we use are with respect to the top left corner (both window and screen), but the actual OS takes them with respect to the bottom left (both window and screen), so we must convert between these
    NSRect screenSize = [[NSScreen mainScreen] frame];
    return NSMakeRect(appleCoordRect.origin.x,(screenSize.size.height - appleCoordRect.origin.y - appleCoordRect.size.height),appleCoordRect.size.width,appleCoordRect.size.height);
}

- (NSRect)rect
{
    return NSMakeRect([parentProperties integerForKey:@"x"],
                      [parentProperties integerForKey:@"y"],
                      [parentProperties integerForKey:@"w"],
                      [parentProperties integerForKey:@"h"]);
}

- (int)imageFit
{
    switch ([parentProperties integerForKey:@"imageFit"])
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

- (int)imageAlignment
{
    switch ([parentProperties integerForKey:@"pictureAlignment"])
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

@end
