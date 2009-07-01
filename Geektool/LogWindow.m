#import "LogWindow.h"
#import <Carbon/Carbon.h>

// simply a window that holds logView, logTextField, and NSImageView
@implementation LogWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:backingType defer:NO];
    if (self != nil)
    {
        [self setHasShadow:NO];
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [text setEnabled:NO];
        [self setReleasedWhenClosed:YES];
    }
    return self;
}


// Custom windows that use the NSBorderlessWindowMask can't become key by default. Override this method so that controls in this window will be enabled.
- (BOOL)canBecomeKeyWindow
{
    return YES;
}

#pragma mark -
- (void)setHighlighted:(BOOL)flag;
{
    [self setClickThrough:!flag];
    [logView setHighlighted: flag];
}

- (void)setClickThrough:(BOOL)clickThrough
{
    /* carbon */
    void *ref = [self windowRef];
    if (clickThrough)
        ChangeWindowAttributes(ref,kWindowIgnoreClicksAttribute,kWindowNoAttributes);
    else
        ChangeWindowAttributes(ref,kWindowNoAttributes,kWindowIgnoreClicksAttribute);
    /* cocoa */
    [self setIgnoresMouseEvents:clickThrough];
}
@end