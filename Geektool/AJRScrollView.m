#import "AJRScrollView.h"
#import "LogTextField.h"

// Holds our text view. Turns out this class was taken from some Cocoa mailing list to work around a problem with displaying semi-transparency for scroll views pre-Jaguar. Background colors are now displayed through NSTextField instead of NSScroll/ClipView
@implementation AJRScrollView
- (BOOL)isOpaque
{
    return NO;
}

// This first line is necessary, the remainder isn't...
- (void)awakeFromNib
{
    [self setDocumentView:textView];
    [[self contentView] setCopiesOnScroll:NO];
    [[self contentView] setDrawsBackground:NO];
}

- (void)setBackgroundColor:(NSColor *)aColor
{
    [[self documentView] setBackgroundColor:aColor];
}

@end
