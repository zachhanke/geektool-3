/* LogWindow */

#import <Cocoa/Cocoa.h>
#import "NTLogProtocol.h"

@class LogTextField;

@interface LogWindow : NSWindow
{
    IBOutlet id textView;
    IBOutlet id scrollView;
    IBOutlet id logView;
    
    id<NTLogProtocol> *parentLog;
}
@property (assign) id<NTLogProtocol> *parentLog;

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag;
- (BOOL)canBecomeKeyWindow;
- (void)setHighlighted:(BOOL)flag;
- (void)setClickThrough:(BOOL)clickThrough;
- (void)setSticky:(BOOL)flag ;
- (void)setTextColor:(NSColor*)color;
- (void)setTextBackgroundColor:(NSColor*)color;
- (void)setTextRect:(NSRect)rect;
- (LogTextField*)textView;
@end
