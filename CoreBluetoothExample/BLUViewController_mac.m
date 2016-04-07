//
//  BLUViewController_mac.m
//  CoreBluetoothExample
//
//  Created by Michael Reneer on 4/8/13.
//  Copyright © 2016 Michael Reneer. All rights reserved.
//

#import "BLUViewController_mac.h"
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const BLUServiceUUID = @"5B2EABB7-93CB-4C6A-94D4-C6CF2F331ED5";
static NSString *const BLUCharacteristicUUID = @"D589A9D6-C7EE-44FC-8F0E-46DD631EC940";

@interface BLUViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong, nullable) CBPeripheral *peripheral;

@property (nonatomic, weak) IBOutlet NSTextField *deviceTextField;
@property (nonatomic, weak) IBOutlet NSTextField *orientationTextField;

@end

@interface BLUViewController ()
@end

@implementation BLUViewController {
	NSMutableData *_data;
	CBCentralManager *_manager;
	CBPeripheral *_peripheral;

	__weak NSTextField *_deviceTextField;
	__weak NSTextField *_orientationTextField;
}

@synthesize data = _data;
@synthesize manager = _manager;
@synthesize peripheral = _peripheral;

@synthesize deviceTextField = _deviceTextField;
@synthesize orientationTextField = _orientationTextField;

#pragma mark - Lifecycle

static void BLUViewControllerInit(BLUViewController *self) {
	self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];

	if (self != nil) {
		BLUViewControllerInit(self);
	}

	return self;
}

- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

	if (self != nil) {
		BLUViewControllerInit(self);
	}

	return self;
}

- (void)didReceiveMemoryWarning {
	if ([self peripheral] != nil) {
		[[self manager] cancelPeripheralConnection:(CBPeripheral * _Nonnull)[self peripheral]];
	}
}

#pragma mark - Central

- (void)startScan {
	NSDictionary *options = @{ CBCentralManagerScanOptionAllowDuplicatesKey: @YES };
	CBUUID *serviceUUID = [CBUUID UUIDWithString:BLUServiceUUID];
	[self.manager scanForPeripheralsWithServices:@[serviceUUID] options:options];
}

- (void)stopScan {
	[self.manager stopScan];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
	CBUUID *serviceUUID = [CBUUID UUIDWithString:BLUServiceUUID];
	peripheral.delegate = self;
	[peripheral discoverServices:@[serviceUUID]];

	if (peripheral.name != nil) {
		[self.deviceTextField setStringValue:(NSString * _Nonnull)peripheral.name];
	}

	[self.orientationTextField setStringValue:@""];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
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

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
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
	} else if (central.state == CBCentralManagerStatePoweredOff) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLocalizedString(@"Bluetooth is currently powered off.", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
		[alert runModal];
	} else if (central.state == CBCentralManagerStateUnauthorized) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLocalizedString(@"The app is not authorized to use Bluetooth Low Energy.", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
		[alert runModal];
	} else if (central.state == CBCentralManagerStateUnsupported) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLocalizedString(@"The platform/hardware doesn't support Bluetooth Low Energy.", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
		[alert runModal];
	}
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
	if (error != nil) {
		NSAlert *alert = [NSAlert alertWithError:(NSError * _Nonnull)error];
		[alert runModal];

		return;
	}

	CBUUID *serviceUUID = [CBUUID UUIDWithString:BLUServiceUUID];

	if ([service.UUID isEqual:serviceUUID]) {
		CBUUID *characteristicUUID = [CBUUID UUIDWithString:BLUCharacteristicUUID];

		for (CBCharacteristic *characteristic in service.characteristics) {
			if ([characteristic.UUID isEqual:characteristicUUID]) {
				[peripheral setNotifyValue:YES forCharacteristic:characteristic];
			}
		}
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
	if (error != nil) {
		NSAlert *alert = [NSAlert alertWithError:(NSError * _Nonnull)error];
		[alert runModal];

		return;
	}

	for (CBService *service in peripheral.services) {
		CBUUID *serviceUUID = [CBUUID UUIDWithString:BLUServiceUUID];

		if ([service.UUID isEqual:serviceUUID]) {
			CBUUID *characteristicUUID = [CBUUID UUIDWithString:BLUCharacteristicUUID];
			[peripheral discoverCharacteristics:@[characteristicUUID] forService:service];
		}

		if ([service.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]]) {
			[peripheral discoverCharacteristics:nil forService:service];
		}
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
	if (error != nil) {
		NSAlert *alert = [NSAlert alertWithError:(NSError * _Nonnull)error];
		[alert runModal];

		return;
	}

	CBUUID *characteristicUUID = [CBUUID UUIDWithString:BLUCharacteristicUUID];

	if ([characteristic.UUID isEqual:characteristicUUID]) {
		NSInteger orientation = 0;
		[characteristic.value getBytes:&orientation length:sizeof(orientation)];

		if (orientation == 1) {
			[self.orientationTextField setStringValue:NSLocalizedString(@"Portrait", nil)];
		} else if (orientation == 2) {
			[self.orientationTextField setStringValue:NSLocalizedString(@"Portrait Upside Down", nil)];
		} else if (orientation == 3) {
			[self.orientationTextField setStringValue:NSLocalizedString(@"Landscape Left", nil)];
		} else if (orientation == 4) {
			[self.orientationTextField setStringValue:NSLocalizedString(@"Landscape Right", nil)];
		} else if (orientation == 5) {
			[self.orientationTextField setStringValue:NSLocalizedString(@"Face Up", nil)];
		} else if (orientation == 6) {
			[self.orientationTextField setStringValue:NSLocalizedString(@"Face Down", nil)];
		} else {
			[self.orientationTextField setStringValue:NSLocalizedString(@"Unknown", nil)];
		}
	}
}

@end

NS_ASSUME_NONNULL_END
