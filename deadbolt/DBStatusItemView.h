//
//  YBStatusItemView.h
//  yubibar
//
//  Created by D.E. Goodman-Wilson on 05/12/15.
//  Copyright (c) 2015 D.E. Goodman-Wilson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DBStatusItemView : NSView

- (id) initWithLightImage:(NSImage *)lightImage darkImage:(NSImage *)darkImage delegate:(NSStatusItem *)delegate;

@end
