//
//  BOCAppDelegate.h
//  CoreBluetoothOSXCentral
//
//  Created by Michael Reneer on 4/8/13.
//  Copyright (c) 2013 Michael Reneer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>

#pragma mark - Interface

@interface BOCAppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, assign) IBOutlet NSWindow *window;

@end
