//
//  BOCAppDelegate.m
//  CoreBluetoothOSXCentral
//
//  Created by Michael Reneer on 4/8/13.
//  Copyright (c) 2013 Michael Reneer. All rights reserved.
//

#import "BOCAppDelegate.h"

#pragma mark - Interface

@interface BOCAppDelegate ()

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, weak) IBOutlet NSTextField *deviceTextField;
@property (nonatomic, weak) IBOutlet NSTextField *orientationTextField;

@end

#pragma mark - Implementation

@implementation BOCAppDelegate

#pragma mark - Constants

static NSString *const kServiceUUID = @"5B2EABB7-93CB-4C6A-94D4-C6CF2F331ED5";
static NSString *const kCharacteristicUUID = @"D589A9D6-C7EE-44FC-8F0E-46DD631EC940";

#pragma mark - Instance Methods

- (void)startScan {
    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: @YES};
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    [self.manager scanForPeripheralsWithServices:@[serviceUUID] options:options];
}

- (void)stopScan {
    [self.manager stopScan];
}

#pragma mark - Protocol Methods - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    peripheral.delegate = self;
    [peripheral discoverServices:@[serviceUUID]];
    
    NSString *value = [[NSString alloc] initWithFormat:@"%@", peripheral.name];
    [self.deviceTextField setStringValue:value];
    [self.orientationTextField setStringValue:@""];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if (self.peripheral == peripheral) {
        self.peripheral = nil;
    }
    
    [self startScan];
    
    [self.deviceTextField setStringValue:@"..."];
    [self.orientationTextField setStringValue:@""];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if (self.peripheral != peripheral) {
        self.peripheral = peripheral;
    }
    
    [self stopScan];
    
    [central connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if (self.peripheral == peripheral) {
        self.peripheral = nil;
    }
    
    [self startScan];
    
    [self.deviceTextField setStringValue:@"..."];
    [self.orientationTextField setStringValue:@""];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self startScan];
        
        [self.deviceTextField setStringValue:@"..."];
        [self.orientationTextField setStringValue:@""];
    }
    else if (central.state == CBCentralManagerStatePoweredOff) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Bluetooth is currently powered off." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:nil];
        [alert runModal];
    }
    else if (central.state == CBCentralManagerStateUnauthorized) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"The app is not authorized to use Bluetooth Low Energy." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:nil];
        [alert runModal];
    }
    else if (central.state == CBCentralManagerStateUnsupported) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"The platform/hardware doesn't support Bluetooth Low Energy." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:nil];
        [alert runModal];
    }
}

#pragma mark - Protocol Methods - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if (error != nil) {
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        
        return;
    }
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    
    if ([service.UUID isEqual:serviceUUID]) {
        CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
        
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if ([characteristic.UUID isEqual:characteristicUUID]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if (error != nil) {
        NSLog(@"Error discovering service: %@", [error localizedDescription]);
        
        return;
    }
    
    for (CBService *service in peripheral.services) {
        CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
        
        if ([service.UUID isEqual:serviceUUID]) {
            CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
            [peripheral discoverCharacteristics:@[characteristicUUID] forService:service];
        }
        
        if ([service.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (error != nil) {
        NSLog(@"Error updating value: %@", error.localizedDescription);
        
        return;
    }
    
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
    
    if ([characteristic.UUID isEqual:characteristicUUID]) {
        NSInteger orientation = 0;
        [characteristic.value getBytes:&orientation length:sizeof(orientation)];
        
        if (orientation == 1) {
            [self.orientationTextField setStringValue:@"Portrait"];
        }
        else if (orientation == 2) {
            [self.orientationTextField setStringValue:@"Portrait Upside Down"];
        }
        else if (orientation == 3) {
            [self.orientationTextField setStringValue:@"Landscape Left"];
        }
        else if (orientation == 4) {
            [self.orientationTextField setStringValue:@"Landscape Right"];
        }
        else if (orientation == 5) {
            [self.orientationTextField setStringValue:@"Face Up"];
        }
        else if (orientation == 6) {
            [self.orientationTextField setStringValue:@"Face Down"];
        }
        else {
            [self.orientationTextField setStringValue:@"Unknown"];
        }
    }
}

#pragma mark - Protocol Methods - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    
    if (self.peripheral != nil) {
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
}

@end
