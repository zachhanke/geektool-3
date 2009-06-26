#import "AJRScrollView.h"
#import "LogTextField.h"
@implementation AJRScrollView
// This is necessary
- (BOOL)isOpaque
{
    return NO;
}

// This isn't really necessary

- (void)drawRect:(NSRect)rect
{
    /*
    if ([self borderType] == NSLineBorder) {
        NSRect    bounds = [self bounds];

        [[NSColor colorWithCalibratedWhite:0.68 alpha:1.0] set];
        NSFrameRect(bounds);
    }
     */
}

// This first line is necessary, the remainder isn't...
- (void)awakeFromNib
{
    //[ self setContentView: textView ];
    [self setDocumentView: textView];
    [[self contentView] setCopiesOnScroll:NO];
    
    if ([[self documentView] isKindOfClass:[LogTextField class]])
    {
        [[self documentView] setBackgroundColor:[NSColor clearColor]];
        [[self documentView] setDrawsBackground:NO];
    }
}

@end