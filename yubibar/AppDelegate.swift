//
//  AppDelegate.swift
//  yubibar
//
//  Created by D.E. Goodman-Wilson on 5/11/15.
//  Copyright (c) 2015 D.E. Goodman-Wilson. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, YBStatusItemViewDelegate {
    
    let statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var icon: YBStatusItemView?
    
    @IBOutlet weak var mainWindow: NSWindow?
    
    override func awakeFromNib() {
        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1) //NSVariableStatusItemLength
        self.icon = YBStatusItemView(image: NSImage(named:"statusbaricon")!, item: statusBarItem, delegate: self);
        statusBarItem.view = self.icon;
        
        //Suppress display of icon in dock.
        NSApp.setActivationPolicy(NSApplicationActivationPolicy.Accessory)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func onItemClicked(active: Bool) {
        if(active == true)
        {
            let iconFrame = self.statusBarItem.view!.window!.frame
            let windowFrame = self.mainWindow!.frame
            let windowFrameSize = windowFrame.size
            
            var origin = NSMakePoint(NSMidX(iconFrame), NSMinY(iconFrame))
            
            origin.x -= windowFrameSize.width / 2
            origin.y -= windowFrameSize.height + 3
            
            mainWindow?.setFrameOrigin(origin)
            
            mainWindow?.makeKeyAndOrderFront(self)
            NSApp.activateIgnoringOtherApps(true)
        }
        else
        {
            mainWindow?.orderOut(self)
        }
    }
}