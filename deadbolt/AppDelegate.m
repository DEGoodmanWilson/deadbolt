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
@property (strong)              NSDictionary        *usbDevices;

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
                                                              @kUSBVendorID: [NSNumber numberWithLong:0x0000],
                                                              @kUSBProductID: [NSNumber numberWithLong:0x0000],
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

#pragma mark - USB goodies

- (NSDictionary *) getListOfSystemDevices
{
    //first, get the list of USB devices from the system
    CFMutableDictionaryRef matchingDict;
    io_iterator_t iter;
    kern_return_t kr;
    io_service_t device;
    
    /* set up a matching dictionary for the class */
    matchingDict = IOServiceMatching(kIOUSBDeviceClassName);    // Interested in instances of class
    // IOUSBDevice and its subclasses
    if (matchingDict == NULL) {
        return @{};
    }
    
    // We are interested in all USB devices (as opposed to USB interfaces).  The Common Class Specification
    // tells us that we need to specify the idVendor, idProduct, and bcdDevice fields, or, if we're not interested
    // in particular bcdDevices, just the idVendor and idProduct.  Note that if we were trying to match an
    // IOUSBInterface, we would need to set more values in the matching dictionary (e.g. idVendor, idProduct,
    // bInterfaceNumber and bConfigurationValue.
    
    //search for all vendors
    CFDictionarySetValue(matchingDict, CFSTR(kUSBVendorID), CFSTR("*"));
    CFDictionarySetValue(matchingDict, CFSTR (kUSBProductID), CFSTR("*"));
    
    /* Now we have a dictionary, get an iterator.*/
    kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iter);
    if (kr != KERN_SUCCESS)
    {
        return @{};
    }
    
    /* iterate */
    NSMutableDictionary *devices = [NSMutableDictionary new];
    while ((device = IOIteratorNext(iter)))
    {
        io_name_t       deviceName;
        
        //make sure this isn't a hub
        CFTypeRef bDeviceClass = IORegistryEntryCreateCFProperty(device, CFSTR(kUSBDeviceClass), kCFAllocatorDefault, 0);
        uint32_t devClass;
        CFNumberGetValue(bDeviceClass, kCFNumberIntType, &devClass);
        if(devClass == kUSBHubClass)
        {
            continue;
        }
        
        /* do something with device, eg. check properties */
        /* ... */
        /* And free the reference taken before continuing to the next item */
        
        // Get the USB device's name.
        kr = IORegistryEntryGetName(device, deviceName);
        if (KERN_SUCCESS != kr) {
            deviceName[0] = '\0';
        }
        
        CFTypeRef deviceVendorID;
        deviceVendorID = IORegistryEntryCreateCFProperty(device, CFSTR(kUSBVendorID), kCFAllocatorDefault, 0);
        CFTypeRef deviceProductID;
        deviceProductID = IORegistryEntryCreateCFProperty(device, CFSTR(kUSBProductID), kCFAllocatorDefault, 0);
        
        uint32_t vendorId, productId;
        CFNumberGetValue(deviceVendorID, kCFNumberIntType, &vendorId);
        CFNumberGetValue(deviceProductID, kCFNumberIntType, &productId);
        
        devices[[NSString stringWithUTF8String:deviceName ]] = @{
                            @kUSBVendorID: [NSNumber numberWithLong:vendorId],
                            @kUSBProductID: [NSNumber numberWithLong:productId],
                            };
        
        IOObjectRelease(device);
        CFRelease(deviceVendorID);
        CFRelease(deviceProductID);
    }
    
    /* Done, release the iterator */
    IOObjectRelease(iter);
    
    return devices;
}

- (void) populateUSBlist
{
    NSMutableDictionary *deviceDict = [NSMutableDictionary dictionaryWithDictionary:[self getListOfSystemDevices]];
    //now see if we should insert our stored device in list
    NSString *defaultDeviceName = [[NSUserDefaults standardUserDefaults] stringForKey:@"USBName"];
    
    if( (![defaultDeviceName isEqualToString:@""]) && (deviceDict[defaultDeviceName] == nil) )
    {
        //we have a default value stored. Add it to the list only if it doesn't exist
        deviceDict[defaultDeviceName] = @{
               @kUSBVendorID: [NSNumber numberWithLong:[[NSUserDefaults standardUserDefaults] integerForKey:@kUSBVendorID]],
                @kUSBProductID: [NSNumber numberWithLong:[[NSUserDefaults standardUserDefaults] integerForKey:@kUSBProductID]],
             };
    }
    
    self.usbDevices = [NSDictionary dictionaryWithDictionary:deviceDict];
    
    //now, get this into the popup
    [self.usbDevicePopUpButton removeAllItems];
    for (NSString *key in [self.usbDevices allKeys])
    {
        if([defaultDeviceName isEqualToString:key])
        {
            [self.usbDevicePopUpButton insertItemWithTitle:key atIndex:0];
            [self.usbDevicePopUpButton selectItemAtIndex:0];
        }
        else
        {
            [self.usbDevicePopUpButton addItemWithTitle:key];
        }
    }
}

#pragma mark - IBActions

- (IBAction)usbPopUpButtonClicked:(id)sender {
    //get the selected item and
    //  a) watch for it
    //  b) store in defaults
    NSDictionary *device = self.usbDevices[self.usbDevicePopUpButton.selectedItem.title];
    [[NSUserDefaults standardUserDefaults] setObject:self.usbDevicePopUpButton.selectedItem.title forKey:@"USBName"];
    [[NSUserDefaults standardUserDefaults] setObject:device[@kUSBVendorID] forKey:@kUSBVendorID];
    [[NSUserDefaults standardUserDefaults] setObject:device[@kUSBProductID] forKey:@kUSBProductID];
}

- (IBAction)linkButtonClicked:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/DEGoodmanWilson/deadbolt"]];
}


@end
