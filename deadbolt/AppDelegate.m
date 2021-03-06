//
//  AppDelegate.m
//  yubibar
//
//  Created by D.E. Goodman-Wilson on 05/12/15.
//  Copyright (c) 2015 D.E. Goodman-Wilson. All rights reserved.
//

#import "AppDelegate.h"
#import "DBStatusItemView.h"
#import <MASShortcut/MASShortcut.h>
#import <MASShortcut/MASShortcutBinder.h>
#import <MASShortcut/MASShortcutView.h>
#import <MASShortcut/MASShortcutView+Bindings.h>
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
@property (assign)              io_iterator_t       deviceIterator;
@property (strong)  IBOutlet    MASShortcutView     *shortcutView;
@property (strong)  IBOutlet    NSButton            *lockDisplayButton;
@property (strong)  IBOutlet    NSButton            *screensaverButton;
@end

extern void SACLockScreenImmediate ( );

void usbDeviceDisappeared(void *refCon, io_iterator_t iterator){
    NSLog(@"Matching USB device disappeared");
    while (IOIteratorNext(iterator)) {};
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"UseScreenSaver"])
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:@"/System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app"]];
    }
    else
    {
        SACLockScreenImmediate();
    }
}

@implementation AppDelegate

- (void)awakeFromNib
{
    //Add statusBarItem
    self.statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:-1];
    self.icon = [[DBStatusItemView alloc] initWithLightImage:[NSImage imageNamed:@"statusbaricon"] darkImage:[NSImage imageNamed:@"statusbaricon-white"] delegate:self.statusBarItem];
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
    
    // Add the app to the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef != nil)
    {
        CFURLRef appUrl = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
        if (itemRef) CFRelease(itemRef);
    }
    
    //user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              @kUSBVendorID: [NSNumber numberWithLong:0x0000],
                                                              @kUSBProductID: [NSNumber numberWithLong:0x0000],
                                                              @"USBName": @"",
                                                              @"UseScreenSaver": [NSNumber numberWithBool:FALSE],
                                                              }];
    //global shotcut goodies
    [self.shortcutView setAssociatedUserDefaultsKey:@"HotKey"];
    
    //lock: ctrl+alt+cmd+l
    NSEventModifierFlags lockKeyMask = NSAlternateKeyMask | NSControlKeyMask | NSCommandKeyMask;
    MASShortcut *defaultLockShortcut = [[MASShortcut alloc] initWithKeyCode:kVK_ANSI_L modifierFlags:lockKeyMask];
    [[MASShortcutBinder sharedBinder] registerDefaultShortcuts:@{@"HotKey": defaultLockShortcut}];

    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:@"HotKey" toAction:^{
        SACLockScreenImmediate();
    }];
    
    [self populateUSBlist];
    [self watchUSBDevice];
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

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Quit deadbolt?"];
    [alert setInformativeText:[NSString stringWithFormat:@"If you quit, removing %@ will no longer lock your Mac.", [[NSUserDefaults standardUserDefaults] stringForKey:@"USBName"]]];
    [alert setAlertStyle:NSWarningAlertStyle];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        return NSTerminateNow;
    }
    return NSTerminateCancel;
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
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"UseScreenSaver"])
    {
        [self.lockDisplayButton setState:NSOffState];
        [self.screensaverButton setState:NSOnState];
    }
    else
    {
        [self.lockDisplayButton setState:NSOnState];
        [self.screensaverButton setState:NSOffState];
    }
}

- (void)watchUSBDevice
{
    IOObjectRelease(self.deviceIterator); //remove all previous notifications
    
    if([[[NSUserDefaults standardUserDefaults] stringForKey:@"USBName"] isEqualToString:@""])
    {
        return;
    }

    io_iterator_t lostDevicesIterator;
    
    NSMutableDictionary *matchingDict = (__bridge NSMutableDictionary *)IOServiceMatching(kIOUSBDeviceClassName);
    
    if (matchingDict == nil){
        NSLog(@"Could not create matching dictionary");
        return;
    }
    [matchingDict setObject:[NSNumber numberWithInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@kUSBVendorID]] forKey:(NSString *)CFSTR(kUSBVendorID)];
     
    [matchingDict setObject:[NSNumber numberWithShort:[[NSUserDefaults standardUserDefaults] integerForKey:@kUSBProductID]] forKey:(NSString *)CFSTR(kUSBProductID)];
    
    //  Add notification ports to runloop
    IONotificationPortRef notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
    CFRunLoopSourceRef notificationRunLoopSource = IONotificationPortGetRunLoopSource(notificationPort);
    CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], notificationRunLoopSource, kCFRunLoopDefaultMode);
    
    kern_return_t err;
    err = IOServiceAddMatchingNotification(notificationPort,
                                           kIOTerminatedNotification,
                                           (__bridge CFDictionaryRef)matchingDict,
                                           usbDeviceDisappeared,
                                           (__bridge void *)self,
                                           &lostDevicesIterator);
    if (err)
    {
        NSLog(@"error adding removal notification");
    }

    self.deviceIterator = lostDevicesIterator;
    
    [self matchingDevicesRemoved: lostDevicesIterator];
}

#pragma mark - IBActions

- (IBAction)lockTypeChanged:(id)sender {
    NSButton *button = sender;
    if(button == self.lockDisplayButton) {
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"UseScreenSaver"];
    }
    else if(button == self.screensaverButton) {
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"UseScreenSaver"];
    }
}

- (IBAction)usbPopUpButtonClicked:(id)sender {
    //get the selected item and
    //  a) watch for it
    //  b) store in defaults
    NSDictionary *device = self.usbDevices[self.usbDevicePopUpButton.selectedItem.title];
    [[NSUserDefaults standardUserDefaults] setObject:self.usbDevicePopUpButton.selectedItem.title forKey:@"USBName"];
    [[NSUserDefaults standardUserDefaults] setObject:device[@kUSBVendorID] forKey:@kUSBVendorID];
    [[NSUserDefaults standardUserDefaults] setObject:device[@kUSBProductID] forKey:@kUSBProductID];
    
    [self watchUSBDevice];
}

- (IBAction)linkButtonClicked:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/DEGoodmanWilson/deadbolt"]];
}


@end
