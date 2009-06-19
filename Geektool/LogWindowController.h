/* LogWindowController */

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "LogWindow.h"

@interface LogWindowController : NSWindowController
{
    IBOutlet id text;
    IBOutlet id scrollView;
    IBOutlet id picture;
    IBOutlet id logView;
    IBOutlet id quartzView;
    int	type;
    int ident;
    //bool rc = NO;
}
- (void)awakeFromNib;
- (void)windowWillClose:(NSNotification *)aNotification;
#pragma mark KVC
- (void)setIdent:(int)value;
- (int)ident;
- (void)setType:(int)anInt;
- (int)type;
#pragma mark Only Accessors
- (id)quartzView;
- (id)logView;
#pragma mark -
#pragma mark Setters/Actions
#pragma mark Text Attributes
- (void)setFont:(NSFont*)font;
- (void)setShadowText:(bool)shadow;
- (void)setTextBackgroundColor:(NSColor*)color;
- (void)setTextColor:(NSColor*)color;
- (void)setTextAlignment:(int)alignment;
- (void)setWrap:(BOOL)wrap;
- (void)setTextRect:(NSRect)rect;
- (void)setAttributes:(NSDictionary*)attributes;
#pragma mark Text Actions
- (void)addText:(NSString*)newText clear:(BOOL)clear;
- (void)scrollEnd;
#pragma mark Window Attributes
- (void)setFrame:(NSRect)logWindowRect display:(bool)flag;
- (void)setHighlighted:(BOOL)flag;
- (void)setAutodisplay:(BOOL)value;
- (void)setHasShadow:(bool)flag;
- (void)setOpaque:(bool)flag;
- (void)setLevel:(int)level;
-(void)setSticky:(BOOL)flag ;
#pragma mark Window Actions
- (void)makeKeyAndOrderFront:(id)sender;
- (void)display;
#pragma mark Picture Attributes
- (void)setPictureAlignment:(int)alignment;
- (void)setFit:(int)fit;
- (void)setImage:(NSImage*)anImage;
#pragma mark Misc Functions
- (void)setCrop:(BOOL)crop;
@end
