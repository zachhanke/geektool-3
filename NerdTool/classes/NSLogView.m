#import "NSLogView.h"
#import "NTGroup.h"
#import "LogWindow.h"
#import "LogTextField.h"

#import "defines.h"

#define MoveDragType 2
#define ResizeDragType 1

#define SNAP_TOLERANCE 10.0

#define MIN_W 40
#define MIN_H 10

// this class exists so we can move/resize our borderless window unfortunately, these common functions are unavailable to us because we are using an NSBorderlessWindow, so we must recreate them manually ourselves
@implementation NSLogView

- (void)awakeFromNib
{
    highlighted = NO;
    [self setNextResponder: [NSApplication sharedApplication]];
}

#pragma mark View Attributes
// lets us so user can move window immediately, instead of clicking on it to make it "active" and then again to actually move it
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

// dont push logs up to the top
- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent
{
    if ([theEvent type] == NSLeftMouseDragged) return NO;
    else return YES;
}

- (BOOL)acceptsFirstResponder
{
    if (highlighted)
        return YES;
    return NO;
}

- (BOOL)resignFirstResponder
{
    if (highlighted)
        return YES;
    return NO;
}

- (BOOL)becomeFirstResponder
{
    if (highlighted)
        return YES;
    return NO;
}

#pragma mark Mouse Handling
- (void)mouseDown:(NSEvent *)theEvent
{
    NSWindow *window = [self window];
    dragType = 0;
    
    // dont accept clicks if the view is not highlighted
    if (!highlighted) return;
    
    mouseLoc = [window convertBaseToScreen:[theEvent locationInWindow]];
    windowFrame = [window frame];
    
    // figure out where we are clicking either on the resize handle or not
    if (NSMouseInRect(mouseLoc,NSMakeRect(NSMaxX(windowFrame) - 10,NSMaxY(windowFrame) - NSHeight(windowFrame),10,10),NO))
        dragType = ResizeDragType;
    else
        dragType = MoveDragType;
    
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"lockSize"]) dragType = MoveDragType;
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"NSLogViewMouseDown" object:window];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSWindow *window = [self window];
    NSRect newWindowFrame = windowFrame;
    
    if (dragType == ResizeDragType)
    {                
        // Get the mouse location in window coordinates.    
        NSPoint currentMouseLoc = [NSEvent mouseLocation];
        
        NSPoint delta = NSMakePoint(currentMouseLoc.x - mouseLoc.x,currentMouseLoc.y - mouseLoc.y);
        
        newWindowFrame.size.width += delta.x;
        newWindowFrame.size.height -= delta.y;
        newWindowFrame.origin.y += delta.y;
        //X coord does not change
        //windowFrame.origin.x;
        
        
        // don't let the window be resized smaller than 20x20
        if (NSWidth(newWindowFrame) < MIN_W)
            newWindowFrame.size.width = MIN_W;
        
        if (NSHeight(newWindowFrame) < MIN_H)
        {
            newWindowFrame.origin.y -= MIN_H - NSHeight(newWindowFrame);
            newWindowFrame.size.height = MIN_H;
        }
                
        [window setFrame:newWindowFrame display:YES animate:NO];
        [[NSNotificationCenter defaultCenter]postNotificationName:NSWindowDidResizeNotification object:window];
        
        int type = [[[[(LogWindow*)[logWindowController window]parentLog]properties]valueForKey:@"type"]intValue];
        if (type == TYPE_SHELL || type == TYPE_FILE) [[(LogWindow*)[logWindowController window]textView]scrollEnd];
    }
    else
    {
        NSPoint currentMouseLoc = [NSEvent mouseLocation];
        
        // Update the origin with the difference between the new mouse location and the old mouse location.
        newWindowFrame.origin.x += (currentMouseLoc.x - mouseLoc.x);
        newWindowFrame.origin.y += currentMouseLoc.y - mouseLoc.y;
        
        NSRect screen = [[NSScreen mainScreen]frame];
        
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"expose"])
        {
            // bound by expose border
            if (NSMinX(newWindowFrame) < EXPOSE_WIDTH) newWindowFrame.origin.x = EXPOSE_WIDTH;
            if (NSMaxX(newWindowFrame) > NSWidth(screen) - EXPOSE_WIDTH) newWindowFrame.origin.x = screen.size.width - EXPOSE_WIDTH - NSWidth(newWindowFrame);
            if (NSMinY(newWindowFrame) < EXPOSE_WIDTH) newWindowFrame.origin.y = EXPOSE_WIDTH;
            if (NSMaxY(newWindowFrame) > NSHeight(screen) - MENU_BAR_HEIGHT - EXPOSE_WIDTH) newWindowFrame.origin.y = NSHeight(screen) - MENU_BAR_HEIGHT - EXPOSE_WIDTH - NSHeight(newWindowFrame);
        }
        
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"magneticWindows"])
        {
            for (NSWindow *tmpWindow in [NSApp windows])
            {
                if ([tmpWindow class] != [LogWindow class] || [self window] == tmpWindow) continue;
                NSRect frame = [tmpWindow frame];                
                
                // horizontal magnet
                if (fabs(NSMinX(frame) - NSMinX(newWindowFrame)) <= SNAP_TOLERANCE) newWindowFrame.origin.x = frame.origin.x;
                if (fabs(NSMinX(frame) - NSMaxX(newWindowFrame)) <= SNAP_TOLERANCE) newWindowFrame.origin.x += NSMinX(frame) - NSMaxX(newWindowFrame);
                if (fabs(NSMaxX(frame) - NSMinX(newWindowFrame)) <= SNAP_TOLERANCE) newWindowFrame.origin.x = NSMaxX(frame);
                if (fabs(NSMaxX(frame) - NSMaxX(newWindowFrame)) <= SNAP_TOLERANCE) newWindowFrame.origin.x += NSMaxX(frame) - NSMaxX(newWindowFrame);
                
                // vertical magnet
                if (fabs(NSMinY(frame) - NSMinY(newWindowFrame)) <= SNAP_TOLERANCE) newWindowFrame.origin.y = frame.origin.y;
                if (fabs(NSMinY(frame) - NSMaxY(newWindowFrame)) <= SNAP_TOLERANCE) newWindowFrame.origin.y += NSMinY(frame) - NSMaxY(newWindowFrame);
                if (fabs(NSMaxY(frame) - NSMinY(newWindowFrame)) <= SNAP_TOLERANCE) newWindowFrame.origin.y = NSMaxY(frame);
                if (fabs(NSMaxY(frame) - NSMaxY(newWindowFrame)) <= SNAP_TOLERANCE) newWindowFrame.origin.y += NSMaxY(frame) - NSMaxY(newWindowFrame);
            }
        }
        
        // Move the window to the new location
        [[NSNotificationCenter defaultCenter]postNotificationName:NSWindowWillMoveNotification object:window];
        [window setFrameOrigin:newWindowFrame.origin];
        [[NSNotificationCenter defaultCenter]postNotificationName:NSWindowDidMoveNotification object:window];
    }
}

- (void)mouseUp:(NSEvent *)theEvent;
{
    [[NSNotificationCenter defaultCenter]postNotificationName:@"NSLogViewMouseUp" object:[self window]];
    
    [text display];
}

#pragma mark View Drawing
- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    NSBezierPath *bp = [NSBezierPath bezierPathWithRect:[self bounds]];
    NSColor *color;
    
    if (highlighted)
    {
        color = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults]objectForKey:@"selectionColor"]];
        [color set];
        [bp fill];
        
        [[NSImage imageNamed:@"corner"] drawInRect:(NSRect){{[self bounds].size.width - 11,0},{11,11}} fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    else
    {
        // make the background clear
        color = [NSColor clearColor];
        [color set];
        [bp fill];

        NSRectFillUsingOperation((NSRect){{[self bounds].size.width - 11,0},{11,11}},NSCompositeSourceOver);
    }
}

#pragma mark Misc Actions
- (void)setHighlighted:(BOOL)flag
{
    highlighted = flag;
    //if (highlighted) [[self window] makeKeyWindow];
    [self setNeedsDisplay:YES];
}
@end
