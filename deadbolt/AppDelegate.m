//
//  AppDelegate.m
//  yubibar
//
//  Created by D.E. Goodman-Wilson on 05/12/15.
//  Copyright (c) 2015 D.E. Goodman-Wilson. All rights reserved.
//

#import "AppDelegate.h"
#import "DBStatusItemView.h"

@interface AppDelegate ()

@property (strong) NSStatusItem         *statusBarItem;
@property (strong) DBStatusItemView     *icon;
@property (strong) IBOutlet NSPopover            *window;

@end

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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"unsetHighlight" object:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
