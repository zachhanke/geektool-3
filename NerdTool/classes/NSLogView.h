/* GeekTool */

#import <Cocoa/Cocoa.h>

@interface NSLogView : NSView
{
    NSPoint mouseLoc;
    NSRect windowFrame;
    
    IBOutlet id logWindowController;
    IBOutlet id text;
    
    int highlighted;
    int dragType;
    NSTimer *timer;
}
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)setHighlighted:(BOOL)flag;
@end