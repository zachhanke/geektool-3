/*
 * AppDelegate.h
 * NerdTool
 * Updated by Kevin Nygaard on May 2010.
 *
 * Original file name: GeekToolPrefPref.h
 * Based on code by Yann Bizeul from Thu Nov 21 2002.
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


extern NSString *NTTreeNodeType;

@class NTLog;

@interface AppDelegate : NSObject 
{        
    IBOutlet id mainConfigWindow;
    IBOutlet id loginItem;
    
    // expose border
    NSMutableArray *windowControllerArray;
    NSMutableArray *exposeBorderWindowArray;    
    
    // Core Data
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    IBOutlet NSOutlineView *outlineView;
	IBOutlet NSTreeController *treeController;
}

- (IBAction)newLeaf:(id)sender;
- (IBAction)newGroup:(id)sender;

#pragma mark -
- (IBAction)trackROProcess:(id)sender;
#pragma mark UI management
- (IBAction)addAsLoginItem:(id)sender;
- (IBAction)logImport:(id)sender;
- (IBAction)revertDefaultSelectionColor:(id)sender;
- (IBAction)showExpose:(id)sender;
- (IBAction)donate:(id)sender;
- (IBAction)openReadme:(id)sender;
- (IBAction)refreshGroupSelection:(id)sender;
#pragma mark Saving
- (void)loadPreferences;
#pragma mark -
#pragma mark Misc

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)saveAction:sender;

@end
