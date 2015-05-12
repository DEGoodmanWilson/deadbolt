//
//  YBStatusItemView.m
//  yubibar
//
//  Created by D.E. Goodman-Wilson on 05/12/15.
//  Copyright (c) 2015 D.E. Goodman-Wilson. All rights reserved.
//

#import "YBStatusItemView.h"

@interface YBStatusItemView ()

@property   (strong)            NSImage         *image;
@property   (weak)              NSStatusItem    *delegate;
@property   (nonatomic, assign) BOOL            isSelected;
@end

@implementation YBStatusItemView

- (id) initWithImage:(NSImage *)image delegate:(NSStatusItem *)delegate
{
    if(self = [super  init])
    {
        self.image = image;
        self.delegate = delegate;
        self.isSelected = false;
        
        CGFloat thickness = [NSStatusBar systemStatusBar].thickness;
        NSRect rect = NSMakeRect(0.0, 0.0, self.image.size.width+4, thickness);
        
        self.frame = rect;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHighlightNotification:) name:@"setHighlight" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHighlightNotification:) name:@"unsetHighlight" object:nil];

    }
    
    return self;
}

- (void) drawRect:(NSRect)dirtyRect
{
    [self.delegate drawStatusBarBackgroundInRect:dirtyRect withHighlight:self.isSelected];
    NSRect rect = NSMakeRect(2.0, 2.0, self.image.size.width, self.image.size.height);
    [self.image drawInRect:rect];
}

- (void) handleHighlightNotification:(NSNotification *)notification
{
    if([notification.name isEqualToString:@"setHighlight"])
    {
        self.isSelected = YES;
    }
    else if([notification.name isEqualToString:@"unsetHighlight"])
    {
        self.isSelected = NO;
    }
    
    self.needsDisplay = YES;
}

- (void) mouseDown:(NSEvent *)theEvent
{
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
