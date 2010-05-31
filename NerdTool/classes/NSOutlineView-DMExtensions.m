//  NSOutlineView-DMExtensions.m
//  Library
//
//  Created by William Shipley on 3/10/06.
//  Copyright 2006 Delicious Monster Software, LLC. Some rights reserved,
//    see Creative Commons license on wilshipley.com

#import "NSOutlineView-DMExtensions.h"

@interface NSOutlineView (DMExtensions_Private)
- (NSTreeController *)_treeController;
- (id)_realItemForOpaqueItem:(id)findOpaqueItem outlineRowIndex:(int *)outlineRowIndex
                       items:(NSArray *)items;
@end


@implementation NSOutlineView (DMExtensions)

- (id)realItemForOpaqueItem:(id)opaqueItem;
{
    int outlineRowIndex = 0;
    return [self _realItemForOpaqueItem:opaqueItem outlineRowIndex:&outlineRowIndex
                                  items:[[self _treeController] content]];
}

@end


@implementation NSOutlineView (DMExtensions_Private)

- (NSTreeController *)_treeController;
{
    return (NSTreeController *)[[self infoForBinding:NSContentBinding]
                                objectForKey:@"NSObservedObject"];
}

- (id)_realItemForOpaqueItem:(id)findOpaqueItem outlineRowIndex:(int *)outlineRowIndex
                       items:(NSArray *)items;
{
    unsigned int itemIndex;
    for (itemIndex = 0; itemIndex < [items count] && *outlineRowIndex < [self numberOfRows];
         itemIndex++, (*outlineRowIndex)++) {
        id realItem = [items objectAtIndex:itemIndex];
        id opaqueItem = [self itemAtRow:*outlineRowIndex];
        if (opaqueItem == findOpaqueItem)
            return realItem;
        if ([self isItemExpanded:opaqueItem]) {
            realItem = [self _realItemForOpaqueItem:findOpaqueItem outlineRowIndex:outlineRowIndex
                                              items:[realItem valueForKeyPath:[[self _treeController] childrenKeyPath]]];
            if (realItem)
                return realItem;
        }
    }
    
    return nil;
}

@end