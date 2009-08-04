//
//  LogController.h
//  GeektoolPreferencePane
//
//  Created by Kevin Nygaard on 3/18/09.
//  Copyright 2009 AllocInit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTLog;

@interface LogController : NSArrayController
{
    IBOutlet id groupController;
    BOOL _userInsert;
    
    IBOutlet id prefsView;
    IBOutlet id defaultPrefsView;
    IBOutlet id defaultPrefsViewText;
    
    // drag n drop
    NSString *MovedRowsType;
    NSString *CopiedRowsType;
    IBOutlet id tableView;

    // observing
    NTLog *_oldSelectedLog;
}
- (void)awakeFromNib;
- (void)dealloc;
// UI
- (IBAction)displayLogTypeMenu:(id)sender;
- (IBAction)displayLogGearMenu:(id)sender;
// Exporting
- (IBAction)exportSelectedLogs:(id)sender;
- (NSArray*)exportLogs:(NSArray*)logs withRootDestination:(NSString*)rootPath;
// Importing
- (IBAction)importLogs:(id)sender;
- (void)importLogsAtPaths:(NSArray*)logPaths;
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
// Content Add/Dupe/Remove
- (void)removeObjectsAtArrangedObjectIndexes:(NSIndexSet *)indexes;
- (IBAction)duplicate:(id)sender;
- (IBAction)insertLog:(id)sender;
- (void)insertObject:(id)object atArrangedObjectIndex:(NSUInteger)index;
- (void)insertObjects:(NSArray *)objects atArrangedObjectIndexes:(NSIndexSet *)indexes;
// Observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
- (NSIndexSet *)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)fromIndexSet toIndex:(unsigned int)insertIndex;
@end
