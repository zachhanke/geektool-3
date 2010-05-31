/*
 * NSWindow+StickyWindow.m
 * NerdTool
 * Created by Kevin Nygaard on 5/30/10.
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

#import "NSWindow+StickyWindow.h"
#import "CGSPrivate.h"
#import <Carbon/Carbon.h>

@implementation NSWindow (StickyWindow)

// sticky in that the window will stay put during expose
- (void)setSticky:(BOOL)flag
{
    CGSConnection cid;
    CGSWindow wid;
    
    wid = [self windowNumber];
    cid = _CGSDefaultConnection();
    int tags[2] = {0,0};   
    
    if(!CGSGetWindowTags(cid,wid,tags,32))
    {
        if (flag) tags[0] = tags[0] | 0x00000800;
        else tags[0] = tags[0] & ~0x00000800;
        CGSSetWindowTags(cid,wid,tags,32);
    }
}

- (void)setClickThrough:(BOOL)clickThrough
{
    /* carbon */
    void *ref = [self windowRef];
    if (clickThrough) ChangeWindowAttributes(ref,kWindowIgnoreClicksAttribute,kWindowNoAttributes);
    else ChangeWindowAttributes(ref,kWindowNoAttributes,kWindowIgnoreClicksAttribute);
    /* cocoa */
    [self setIgnoresMouseEvents:clickThrough];
}

@end
