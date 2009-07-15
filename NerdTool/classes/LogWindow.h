/* LogWindow */

#import <Cocoa/Cocoa.h>
@class GTLog;
@class QCView;
@class LogTextField;
@class AIQuartzView;

@interface LogWindow : NSWindow
{
    IBOutlet id textView;
    IBOutlet id scrollView;
    IBOutlet id logView;
    IBOutlet id imageView;
    IBOutlet id quartzView;
    
    GTLog *parentLog;
}
@property (assign) GTLog *parentLog;

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag;
- (BOOL)canBecomeKeyWindow;
- (void)setHighlighted:(BOOL)flag;
- (void)setClickThrough:(BOOL)clickThrough;
- (void)setSticky:(BOOL)flag ;
- (void)setTextColor:(NSColor*)color;
- (void)setTextBackgroundColor:(NSColor*)color;
- (void)setTextRect:(NSRect)rect;
- (AIQuartzView*)quartzView;
- (NSImageView*)imageView;
- (LogTextField*)textView;
@end
