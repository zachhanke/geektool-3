//
//  LogTextField.h
//  GeekTool
//
//  Created by Yann Bizeul on Sun Feb 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


@interface LogTextField : NSTextView
{    
    void *shadowValues;
    BOOL shadowText;
}
@property (assign) BOOL shadowText;

- (void)awakeFromNib;
- (void)setTextAlignment:(int)alignment;
- (void)setAttributes:(NSDictionary*)attributes;
- (void)setWrap:(BOOL)wrap;
- (void)scrollEnd;
- (void)addText:(NSString*)newText clear:(BOOL)clear;
- (void)drawRect:(NSRect)rect;
- (BOOL)isOpaque;
- (BOOL)shouldDrawInsertionPoint;
- (BOOL)acceptsFirstResponder;
- (BOOL)resignFirstResponder;
- (BOOL)becomeFirstResponder;
@end
