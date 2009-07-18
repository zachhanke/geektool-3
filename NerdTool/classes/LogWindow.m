#import "LogWindow.h"
#import <Carbon/Carbon.h>
#import "CGSPrivate.h"

@implementation LogWindow

@synthesize parentLog;

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:backingType defer:NO];
    if (self != nil)
    {
        [self setHighlighted:NO];
        [self setHasShadow:NO];
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [textView setEnabled:NO];
        [self setReleasedWhenClosed:YES];
    }
    return self;
}

// Custom windows that use the NSBorderlessWindowMask can't become key by default. Override this method so that controls in this window will be enabled.
- (BOOL)canBecomeKeyWindow
{
    return YES;
}

#pragma mark Window Properties
- (void)setHighlighted:(BOOL)flag
{
    [self setClickThrough:!flag];
    [logView setHighlighted:flag];
}

- (void)setClickThrough:(BOOL)clickThrough
{
    /* carbon */
    void *ref = [self windowRef];
    if (clickThrough) ChangeWindowAttributes(ref,kWindowIgnoreClicksAttribute,kWindowNoAttributes);
    else ChangeWindowAttributes(ref,kWindowNoAttributes,kWindowIgnoreClicksAttribute);
    /* cocoa */
    [self setIgnoresMouseEvents:clickThrough];
}

// sticky in that the window will stay put during expose
- (void)setSticky:(BOOL)flag 
{
    CGSConnection cid;
    CGSWindow wid;
    
    wid = [self windowNumber];
    cid = _CGSDefaultConnection();
    int tags[2] = {0,0};   
    
    if(!CGSGetWindowTags(cid,wid,tags,32))
    {
        if (flag) tags[0] = tags[0] | 0x00000800;
        else tags[0] = tags[0] & ~0x00000800;
        CGSSetWindowTags(cid,wid,tags,32);
    }
}

#pragma mark Text Properties
- (void)setTextColor:(NSColor*)color
{
    [textView setTextColor:color];
}

- (void)setTextBackgroundColor:(NSColor*)color
{
    [scrollView setBackgroundColor:color];
    [self setBackgroundColor:[NSColor clearColor]];
}

- (void)setTextRect:(NSRect)rect
{
    [scrollView setFrame:rect];
    [scrollView display];
}

#pragma mark Accessors
- (LogTextField*)textView
{
    return textView;
}

@end