//
//  NTLogProcess.m
//  NerdTool
//
//  Created by Kevin Nygaard on 6/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTLogProcess.h"
#import "LogWindow.h"
#import "LogTextField.h"
#import "AIQuartzView.h"
#import "NSDictionary+IntAndBoolAccessors.h"
#import "defines.h"

@implementation NTLogProcess

@synthesize windowController;
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
    return self;
    
}

- (id)init
{
    return [self initWithParentLog:nil];
}

- (void)dealloc
{
    [windowController close];
    [windowController release];
    [env release];
    [task release];
    [self retain];
    [timer invalidate];
    [timer release];
    [super dealloc];
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
    [windowController showWindow:self];
}

// Gets called when initializing a log for viewing. All initialization for all log types should occur here
- (void)createWindow
{        
    // we have to do this here instead of in the nib because we get an "invalid drawable" error if its done via the nib
    [[window quartzView]setHidden:TRUE];
    [window setHasShadow:[parentProperties boolForKey:@"shadowWindow"]];
    
    switch ([parentProperties integerForKey:@"type"])
    {
        case TYPE_FILE:
            if ([[parentProperties objectForKey:@"file"]isEqual:@""]) return;
            
            // Read file to 50 lines. The -F file makes sure the file keeps getting read even if it hits the EOF or the file name is changed
            if (task) [task release];
            task = [[NSTask alloc]init];
            NSPipe *pipe = [NSPipe pipe];
            
            [task setLaunchPath:@"/usr/bin/tail"];
            [task setArguments:[NSArray arrayWithObjects:@"-n",@"50",@"-F",[parentProperties objectForKey:@"file"],nil]];
            [task setEnvironment:env];
            [task setStandardOutput:pipe];
            [[pipe fileHandleForReading]waitForDataInBackgroundAndNotify];

            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:@"NSFileHandleReadCompletionNotification" object:[pipe fileHandleForReading]];
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:@"NSFileHandleDataAvailableNotification" object:[pipe fileHandleForReading]];
            
            [task launch];
            break;
            
        case TYPE_QUARTZ:
            [[window quartzView]setHidden:FALSE];
            
            if (![[parentProperties objectForKey:@"quartzFile"]isEqual:@""]) break;
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
    
    [window setClickThrough:YES];
    [window setLevel:(([parentProperties integerForKey:@"alwaysOnTop"])?[parentProperties integerForKey:@"alwaysOnTop"]:kCGDesktopWindowLevel)];
    [window setSticky:(![parentProperties boolForKey:@"alwaysOnTop"])];
    [[window imageView] setImageAlignment:[self imageAlignment]];
    
    //==Init==
    switch ([parentProperties integerForKey:@"type"])
    {
        case TYPE_FILE:
            [self updateTextAttributes];
            
            [[window textView]scrollEnd];
            break;
            
        case TYPE_SHELL:
            [self updateTextAttributes];
            
            // if we need new timers
            if (timerNeedsUpdate)
            {
                [self setArguments:[[[NSArray alloc]initWithObjects:@"-c",[parentProperties objectForKey:@"command"],nil]autorelease]];
                
                [[window textView]addText:@"" clear:YES];
                [self updateTimer];
            }
            
            [[window textView]scrollEnd];
            break;
            
        case TYPE_IMAGE:
            // make a nice environment for the image
            [window setTextBackgroundColor:[NSColor clearColor]];
            [window setAlphaValue:([parentProperties integerForKey:@"transparency"])];
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
            
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(processNewDataFromTask:) name:@"NSFileHandleReadToEndOfFileCompletionNotification" object:[pipe fileHandleForReading]];
            [[pipe fileHandleForReading]readToEndOfFileInBackgroundAndNotify];

            [task launch];
            
            [pipe release];
            break;
            
        case TYPE_IMAGE:
            [NSThread detachNewThreadSelector:@selector(setImage:)
                                     toTarget:self
                                   withObject:[parentProperties objectForKey:@"imageURL"]];            
            break;
            
            // if its quartz, we just tell AIQuartzView we want a render. notice that we must send information about ourself so we can render a specific log (instead of rendering all quartz objects)
        case TYPE_QUARTZ:
             //[[NSDistributedNotificationCenter defaultCenter]postNotificationName:@"GTLogUpdate" object:@"GeekTool" userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[properties objectForKey:@"refresh"]]forKey:@"ident"]deliverImmediately:NO];
            break;
            // notice we don't have a case for FILE because it does not need to be updated
    }
}

- (void)processNewDataFromTask:(NSNotification*)aNotification
{
    NSData *newData;
    
    if ([[aNotification name]isEqual:@"NSFileHandleReadToEndOfFileCompletionNotification"])
    {
        newData = [[aNotification userInfo]objectForKey:@"NSFileHandleNotificationDataItem"];
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
        [[window textView] setAttributes:attributes];
    }
    
    [window display];
    [newString release];
}

#pragma mark Update
- (void)updateTimer
{
    if (timer)
    {
        [self retain];
        [timer invalidate];
        [timer release];
    }
    timer = [[NSTimer scheduledTimerWithTimeInterval:[parentProperties integerForKey:@"refresh"]target:self selector:@selector(updateCommand:) userInfo:nil repeats:YES]retain];
    [timer fire];
    
    [self release]; // when the timer is added to the runloop, we are retained. we don't want to be.
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
    [window orderFront: self];
}

- (void)setImage:(NSString*)urlStr
{    
    NSImage *myImage = [[NSImage alloc]initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:urlStr]]];
    [[window imageView] setImage:myImage];
    [myImage release];
}

#pragma mark Accessors

- (NSRect)screenToRect:(NSRect)var
{
    // remember, the coordinates we use are with respect to the top left corner (both window and screen), but the actual OS takes them with respect to the bottom left (both window and screen), so we must convert between these
    NSRect screenSize = [[NSScreen mainScreen] frame];
    return NSMakeRect(var.origin.x,(screenSize.size.height - var.origin.y) - var.size.height,var.size.width,var.size.height);
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
