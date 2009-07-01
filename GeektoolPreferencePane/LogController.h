//
//  LogController.h
//  GeektoolPreferencePane
//
//  Created by Kevin Nygaard on 3/18/09.
//  Copyright 2009 AllocInit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class GTLog;

@interface LogController : NSArrayController
{
    // drag n drop
    NSString *MovedRowsType;
    NSString *CopiedRowsType;
    IBOutlet id tableView;

    // observing
    GTLog *oldSelectedLog;
}
#pragma mark Methods
// table view drag and drop support
- (BOOL)tableView:(NSTableView *)aTableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes
toPasteboard:(NSPasteboard *)pboard;
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;
// utility methods
-(NSIndexSet *)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)fromIndexSet
toIndex:(unsigned int)insertIndex;
@end