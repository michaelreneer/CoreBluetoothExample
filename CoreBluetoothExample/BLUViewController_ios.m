//
//  BLUViewController_ios.m
//  CoreBluetoothExample
//
//  Created by Michael Reneer on 4/8/13.
//  Copyright © 2016 Michael Reneer. All rights reserved.
//

#import "BLUViewController_ios.h"
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const BLUIOSPeripheralNameKey = @"BLUIOSPeripheralName";
static NSString *const BLUServiceUUID = @"5B2EABB7-93CB-4C6A-94D4-C6CF2F331ED5";
static NSString *const BLUCharacteristicUUID = @"D589A9D6-C7EE-44FC-8F0E-46DD631EC940";

@interface BLUViewController () <CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *manager;
@property (nonatomic, strong, nullable) CBMutableService *service;
@property (nonatomic, strong, nullable) CBMutableCharacteristic *characteristic;

@end

@implementation BLUViewController {
	CBMutableCharacteristic *_characteristic;
	CBPeripheralManager *_manager;
	CBMutableService *_service;
}

#pragma mark - Lifecycle

static void BLUViewControllerInit(BLUViewController *self) {
	self->_manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];

	if (self != nil) {
		BLUViewControllerInit(self);
	}

	return self;
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

	if (self != nil) {
		BLUViewControllerInit(self);
	}

	return self;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];

	CBPeripheralManager *manager = [self manager];
	[manager stopAdvertising];
	[manager removeAllServices];

	[self setCharacteristic:nil];
	[self setService:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];

	UIDevice *device = [UIDevice currentDevice];
	[device beginGeneratingDeviceOrientationNotifications];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
	if ([[self manager] isAdvertising]) {
		[self updateValueForCharacteristic];
	}
}

#pragma mark - Peripheral

@synthesize manager = _manager;
@synthesize service = _service;
@synthesize characteristic = _characteristic;

- (void)addServiceToPeripheralManager {
	CBPeripheralManager *manager = [self manager];

	CBUUID *characteristicUUID = [CBUUID UUIDWithString:BLUCharacteristicUUID];
	CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsWriteable];
	[self setCharacteristic:characteristic];

	CBUUID *serviceUUID = [CBUUID UUIDWithString:BLUServiceUUID];
	CBMutableService *service = [self service];

	if (service != nil) {
		[manager removeService:service];
	}

	service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
	[service setCharacteristics:@[characteristic]];

	[manager addService:service];
}

- (void)updateValueForCharacteristic {
	CBMutableCharacteristic *characteristic = [self characteristic];

	if (characteristic != nil) {
		dispatch_block_t block = ^(void) {
			UIDevice *device = [UIDevice currentDevice];
			NSInteger orientation = [device orientation];
			NSData *value = [NSData dataWithBytes:&orientation length:sizeof(orientation)];
			[[self manager] updateValue:value forCharacteristic:characteristic onSubscribedCentrals:nil];
		};

		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(queue, block);
	}
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
	if ([self characteristic] == characteristic) {
		[self updateValueForCharacteristic];
	}
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(nullable NSError *)error {
	if (error == nil) {
		CBUUID *serviceUUID = [CBUUID UUIDWithString:BLUServiceUUID];
		NSDictionary *data = @{
			CBAdvertisementDataLocalNameKey: BLUIOSPeripheralNameKey,
			CBAdvertisementDataServiceUUIDsKey: @[serviceUUID],
		};

		[peripheral startAdvertising:data];
	} else {
		NSString *message = [error localizedDescription];
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil];
		[alertController addAction:dismissAction];

		[self showViewController:alertController sender:self];
	}
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
	if ([peripheral state] == CBPeripheralManagerStatePoweredOn) {
		[self addServiceToPeripheralManager];
	} else {
		NSString *message = NSLocalizedString(@"Peripheral manager did update state.", nil);
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil];
		[alertController addAction:dismissAction];

		[self showViewController:alertController sender:self];
	}
}

@end

NS_ASSUME_NONNULL_END
