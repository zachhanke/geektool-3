/* GeekTool */

#import <Cocoa/Cocoa.h>

@interface NSLogView : NSView
{
    NSPoint mouseLoc;
    NSRect windowFrame;
    
    IBOutlet id logWindowController;
    IBOutlet id picture;
    IBOutlet id text;
    
    int highlighted;
    int dragType;
    NSTimer *timer;
    
    BOOL magn;
    NSMutableArray *xGuides;
    NSMutableArray *yGuides;
    
    NSArray *rectCache;
}
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)fetchRects;
- (void)setHighlighted:(BOOL)flag;
- (NSRect)convertToNTCoords:(NSRect)appleCoordRect;
@end