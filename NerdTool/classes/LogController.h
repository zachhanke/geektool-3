//
//  LogController.h
//  GeektoolPreferencePane
//
//  Created by Kevin Nygaard on 3/18/09.
//  Copyright 2009 AllocInit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLogProtocol.h"

@class GTLog;

@interface LogController : NSArrayController
{
    IBOutlet id groupController;
    BOOL _userInsert;
    
    IBOutlet id prefsView;
    
    // drag n drop
    NSString *MovedRowsType;
    NSString *CopiedRowsType;
    IBOutlet id tableView;

    // observing
    id<NTLogProtocol> _oldSelectedLog;
}
- (void)awakeFromNib;
- (void)dealloc;
// UI
- (IBAction)displayLogTypeMenu:(id)sender;
// Content Add/Dupe/Remove
- (void)removeObjectsAtArrangedObjectIndexes:(NSIndexSet *)indexes;
- (IBAction)duplicate:(id)sender;
- (IBAction)insertLog:(id)sender;
- (void)insertObject:(id)object atArrangedObjectIndex:(NSUInteger)index;
- (void)insertObjects:(NSArray *)objects atArrangedObjectIndexes:(NSIndexSet *)indexes;
// File handling
- (IBAction)fileChoose:(id)sender;
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
// Observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
// Drag n' Drop Stuff
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard;
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;
- (NSIndexSet *)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)fromIndexSet toIndex:(unsigned int)insertIndex;
@end