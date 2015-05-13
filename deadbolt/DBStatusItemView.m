//
//  DBStatusItemView.m
//  yubibar
//
//  Created by D.E. Goodman-Wilson on 05/12/15.
//  Copyright (c) 2015 D.E. Goodman-Wilson. All rights reserved.
//

#import "DBStatusItemView.h"

@interface DBStatusItemView ()

@property   (strong)            NSImage         *lightImage;
@property   (strong)            NSImage         *darkImage;
@property   (weak)              NSStatusItem    *delegate;
@property   (nonatomic, assign) BOOL            isSelected;
@end

@implementation DBStatusItemView

- (id) initWithLightImage:(NSImage *)lightImage darkImage:(NSImage *)darkImage delegate:(NSStatusItem *)delegate
{
    if(self = [super  init])
    {
        self.lightImage = lightImage;
        self.darkImage = darkImage;
        self.delegate = delegate;
        self.isSelected = false;
        
        CGFloat thickness = [NSStatusBar systemStatusBar].thickness;
        NSRect rect = NSMakeRect(0.0, 0.0, self.lightImage.size.width+4, thickness);
        
        self.frame = rect;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHighlightNotification:) name:@"setHighlight" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHighlightNotification:) name:@"unsetHighlight" object:nil];

    }
    
    return self;
}

- (BOOL)isYosemiteDarkTheme
{
    return [[[NSAppearance currentAppearance] name] isEqualTo:@"NSAppearanceNameVibrantDark"];
}

- (void) drawRect:(NSRect)dirtyRect
{
    [self.delegate drawStatusBarBackgroundInRect:dirtyRect withHighlight:self.isSelected];
    
    NSImage *image = self.lightImage;
    
    if([self isYosemiteDarkTheme]) image = self.darkImage;
    
    NSRect rect = NSMakeRect(2.0, 2.0, image.size.width, image.size.height);
    [image drawInRect:rect];
}

- (void) handleHighlightNotification:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"setHighlight"])
    {
//        NSLog(@"setHighlight");
        self.isSelected = YES;
    }
    else if([notification.name isEqualToString:@"unsetHighlight"])
    {
//        NSLog(@"unsetHighlight");
        self.isSelected = NO;
    }
    
    self.needsDisplay = YES;
}

- (void) mouseDown:(NSEvent *)theEvent
{
//    NSLog(@"mouseDown");
    if(self.isSelected)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"unsetHighlight" object:self];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setHighlight" object:self];
    }
}

@end
