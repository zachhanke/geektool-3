/*
 * LogController.h
 * NerdTool
 * Created by Kevin Nygaard on 3/18/09.
 * Copyright 2009 AllocInit. All rights reserved.
 *
 * This file is part of NerdTool.
 * 
 * NerdTool is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * NerdTool is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with NerdTool.  If not, see <http://www.gnu.org/licenses/>.
 */

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
- (void)importLogAtPath:(NSString*)logPath toRow:(int)insertRow;
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
