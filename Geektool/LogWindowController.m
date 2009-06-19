#import "LogWindowController.h"
#import "CGSPrivate.h"
#import "defines.h"

#define ZeroRange NSMakeRange(NSNotFound, 0)

// controls each individual log
@implementation LogWindowController

- (void)awakeFromNib
{
    //[quartzView setMaxRenderingFrameRate:0.1];
    //float tmp = [quartzView maxRenderingFrameRate];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [self autorelease];
}

#pragma mark KVC
- (void)setIdent:(int)value
{
    ident = value;
}

- (int)ident
{
    return ident;
}

- (void)setType:(int)anInt
{
    type = anInt;
}

- (int)type
{
    return type;
}

#pragma mark Only Accessors

- (id)quartzView
{
    return quartzView;
}

- (id)logView
{
    return logView;
}
#pragma mark -

#pragma mark Setters/Actions
#pragma mark Text Attributes
- (void)setFont:(NSFont*)font
{
    [text setFont: font];
}

- (void)setShadowText:(bool)shadow
{
    //[text setShadowText: shadow];
}

- (void)setTextBackgroundColor:(NSColor*)color
{
    [scrollView setBackgroundColor: color];
    [[self window] setBackgroundColor: [NSColor clearColor]];
}

- (void)setTextColor:(NSColor*)color
{
    [text setTextColor: color];
}

- (void)setTextAlignment:(int)alignment
{
    switch (alignment)
    {
        case ALIGN_LEFT:
            [text setAlignment:NSLeftTextAlignment];
            break;
        case ALIGN_CENTER:
            [text setAlignment:NSCenterTextAlignment];
            break;
        case ALIGN_RIGHT:
            [text setAlignment:NSRightTextAlignment];
            break;
        case ALIGN_JUSTIFIED:
            [text setAlignment:NSJustifiedTextAlignment];
            break;
    }
    //[self display];
}

- (void)setWrap:(BOOL)wrap
{
    if ([[text string] length] == 0 )
        [text setString: @" "];
    NSRange range=NSMakeRange(0,[[text string] length]);
    NSTextStorage *textStorage=[text textStorage];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle
                                                defaultParagraphStyle] mutableCopy];
    if (wrap)
        [paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
    else
        [paragraphStyle setLineBreakMode:NSLineBreakByClipping];
    [textStorage addAttribute:NSParagraphStyleAttributeName
                        value:paragraphStyle range:range];
    //[self display];
}

- (void)setTextRect:(NSRect)rect
{
    //[text setFrame: rect];
    //[text display];
    [scrollView setFrame: rect];
    [scrollView display];
}

- (void)setAttributes:(NSDictionary*)attributes
{
    // NSLog(@"%@",attributes);
    //    [[text textStorage] beginEditing];
    [[text textStorage] setAttributes: attributes range: NSMakeRange(0,[[text string] length])];
    //    [[text textStorage] endEditing];
    //[self display];
}

#pragma mark Text Actions
- (void)addText:(NSString*)newText clear:(BOOL)clear
{
    // TODO: I think here would be the place to add in colors
    
    NSMutableCharacterSet *cs = [[NSCharacterSet controlCharacterSet] mutableCopy];
    [cs removeCharactersInRange: NSMakeRange(10,1)]; // this is removing invisible characters I think
    
    NSMutableString *theText = [newText mutableCopy];
    NSRange r;
    while (! NSEqualRanges(r=[theText rangeOfCharacterFromSet: cs],ZeroRange))
    {
        [theText deleteCharactersInRange: r];
    }
    
    if (clear)
        [text setString: theText];
    else
        [text insertText: theText];
    [theText release];
    [cs release];
}

- (void)scrollEnd
{
    //NSRange range = NSMakeRange([[text string] length],0);
    NSRange range = NSMakeRange(0,0);
    [text scrollRangeToVisible: range];
}

#pragma mark Window Attributes
- (void)setFrame:(NSRect)logWindowRect display:(bool)flag
{
    [[self window] setFrame:logWindowRect display:flag];
}

- (void)setHighlighted:(BOOL)flag
{
    [(LogWindow*)[self window] setHighlighted: flag];
    [self display];
}

- (void)setAutodisplay:(BOOL)value
{
    [[self window] setAutodisplay:value];
}

- (void)setHasShadow:(bool)flag
{
    [[self window] setHasShadow:flag];
}

- (void)setOpaque:(bool)flag
{
    [[self window] setOpaque:flag];
}

- (void)setLevel:(int)level
{
    [[self window] setLevel:level];
}

-(void)setSticky:(BOOL)flag 
{
    CGSConnection cid;
    CGSWindow wid;
    SInt32 vers; 
    
    Gestalt(gestaltSystemVersion,&vers); 
    if (vers < 0x1030)
        return;
    wid = [[self window] windowNumber];
    cid = _CGSDefaultConnection();
    int tags[2];
    tags[0] = tags[1] = 0;
    OSStatus retVal = CGSGetWindowTags(cid, wid, tags, 32);
    if(!retVal) {
        if (flag)
            tags[0] = tags[0] | 0x00000800;
        else
            tags[0] = tags[0] & 0x00000800;
        
        retVal = CGSSetWindowTags(cid, wid, tags, 32);
    }
}

#pragma mark Window Actions
- (void)makeKeyAndOrderFront:(id)sender
{
    [[self window] makeKeyAndOrderFront:sender];
}

- (void)display
{
    //[[self window] display];
    [text display];
}

#pragma mark Picture Attributes
-(void)setPictureAlignment:(int)alignment
{
    [picture setImageAlignment: alignment];
}

-(void)setFit:(int)fit
{
    [picture setImageScaling: fit];
}

- (void)setImage:(NSImage*)anImage
{
    [picture setImage: anImage];
}

#pragma mark Misc Functions

-(void)setCrop:(BOOL)crop
{
    [logView setCrop: crop];
}
@end
