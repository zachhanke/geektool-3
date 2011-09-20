//
//  NTUtility.h
//  NerdTool
//
//  Created by Kevin Nygaard on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NTLog.h"
#import "LogProtocol.h"
#import <sys/types.h>
#import <sys/sysctl.h>
#import <mach-o/arch.h>
#import <mach/mach.h>
#import <mach/mach_error.h>

@interface NTUtility : NTLog <LogProtocol> {
    IBOutlet id formattingString;
    IBOutlet id refresh;
    IBOutlet id printMode;
    int oldPrintMode;
    
    // Mach host
	host_name_port_t theHost;
	// Default processor set
	processor_set_name_port_t theProcessorSet;
	// Previous processor tick data
	processor_cpu_load_info_t priorCPUTicks;    
}

#pragma mark Properties
- (NSString *)logTypeName;
- (BOOL)needsDisplayUIBox;
- (NSString *)preferenceNibName;
- (NSString *)displayNibName;
- (NSDictionary *)defaultProperties;
- (void)createLogProcess;
#pragma mark Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee;
- (void)destroyInterfaceBindings;
#pragma mark Observing
- (void)setupPreferenceObservers;
- (void)removePreferenceObservers;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
#pragma mark Window Management
- (void)updateWindowIncludingTimer:(BOOL)updateTimer;
#pragma mark Task
- (void)updateCommand:(NSTimer*)timer;
- (void)notificationHandler:(NSNotification *)notification;
#pragma mark Data Fetching
#pragma mark Disk
- (NSString*)diskSpace:(NSString*)formattingString;
#pragma mark CPU: direct sysctl attributes
- (NSString*)clockSpeed;
- (NSString*)cpuCount;
- (NSString*)kernelOSType;
- (NSString*)kernelVersion;
- (NSString*)hostname;
#pragma mark CPU: other attributes
- (NSString *)cpuPrettyName;
- (NSString *)currentProcessorTasks:(NSString*)format;
- (NSString *)loadAverage;
- (NSString *)currentLoad:(BOOL)averageAllProcs args:(NSString*)format;
- (NSString *)getUptime:(NSString*)format;
#pragma mark  
- (void)parseInputString:(NSString*)inputString;
- (void)awakeFromNib;
#pragma mark Utility
- (NSString*)humanizeSize:(unsigned long long)size;
- (NSString*)pullTextBetween:(NSString*)startMarker and:(NSString*)endMarker inString:(NSString*)formattedString rtnRange:(NSRange*)rtnRange;

@end
