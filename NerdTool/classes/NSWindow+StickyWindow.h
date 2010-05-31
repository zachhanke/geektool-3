//
//  NSWindow+StickyWindow.h
//  NerdTool
//
//  Created by Kevin Nygaard on 5/30/10.
//  Copyright 2010 MutableCode. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSWindow (StickyWindow)
- (void)setSticky:(BOOL)flag;
- (void)setClickThrough:(BOOL)clickThrough;
@end
