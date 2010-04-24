//
//  NTUtility.m
//  NerdTool
//
//  Created by Kevin Nygaard on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NTUtility.h"


#import "NTLog.h"
#import "LogTextField.h"

#import "defines.h"
#import "NSDictionary+IntAndBoolAccessors.h"

#import "ANSIEscapeHelper.h"


#define DEFAULT_FLAG_DISKSPACE @"default"
#define DEFAULT_FLAG_UPTIME @"default"
#define DEFAULT_FLAG_CURRENTLOAD @"default"
#define DEFAULT_FLAG_CURRENTTASKS @"default"

@implementation NTUtility

#pragma mark Properties
- (NSString *)logTypeName
{
    return NSLocalizedString(@"Utility",nil);
}

- (BOOL)needsDisplayUIBox
{
    return YES;
}

- (NSString *)preferenceNibName
{
    return @"utilityPrefs";
}

- (NSString *)displayNibName
{
    return @"shellWindow";
}

- (NSDictionary *)defaultProperties
{
    NSDictionary *defaultProperties = [[NSDictionary alloc]initWithObjectsAndKeys:
                                       NSLocalizedString(@"New utility log",nil),@"name",
                                       [NSNumber numberWithBool:YES],@"enabled",
                                       
                                       [NSNumber numberWithInt:16],@"x",
                                       [NSNumber numberWithInt:38],@"y",
                                       [NSNumber numberWithInt:280],@"w",
                                       [NSNumber numberWithInt:150],@"h",
                                       [NSNumber numberWithBool:NO],@"alwaysOnTop",
                                       [NSNumber numberWithBool:NO],@"sizeToScreen",
                                       
                                       @"date",@"formattingString",
                                       [NSNumber numberWithInt:10],@"refresh",
                                       
                                       [NSArchiver archivedDataWithRootObject:[NSFont systemFontOfSize:[NSFont systemFontSize]]],@"font",
                                       [NSNumber numberWithInt:NSASCIIStringEncoding],@"stringEncoding",
                                       [[NSUserDefaults standardUserDefaults]objectForKey:@"defaultFgColor"],@"textColor",
                                       [[NSUserDefaults standardUserDefaults]objectForKey:@"defaultBgColor"],@"backgroundColor",
                                       [NSNumber numberWithBool:NO],@"wrap",
                                       [NSNumber numberWithBool:NO],@"shadowText",
                                       [NSNumber numberWithBool:NO],@"shadowWindow",
                                       [NSNumber numberWithBool:NO],@"useAsciiEscapes",
                                       [NSNumber numberWithInt:ALIGN_LEFT],@"alignment",
                                       
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBlack],@"fgBlack",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgRed],@"fgRed",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgGreen],@"fgGreen",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgYellow],@"fgYellow",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBlue],@"fgBlue",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgMagenta],@"fgMagenta",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgCyan],@"fgCyan",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgWhite],@"fgWhite",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBlack],@"bgBlack",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgRed],@"bgRed",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgGreen],@"bgGreen",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgYellow],@"bgYellow",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBlue],@"bgBlue",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgMagenta],@"bgMagenta",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgCyan],@"bgCyan",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgWhite],@"bgWhite",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightBlack],@"fgBrightBlack",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightRed],@"fgBrightRed",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightGreen],@"fgBrightGreen",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightYellow],@"fgBrightYellow",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightBlue],@"fgBrightBlue",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightMagenta],@"fgBrightMagenta",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightCyan],@"fgBrightCyan",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorFgBrightWhite],@"fgBrightWhite",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightBlack],@"bgBrightBlack",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightRed],@"bgBrightRed",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightGreen],@"bgBrightGreen",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightYellow],@"bgBrightYellow",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightBlue],@"bgBrightBlue",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightMagenta],@"bgBrightMagenta",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightCyan],@"bgBrightCyan",
                                       [NSArchiver archivedDataWithRootObject:kDefaultANSIColorBgBrightWhite],@"bgBrightWhite",
                                       nil];
    
    return [defaultProperties autorelease];
}

- (void)createLogProcess
{
    [super createLogProcess];
    oldPrintMode = [properties integerForKey:@"printMode"];

    // host_info params
	unsigned int processorCount;
	processor_cpu_load_info_t processorTickInfo;
	mach_msg_type_number_t processorMsgCount;
	// loops
	unsigned int i, j;
    
	// Set up our mach host and default processor set for later calls
	theHost = mach_host_self();
	processor_set_default(theHost, &theProcessorSet);
    
	// Build the storage for the prior ticks and store the first block of data
	kern_return_t kStatus = host_processor_info(theHost, PROCESSOR_CPU_LOAD_INFO, &processorCount, (processor_info_array_t *)&processorTickInfo, &processorMsgCount);
    
	if (kStatus != KERN_SUCCESS) return;
    
	priorCPUTicks = malloc(processorCount * sizeof(*priorCPUTicks));
	for (i = 0; i < processorCount; i++)
		for (j = 0; j < CPU_STATE_MAX; j++) priorCPUTicks[i].cpu_ticks[j] = processorTickInfo[i].cpu_ticks[j];
    
	vm_deallocate(mach_task_self(), (vm_address_t)processorTickInfo, (vm_size_t)(processorMsgCount * sizeof(*processorTickInfo)));
}

#pragma mark Interface
- (void)setupInterfaceBindingsWithObject:(id)bindee
{
    // These can get turned off if you have the text field selected, and then change logs. When you go back to that log, things are screwed up. The setEditable: fixes this (as well as makes them tasty :P)
    [formattingString setEditable:YES];
    [refresh setEditable:YES];
    
    [formattingString bind:@"value" toObject:bindee withKeyPath:@"selection.properties.formattingString" options:nil];
    [refresh bind:@"value" toObject:bindee withKeyPath:@"selection.properties.refresh" options:nil];
    [printMode bind:@"selectedIndex" toObject:bindee withKeyPath:@"selection.properties.printMode" options:nil];
}

- (void)destroyInterfaceBindings
{
    [formattingString unbind:@"value"];
    [refresh unbind:@"value"];
    [printMode unbind:@"selectedIndex"];
}

#pragma mark Observing
- (void)setupPreferenceObservers
{
    [self addObserver:self forKeyPath:@"properties.formattingString" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.refresh" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"properties.printMode" options:0 context:NULL];
    [super setupPreferenceObservers];
}

- (void)removePreferenceObservers
{
    [self removeObserver:self forKeyPath:@"properties.formattingString"];
    [self removeObserver:self forKeyPath:@"properties.refresh"];
    [self removeObserver:self forKeyPath:@"properties.printMode"];
    [super removePreferenceObservers];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"properties.enabled"] || [keyPath isEqualToString:@"active"])
    {
        if (windowController) [self destroyLogProcess];
        if (![[self active]boolValue] || ![properties boolForKey:@"enabled"]) return;
        
        [self createLogProcess];
        [self updateWindowIncludingTimer:YES];
    }
    // check if our LogProcess is alive
    else if (!windowController) return;
    else if ([keyPath isEqualToString:@"properties.command"] || [keyPath isEqualToString:@"properties.refresh"] || [keyPath isEqualToString:@"properties.printMode"])
    {
        [self updateWindowIncludingTimer:YES];
    }
    else if ([keyPath isEqualToString:@"properties.useAsciiEscapes"] || [keyPath isEqualToString:@"properties.stringEncoding"])
    {
        if (windowController && timer) [timer fire];
    }    
    else
    {
        [self updateWindowIncludingTimer:NO];
    }
    
    if (postActivationRequest)
    {
        postActivationRequest = NO;
        if(!highlightSender) return;
        [[self highlightSender]observeValueForKeyPath:@"selectedObjects" ofObject:self change:nil context:nil];
    }
}

#pragma mark Window Management
- (void)updateWindowIncludingTimer:(BOOL)updateTimer
{
    if (updateTimer)
    {
        [[window textView]setString:@""];
    }
    
    [super updateWindowIncludingTimer:updateTimer];
}

#pragma mark Task
- (void)updateCommand:(NSTimer*)timer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    NSArray* lines = [[[self properties]objectForKey:@"formattingString"] componentsSeparatedByString:@"\n"];
    NSMutableArray *outputLines = [NSMutableArray array];
    for (NSString* element in lines)
    {
        // don't touch comments
        if (![element hasPrefix:@"#"])
        {
            NSMutableString *mutElement = [NSMutableString stringWithString:element];
            while (1)
            {                
                NSRange replaceRange;
                NSString* commandString = [self pullTextBetween:@"${" and:@"}" inString:mutElement rtnRange:&replaceRange];                
                
                if (!commandString) break;
                
                // array starts with command at 0, followed subsequently by (optional) arguments (depending on the command)
                NSString* commandName = commandString;
                NSString* args = nil;
                NSString* replaceString = @"";
                if (!NSEqualRanges([commandString rangeOfString:@" "], NSMakeRange(NSNotFound, 0)))
                {
                    NSRange nameLocation;
                    commandName = [self pullTextBetween:@"" and:@" " inString:commandString rtnRange:&nameLocation];
                    args = [commandString stringByReplacingCharactersInRange:nameLocation withString:@""];
                }
                
                // disk
                if ([commandName isEqualToString:@"diskSpace"]) replaceString = [self diskSpace:args];
                // sysctl
                else if ([commandName isEqualToString:@"cpuSpeed"]) replaceString = [self clockSpeed];
                else if ([commandName isEqualToString:@"cpuCount"]) replaceString = [self cpuCount];
                else if ([commandName isEqualToString:@"kernOSType"]) replaceString = [self kernelOSType];
                else if ([commandName isEqualToString:@"kernVersion"]) replaceString = [self kernelVersion];
                else if ([commandName isEqualToString:@"hostname"]) replaceString = [self hostname];
                // load
                else if ([commandName isEqualToString:@"cpuName"]) replaceString = [self cpuPrettyName];
                else if ([commandName isEqualToString:@"currentTasks"]) replaceString = [self currentProcessorTasks:args];
                else if ([commandName isEqualToString:@"loadAverage"]) replaceString = [self loadAverage];
                else if ([commandName isEqualToString:@"currentLoad"]) replaceString = [self currentLoad:TRUE args:args];
                else if ([commandName isEqualToString:@"uptime"]) replaceString = [self getUptime:args];
                [mutElement replaceCharactersInRange:replaceRange withString:replaceString];
            }
            [outputLines addObject:mutElement];
        }
    }
    [(LogTextField*)[window textView]processAndSetText:[outputLines componentsJoinedByString:@"\n"] withEscapes:[[self properties]boolForKey:@"useAsciiEscapes"] andCustomColors:[self customAnsiColors] insert:NO];
    [(LogTextField*)[window textView]scrollEnd];
    [window display];
    
    [pool release];
}

- (void)notificationHandler:(NSNotification *)notification
{
    if ([[notification name]isEqualToString:NSWindowDidResizeNotification]) [(LogTextField *)[window textView]scrollEnd];
    [super notificationHandler:notification];
}
#pragma mark -
#pragma mark Data Fetching
#pragma mark Disk
- (NSString*)diskSpace:(NSString*)format
{    
    NSArray *tmp = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
    NSMutableString *workingString = [NSMutableString stringWithString:(format)?format:DEFAULT_FLAG_DISKSPACE];
    
    NSRange zeroRange = NSMakeRange(NSNotFound, 0);
    NSRange removeRange;
    NSString *selectedDrive = [self pullTextBetween:@":" and:@":" inString:workingString rtnRange:&removeRange];
    if (!NSEqualRanges(removeRange, zeroRange)) [workingString replaceCharactersInRange:removeRange withString:@""];
    if ([workingString isEqualToString:@""]) [workingString setString:DEFAULT_FLAG_DISKSPACE];
    if ([selectedDrive isEqualToString:@""]) selectedDrive = [[NSFileManager defaultManager] displayNameAtPath:@"/"];
    
    [workingString replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [workingString length])];
    
    for (NSString* path in tmp)
    {
        // check if we are looking at the drive the user wanted information for
        NSString *prettyName = [[NSFileManager defaultManager] displayNameAtPath:path];
        if (![prettyName isEqualToString:selectedDrive]) continue;
        
        // get data if possible
        BOOL success = NO;
        BOOL removableFlag, writableFlag, unmountableFlag;
        NSString *description, *fsType;
        success = [[NSWorkspace sharedWorkspace] getFileSystemInfoForPath:path isRemovable:&removableFlag isWritable:&writableFlag isUnmountable:&unmountableFlag description:&description type:&fsType];
        if (!success) continue;
        
        if ([workingString isEqualToString:@"name"]) return prettyName;
        else if ([workingString isEqualToString:@"path"]) return path;
        else if ([workingString isEqualToString:@"removable"]) return [NSString stringWithFormat:@"%i", removableFlag];
        else if ([workingString isEqualToString:@"writable"]) return [NSString stringWithFormat:@"%i", writableFlag];
        else if ([workingString isEqualToString:@"unmountable"]) return [NSString stringWithFormat:@"%i", unmountableFlag];
        else if ([workingString isEqualToString:@"description"]) return description;
        else if ([workingString isEqualToString:@"fsType"]) return fsType;
        
        NSDictionary *fsAttributes = [[NSFileManager defaultManager] fileSystemAttributesAtPath:path];
        
        if ([workingString isEqualToString:@"fsSize"]) return [self humanizeSize:[fsAttributes valueForKey:NSFileSystemSize]];
        else if ([workingString isEqualToString:@"fsFreeSize"]) return [self humanizeSize:[[fsAttributes objectForKey:NSFileSystemFreeSize] unsignedLongLongValue]];
        else if ([workingString isEqualToString:@"fsNodes"]) return [NSString stringWithFormat:@"%i", [fsAttributes valueForKey:NSFileSystemNodes]];
        else if ([workingString isEqualToString:@"fsFreeNodes"]) return [NSString stringWithFormat:@"%i", [fsAttributes valueForKey:NSFileSystemFreeNodes]];
        
        return @"Invalid option or syntax";
    }
    return @"Invalid drive";
}

#pragma mark CPU: direct sysctl attributes
- (NSString*)clockSpeed
{
    NSString *clockSpeed;
    UInt32 clockRate;
    size_t length = sizeof(clockRate);
    int mib[2] = {CTL_HW, HW_CPU_FREQ};
	sysctl(mib, 2, &clockRate, &length, NULL, 0);
	if (clockRate > 1000000000) clockSpeed = [NSString stringWithFormat:@"%@GHz", [NSNumber numberWithDouble:(double)clockRate / 1000000000]];
	else clockSpeed = [NSString stringWithFormat:@"%dMHz", clockRate / 1000000];
    return clockSpeed;
}

- (NSString*)cpuCount
{
    int cpuCount;
	size_t length = sizeof(cpuCount);
    int mib[2] = {CTL_HW, HW_NCPU};
	sysctl(mib, 2, &cpuCount, &length, NULL, 0);
    return [NSString stringWithFormat:@"%i",cpuCount];
}

- (NSString*)kernelOSType
{
    char osType[32];
	size_t length = sizeof(osType);
    int mib[2] = {CTL_KERN, KERN_OSTYPE};
	sysctl(mib, 2, &osType, &length, NULL, 0);
    return [NSString stringWithCString:osType length:length];
}

- (NSString*)kernelVersion
{
    char kernVersion[128];
	size_t length = sizeof(kernVersion);
    int mib[2] = {CTL_KERN, KERN_VERSION};
	sysctl(mib, 2, &kernVersion, &length, NULL, 0);
    return [NSString stringWithCString:kernVersion length:length];
}

- (NSString*)hostname
{
    char hostname[128];
	size_t length = sizeof(hostname);
    int mib[2] = {CTL_KERN, KERN_HOSTNAME};
	sysctl(mib, 2, &hostname, &length, NULL, 0);
    return [NSString stringWithCString:hostname length:length];
}

#pragma mark CPU: other attributes
- (NSString *)cpuPrettyName
{
	const NXArchInfo *archInfo;
	archInfo = NXGetLocalArchInfo();
	if (!archInfo) return @"Unknown CPU";
    
    return [NSString stringWithCString:archInfo->description];
}

- (NSString *)currentProcessorTasks:(NSString*)format
{
	struct processor_set_load_info loadInfo;
	unsigned int count = PROCESSOR_SET_LOAD_INFO_COUNT;
    kern_return_t kStatus;
    
	kStatus = processor_set_statistics(theProcessorSet, PROCESSOR_SET_LOAD_INFO, (processor_set_info_t)&loadInfo, &count);
	if (kStatus != KERN_SUCCESS) return @"No information available.";
    
    if ([format isEqualToString:@"loadAvg"]) return [NSString stringWithFormat:@"%i", loadInfo.load_average];
    else if ([format isEqualToString:@"machFactor"]) return [NSString stringWithFormat:@"%i", loadInfo.mach_factor];
    else if ([format isEqualToString:@"tasks"]) return [NSString stringWithFormat:@"%i", loadInfo.task_count];
    else if ([format isEqualToString:@"threads"]) return [NSString stringWithFormat:@"%i", loadInfo.thread_count];
    else if ([format isEqualToString:DEFAULT_FLAG_CURRENTTASKS]) return [NSString stringWithFormat:@"%i threads, %i tasks", loadInfo.thread_count, loadInfo.task_count];
    else return @"Invalid option or syntax";
}

- (NSString *)loadAverage
{
	double loads[3];
	NSString *loadAverage;
	
	// Fetch using getloadavg() to better match top, from Michael Nordmeyer (http://goodyworks.com)
	if (getloadavg(loads, 3) == -1) loadAverage = @"noinfo";
    
	return loadAverage;
}

- (NSString *)currentLoad:(BOOL)averageAllProcs args:(NSString*)format
{
    NSMutableArray *loadInfo;
    
	unsigned int processorCount;
	processor_cpu_load_info_t processorTickInfo;
	mach_msg_type_number_t processorMsgCount;
    
	// Loops
	unsigned int i, j;
	// Data per proc
	unsigned long system, user, nice, idle;
	unsigned long long total, totalnonice;
	// Data average for all procs
	unsigned long long systemall = 0;
	unsigned long long userall = 0;
	unsigned long long niceall = 0;
	unsigned long long idleall = 0;
	unsigned long long totalall = 0;
	unsigned long long totalallnonice = 0;
    
	// Read the current ticks
	kern_return_t kStatus = host_processor_info(theHost, PROCESSOR_CPU_LOAD_INFO, &processorCount, (processor_info_array_t *)&processorTickInfo, &processorMsgCount);
    
	if (kStatus != KERN_SUCCESS) return nil;
    
    if (averageAllProcs) loadInfo = [NSMutableArray arrayWithCapacity:1];
    else loadInfo = [NSMutableArray arrayWithCapacity:processorCount];
    
    // Loop the processors
    for (i = 0; i < processorCount; i++)
    {
        // Calc load types and totals, with guards against overflows
        if (processorTickInfo[i].cpu_ticks[CPU_STATE_SYSTEM] >= priorCPUTicks[i].cpu_ticks[CPU_STATE_SYSTEM])
            system = processorTickInfo[i].cpu_ticks[CPU_STATE_SYSTEM] - priorCPUTicks[i].cpu_ticks[CPU_STATE_SYSTEM];
        else
            system = processorTickInfo[i].cpu_ticks[CPU_STATE_SYSTEM] + (ULONG_MAX - priorCPUTicks[i].cpu_ticks[CPU_STATE_SYSTEM] + 1);
        
        if (processorTickInfo[i].cpu_ticks[CPU_STATE_USER] >= priorCPUTicks[i].cpu_ticks[CPU_STATE_USER])
            user = processorTickInfo[i].cpu_ticks[CPU_STATE_USER] - priorCPUTicks[i].cpu_ticks[CPU_STATE_USER];
        else
            user = processorTickInfo[i].cpu_ticks[CPU_STATE_USER] + (ULONG_MAX - priorCPUTicks[i].cpu_ticks[CPU_STATE_USER] + 1);
        
        if (processorTickInfo[i].cpu_ticks[CPU_STATE_NICE] >= priorCPUTicks[i].cpu_ticks[CPU_STATE_NICE])
            nice = processorTickInfo[i].cpu_ticks[CPU_STATE_NICE] - priorCPUTicks[i].cpu_ticks[CPU_STATE_NICE];
        else
            nice = processorTickInfo[i].cpu_ticks[CPU_STATE_NICE] + (ULONG_MAX - priorCPUTicks[i].cpu_ticks[CPU_STATE_NICE] + 1);
        
        if (processorTickInfo[i].cpu_ticks[CPU_STATE_IDLE] >= priorCPUTicks[i].cpu_ticks[CPU_STATE_IDLE])
            idle = processorTickInfo[i].cpu_ticks[CPU_STATE_IDLE] - priorCPUTicks[i].cpu_ticks[CPU_STATE_IDLE];
        else
            idle = processorTickInfo[i].cpu_ticks[CPU_STATE_IDLE] + (ULONG_MAX - priorCPUTicks[i].cpu_ticks[CPU_STATE_IDLE] + 1);
        
        total = system + user + nice + idle;
        totalnonice = system + user + idle;
        
        // Update avgs
        systemall += system;
        userall += user;
        niceall += nice;
        idleall += idle;
        totalall += total;
        totalallnonice += totalnonice;
        
        // Sanity
        if (total < 1) total = 1;
        if (totalnonice < 1) totalnonice = 1;
        
        // Store here only if we are going proc by proc
        if (!averageAllProcs)
        {
            [loadInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithDouble:((double)system / total)], @"system",
                                 [NSNumber numberWithDouble:((double)user / total)], @"user",
                                 [NSNumber numberWithDouble:((double)nice / total)], @"nice",
                                 [NSNumber numberWithDouble:((double)system / totalnonice)], @"systemwithoutnice",
                                 [NSNumber numberWithDouble:((double)user / totalnonice)], @"userwithoutnice",
                                 nil]];
        }
    }
    
    // Build a data block for averages only if thats what's required
    if (averageAllProcs)
    {
        // Sanity
        if (total < 1) total = 1;
        if (totalnonice < 1) totalnonice = 1;
        
        [loadInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithDouble:((double)systemall / totalall)], @"system",
                             [NSNumber numberWithDouble:((double)userall / totalall)], @"user",
                             [NSNumber numberWithDouble:((double)niceall / totalall)], @"nice",
                             [NSNumber numberWithDouble:((double)systemall / totalallnonice)], @"systemwithoutnice",
                             [NSNumber numberWithDouble:((double)userall / totalallnonice)], @"userwithoutnice",
                             nil]];
    }
    
    // Copy the new data into previous	
    for (i = 0; i < processorCount; i++)
        for (j = 0; j < CPU_STATE_MAX; j++) priorCPUTicks[i].cpu_ticks[j] = processorTickInfo[i].cpu_ticks[j];
    
    // Dealloc
    vm_deallocate(mach_task_self(), (vm_address_t)processorTickInfo, (vm_size_t)(processorMsgCount * sizeof(*processorTickInfo)));
    
    NSDictionary *topDict = [loadInfo objectAtIndex:0];
    
    if ([format isEqualToString:@"sys"]) return [NSString stringWithFormat:@"%.2f", [[topDict objectForKey:@"system"] doubleValue]];
    else if ([format isEqualToString:@"usr"]) return [NSString stringWithFormat:@"%.2f", [[topDict objectForKey:@"user"] doubleValue]];
    else if ([format isEqualToString:@"nice"]) return [NSString stringWithFormat:@"%.2f", [[topDict objectForKey:@"nice"] doubleValue]];
    else if ([format isEqualToString:@"sys!nice"]) return [NSString stringWithFormat:@"%.2f", [[topDict objectForKey:@"systemwithoutnice"] doubleValue]];
    else if ([format isEqualToString:@"usr!nice"]) return [NSString stringWithFormat:@"%.2f", [[topDict objectForKey:@"userwithoutnice"] doubleValue]];
    else if ([format isEqualToString:DEFAULT_FLAG_CURRENTLOAD]) return [NSString stringWithFormat:@"%.2f%% user, %.2f%% system", [[topDict objectForKey:@"user"] doubleValue], [[topDict objectForKey:@"system"] doubleValue]];
    else return @"Invalid option or syntax";
}

- (NSString *)getUptime:(NSString*)format
{
	time_t now, uptime;
	int mib[2];
	size_t length;
	struct timeval bootTime;
	long days, hours, minutes, seconds;
	
	(void)time(&now);
	
	length = sizeof(bootTime);
	mib[0] = CTL_KERN;
	mib[1] = KERN_BOOTTIME;
	sysctl(mib, 2, &bootTime, &length, NULL, 0);
	
	// Calculate the uptime
	uptime = now - bootTime.tv_sec;
	
	// Get our pretty string
	days = uptime / (24 * 60 * 60);
	uptime %= (24 * 60 * 60);
	hours = uptime / (60 * 60);
	uptime %= (60 * 60);
	minutes = uptime / 60;
	uptime %= 60;
	seconds = uptime;
    
    if ([format isEqualToString:@"day"]) return [NSString stringWithFormat:@"%i",days];
    else if ([format isEqualToString:@"hr"]) return [NSString stringWithFormat:@"%i", hours];
    else if ([format isEqualToString:@"min"]) return [NSString stringWithFormat:@"%i", minutes];
    else if ([format isEqualToString:@"sec"]) return [NSString stringWithFormat:@"%i", seconds];
    else if ([format isEqualToString:DEFAULT_FLAG_UPTIME]) return [NSString stringWithFormat:@"%i days, %i:%i", days, hours, minutes];
    else return @"Invalid option or syntax";
}

#pragma mark  
- (void)parseInputString:(NSString*)inputString
{
}

- (void)awakeFromNib
{
    //[self diskSpace:@""];
    //[self parseInputString:@"start\nthis is a test string\n#comment\na variable ${uptime} named for itself\nit actually costs $$42\nif uptime were money, it would be $$${uptime}\nuptime:${uptime d} days ${uptime h}:${uptime m}:${uptime s} end"];
    [self parseInputString:@"uptime:${uptime day} days ${uptime hr}:${uptime min}:${uptime sec}\n${uptime}\n${diskSpace :Macintosh HD: fsFreeSize}"];
    
}

#pragma mark Utility
- (NSString*)humanizeSize:(unsigned long long)size
{
    long double floatSize = size;
    NSString *units = @"B";
    
    if (floatSize > 1024)
    {
        floatSize /= 1024;
        units = @"KB";
    }
    
    if (floatSize > 1024)
    {
        floatSize /= 1024;
        units = @"MB";
    }
    
    if (floatSize > 1024)
    {
        floatSize /= 1024;
        units = @"GB";
    }
    
    return [NSString stringWithFormat:@"%.2Lf %@", floatSize, units];
}

- (NSString*)pullTextBetween:(NSString*)startMarker and:(NSString*)endMarker inString:(NSString*)formattedString rtnRange:(NSRange*)rtnRange
{
    NSRange zeroRange = NSMakeRange(NSNotFound, 0);
    *rtnRange = zeroRange;
    
    NSRange start;
    if ([startMarker isEqualToString:@""]) start = NSMakeRange(0, 0);
    else
    {
        NSRange startRange = NSMakeRange(0,[formattedString length]);
        start = [formattedString rangeOfString:startMarker options:NSLiteralSearch range:startRange];
        
        if (NSEqualRanges(start, zeroRange)) return nil;
    }
    
    // if we are out of range
    if (start.location + start.length >= [formattedString length]) return nil;
    
    NSRange end;
    if ([endMarker isEqualToString:@""]) end = NSMakeRange([formattedString length] - 1, 0);
    else
    {
        NSRange endRange = NSMakeRange(start.location + startMarker.length, [formattedString length] - start.location - start.length);
        end = [formattedString rangeOfString:endMarker options:NSLiteralSearch range:endRange];
        
        if (NSEqualRanges(end, zeroRange)) return nil;
    }
    NSRange variableRange = NSMakeRange(start.location + start.length, end.location - start.location - start.length);
    
    // contains the middle text AND start and end markers (for easy replacement)
    *rtnRange = NSMakeRange(start.location, end.location - start.location + end.length);
    // actual string returned is just the middle text: no markers
    return [formattedString substringWithRange:variableRange];
}

@end
