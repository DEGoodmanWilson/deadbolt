//
//  AppDelegate.m
//  yubibar
//
//  Created by D.E. Goodman-Wilson on 05/12/15.
//  Copyright (c) 2015 D.E. Goodman-Wilson. All rights reserved.
//

#import "AppDelegate.h"
#import "DBStatusItemView.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/usb/USBSpec.h>

@interface AppDelegate ()

@property (strong)              NSStatusItem         *statusBarItem;
@property (strong)              DBStatusItemView     *icon;
@property (strong)  IBOutlet    NSPopover           *window;
@property (strong)  IBOutlet    NSPopUpButton       *usbDevicePopUpButton;

@end

#define     matchVendorID           0x1050
#define     matchProductID          0x0114

extern void SACLockScreenImmediate ( );

void usbDeviceAppeared(void *refCon, io_iterator_t iterator){
    NSLog(@"Matching USB device appeared");
    while (IOIteratorNext(iterator)) {};
}
void usbDeviceDisappeared(void *refCon, io_iterator_t iterator){
    NSLog(@"Matching USB device disappeared");
    while (IOIteratorNext(iterator)) {};
    SACLockScreenImmediate();
}

@implementation AppDelegate

- (void)awakeFromNib
{
    //Add statusBarItem
    self.statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:-1];
    self.icon = [[DBStatusItemView alloc] initWithImage:[NSImage imageNamed:@"statusbaricon"] delegate:self.statusBarItem];
    self.statusBarItem.view = self.icon;
    
    //Suppress display of icon in dock.
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHighlightNotification:) name:@"setHighlight" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHighlightNotification:) name:@"unsetHighlight" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:NSApplicationWillResignActiveNotification object:nil];
}

- (void) handleHighlightNotification:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"setHighlight"])
    {
        [self populateUSBlist];
        [NSApp activateIgnoringOtherApps:YES];
        [self.window showRelativeToRect:self.icon.frame ofView:self.icon preferredEdge:NSMinYEdge];
    }
    else if([notification.name isEqualToString:@"unsetHighlight"])
    {
        [self.window performClose:self];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
//    NSLog(@"applicationWillResignActive");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"unsetHighlight" object:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // initial defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              @"USBVendorID": [NSNumber numberWithLong:0x0000],
                                                              @"USBProductID": [NSNumber numberWithLong:0x0000],
                                                              @"USBName": @"",
                                                              }];
    
    [self populateUSBlist];
    
    io_iterator_t newDevicesIterator;
    io_iterator_t lostDevicesIterator;
    
    newDevicesIterator = 0;
    lostDevicesIterator = 0;
    NSLog(@" ");
    
    NSMutableDictionary *matchingDict = (__bridge NSMutableDictionary *)IOServiceMatching(kIOUSBDeviceClassName);
    
    if (matchingDict == nil){
        NSLog(@"Could not create matching dictionary");
        return;
    }
    [matchingDict setObject:[NSNumber numberWithShort:matchVendorID] forKey:(NSString *)CFSTR(kUSBVendorID)];
    [matchingDict setObject:[NSNumber numberWithShort:matchProductID] forKey:(NSString *)CFSTR(kUSBProductID)];
    
    //  Add notification ports to runloop
    IONotificationPortRef notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
    CFRunLoopSourceRef notificationRunLoopSource = IONotificationPortGetRunLoopSource(notificationPort);
    CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], notificationRunLoopSource, kCFRunLoopDefaultMode);
    
    kern_return_t err;
    err = IOServiceAddMatchingNotification(notificationPort,
                                           kIOMatchedNotification,
                                           (__bridge CFDictionaryRef)matchingDict,
                                           usbDeviceAppeared,
                                           (__bridge void *)self,
                                           &newDevicesIterator);
    if (err)
    {
        NSLog(@"error adding publish notification");
    }
    [self matchingDevicesAdded: newDevicesIterator];
    
    
    NSMutableDictionary *matchingDictRemoved = (__bridge NSMutableDictionary *)IOServiceMatching(kIOUSBDeviceClassName);
    
    if (matchingDictRemoved == nil){
        NSLog(@"Could not create matching dictionary");
        return;
    }
    [matchingDictRemoved setObject:[NSNumber numberWithShort:matchVendorID] forKey:(NSString *)CFSTR(kUSBVendorID)];
    [matchingDictRemoved setObject:[NSNumber numberWithShort:matchProductID] forKey:(NSString *)CFSTR(kUSBProductID)];
    
    
    err = IOServiceAddMatchingNotification(notificationPort,
                                           kIOTerminatedNotification,
                                           (__bridge CFDictionaryRef)matchingDictRemoved,
                                           usbDeviceDisappeared,
                                           (__bridge void *)self,
                                           &lostDevicesIterator);
    if (err)
    {
        NSLog(@"error adding removed notification");
    }
    [self matchingDevicesRemoved: lostDevicesIterator];
    
    
    //      CFRunLoopRun();
    //      [[NSRunLoop currentRunLoop] run];
}

- (void)matchingDevicesAdded:(io_iterator_t)devices
{
    io_object_t thisObject;
    while ( (thisObject = IOIteratorNext(devices))) {
        NSLog(@"new Matching device added ");
        IOObjectRelease(thisObject);
    }
    
}


- (void)matchingDevicesRemoved:(io_iterator_t)devices
{
    io_object_t thisObject;
    while ( (thisObject = IOIteratorNext(devices))) {
        NSLog(@"A matching device was removed ");
        IOObjectRelease(thisObject);
    }
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - IBActions

- (void) populateUSBlist
{
    //todo
    NSMutableDictionary *
}

- (IBAction)usbPopUpButtonClicked:(id)sender {
    ;
}

- (IBAction)linkButtonClicked:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/DEGoodmanWilson/deadbolt"]];
}


@end
