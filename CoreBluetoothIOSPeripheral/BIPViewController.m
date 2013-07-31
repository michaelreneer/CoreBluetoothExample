//
//  BIPViewController.m
//  CoreBluetoothIOSPeripheral
//
//  Created by Michael Reneer on 4/8/13.
//  Copyright (c) 2013 Michael Reneer. All rights reserved.
//

#import "BIPViewController.h"

#pragma mark - Interface

@interface BIPViewController ()

@property (nonatomic, strong) CBMutableCharacteristic *characteristic;
@property (nonatomic, strong) CBPeripheralManager *manager;
@property (nonatomic, strong) CBMutableService *service;

@property (nonatomic, weak) IBOutlet UISwitch *control;

@end

#pragma mark - Implementation

@implementation BIPViewController

#pragma mark - Constants

static NSString *const kServiceUUID = @"5B2EABB7-93CB-4C6A-94D4-C6CF2F331ED5";
static NSString *const kCharacteristicUUID = @"D589A9D6-C7EE-44FC-8F0E-46DD631EC940";

#pragma mark - Overriden Methods

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (![self isViewLoaded]) {
        [self.manager stopAdvertising];
        [self.manager removeAllServices];
        
        self.characteristic = nil;
        self.manager = nil;
        self.service = nil;
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    UIDevice *device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
}

#pragma mark - Instance Methods

- (void)addServiceToPeripheralManager {
    
    if (self.service != nil) {
        [self.manager removeService:self.service];
    }
    
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
    self.characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsWriteable];
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    self.service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    self.service.characteristics = @[self.characteristic];
    
    [self.manager addService:self.service];
}

- (void)commonInit {
    _manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    
    if (self.manager.isAdvertising) {
        [self updateValueForCharacteristic];
    }
}

- (void)updateValueForCharacteristic {
    
    if (self.characteristic != nil) {
        dispatch_block_t block = ^(void) {
            UIDevice *device = [UIDevice currentDevice];
            NSInteger orientation = device.orientation;
            NSData *value = [NSData dataWithBytes:&orientation length:sizeof(orientation)];
            [self.manager updateValue:value forCharacteristic:self.characteristic onSubscribedCentrals:nil];
        };
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, block);
    }
}

#pragma mark - Action Methods

- (IBAction)controlValueChanged:(id)sender {
    UISwitch *control = (UISwitch *)sender;
    
    if (control.on) {
        [self addServiceToPeripheralManager];
    }
    else {
        [self.manager stopAdvertising];
        [self.manager removeAllServices];
    }
}

#pragma mark - Protocol Methods - CBPeripheralManagerDelegate

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    
    if (self.characteristic == characteristic) {
        [self updateValueForCharacteristic];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    
    if (error != nil) {
        NSLog(@"Error adding setvice: %@", error.localizedDescription);
        
        return;
    }
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    NSDictionary *data = @{
                           CBAdvertisementDataLocalNameKey: @"BIPCoreBluetoothIOSPeripheral",
                           CBAdvertisementDataServiceUUIDsKey: @[serviceUUID],
                           };
    
    [peripheral startAdvertising:data];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        [self addServiceToPeripheralManager];
    }
    else if (peripheral.state == CBCentralManagerStatePoweredOff) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Bluetooth is currently powered off." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else if (peripheral.state == CBCentralManagerStateUnauthorized) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"The app is not authorized to use Bluetooth Low Energy." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else if (peripheral.state == CBCentralManagerStateUnsupported) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"The platform/hardware doesn't support Bluetooth Low Energy." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

@end
