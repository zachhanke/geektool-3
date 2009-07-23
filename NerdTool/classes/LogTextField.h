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
    NSDictionary *attributes;
}
@property (copy) NSDictionary *attributes;

- (void)awakeFromNib;
// Text Properties
- (void)applyAttributes:(NSDictionary *)attrs;
- (void)updateTextAttributesUsingProps:(NSDictionary *)properties;
- (void)processAndSetText:(NSMutableString *)newString withEscapes:(BOOL)translateAsciiEscapes insert:(BOOL)insert;
- (NSAttributedString *)combineAttributes:(NSDictionary *)attrs withAttributedString:(NSAttributedString *)attributedString;
// Text Actions
- (void)scrollEnd;
// Attributes
- (BOOL)isOpaque;
- (BOOL)shouldDrawInsertionPoint;
- (BOOL)acceptsFirstResponder;
- (BOOL)resignFirstResponder;
- (BOOL)becomeFirstResponder;
@end
