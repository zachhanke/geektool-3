/*
 * NTTreeController.h
 * NerdTool
 * Created by Kevin Nygaard on 5/22/10.
 * Copyright 2010 MutableCode. All rights reserved.
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

// TODO plug original developer
#import <Cocoa/Cocoa.h>

typedef enum {
    NTLogOperatorNothing          = 1 << 0,
    NTLogOperatorReorderLogs      = 1 << 1,
    NTLogOperatorCreateLogs       = 1 << 2,
    NTLogOperatorDestroyLogs      = 1 << 3,
    NTLogOperatorHighlightLogs    = 1 << 4,
    NTLogOperatorUnhighlightLogs  = 1 << 5
} NSLogOperator;


@interface NTTreeController : NSTreeController
{
    // Observing
    NSArray *previousSelectedLogs;
    IBOutlet id prefsView;
    IBOutlet id defaultPrefsView;
    IBOutlet id defaultPrefsViewText;    
}
- (void)_updateSortOrderOfModelObjects;

@property (copy) NSArray *previousSelectedLogs;

@end
