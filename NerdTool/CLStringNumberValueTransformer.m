//
//  CLStringNumberValueTransformer.m
//
//  Created by Alex Clarke on 15/01/05.
//	2005 CocoaLab. All rights reserved.
//

#import "CLStringNumberValueTransformer.h"


@implementation CLStringNumberValueTransformer

+ (Class)transformedValueClass;
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation;
{
    return YES;   
}

- (id)transformedValue:(id)value;
{
	NSString * valueString = [value stringValue];
	return valueString;	
}

- (id)reverseTransformedValue:(id)value
{
	int valueInt = [value intValue];
	NSNumber * valueNumber = [NSNumber numberWithInt:valueInt];
	return valueNumber;
}

@end
