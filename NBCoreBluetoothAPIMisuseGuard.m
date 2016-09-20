//
//  NBCoreBluetoothAPIMisuseGuard.m
//  LifeStyleLock
//
//  Created by Nick Brook on 03/05/2016.
//  Copyright © 2016 LifeStyleLock. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <objc/runtime.h>
#import <objc/message.h>

#if DEBUG

void swizzleInstance(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@implementation CBCentralManager (APIMisuseGuard)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        swizzleInstance(class, @selector(connectPeripheral:options:), @selector(nb_connectPeripheral:options:));
        swizzleInstance(class, @selector(retrieveConnectedPeripheralsWithServices:), @selector(nb_retrieveConnectedPeripheralsWithServices:));
        swizzleInstance(class, @selector(cancelPeripheralConnection:), @selector(nb_cancelPeripheralConnection:));
        swizzleInstance(class, @selector(scanForPeripheralsWithServices:options:), @selector(nb_scanForPeripheralsWithServices:options:));
        swizzleInstance(class, @selector(stopScan), @selector(nb_stopScan));
    });
}

- (void)nb_stateCheck {
    if(self.state != CBCentralManagerStatePoweredOn) {
        NSString *stack = [[NSThread callStackSymbols] componentsJoinedByString:@"\n"];
        NSAssert(NO, @"CBCentralManager was not in powered on state when a method was called. State was %ld\n\nStacktrace:\n%@", (long)self.state, stack);
    }
}

#pragma mark - Method Swizzling

- (void)nb_connectPeripheral:(CBPeripheral *)peripheral options:(NSDictionary<NSString *,id> *)options {
    [self nb_stateCheck];
    [self nb_connectPeripheral:peripheral options:options];
}

- (NSArray<CBPeripheral *> *)nb_retrieveConnectedPeripheralsWithServices:(NSArray<CBUUID *> *)serviceUUIDs {
    [self nb_stateCheck];
    return [self nb_retrieveConnectedPeripheralsWithServices:serviceUUIDs];
}

- (void)nb_cancelPeripheralConnection:(CBPeripheral *)peripheral {
    [self nb_stateCheck];
    [self nb_cancelPeripheralConnection:peripheral];
}

- (void)nb_scanForPeripheralsWithServices:(NSArray<CBUUID *> *)serviceUUIDs options:(NSDictionary<NSString *,id> *)options {
    [self nb_stateCheck];
    [self nb_scanForPeripheralsWithServices:serviceUUIDs options:options];
}

- (void)nb_stopScan {
    [self nb_stateCheck];
    [self nb_stopScan];
}

@end

@implementation CBPeripheralManager (APIMisuseGuard)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        swizzleInstance(class, @selector(addService:), @selector(nb_addService:));
        swizzleInstance(class, @selector(removeService:), @selector(nb_removeService:));
        swizzleInstance(class, @selector(removeAllServices), @selector(nb_removeAllServices));
        swizzleInstance(class, @selector(startAdvertising:), @selector(nb_startAdvertising:));
        swizzleInstance(class, @selector(stopAdvertising), @selector(nb_stopAdvertising));
        swizzleInstance(class, @selector(updateValue:forCharacteristic:onSubscribedCentrals:), @selector(nb_updateValue:forCharacteristic:onSubscribedCentrals:));
        swizzleInstance(class, @selector(respondToRequest:withResult:), @selector(nb_respondToRequest:withResult:));
    });
}

- (void)nb_stateCheck {
    if(self.state != CBPeripheralManagerStatePoweredOn) {
        NSString *stack = [[NSThread callStackSymbols] componentsJoinedByString:@"\n"];
        NSAssert(NO, @"CBPeripheralManager was not in powered on state when a method was called. State was %ld\n\nStacktrace:\n%@", (long)self.state, stack);
    }
}

#pragma mark - Method Swizzling

- (void)nb_addService:(CBMutableService *)service {
    [self nb_stateCheck];
    [self nb_addService:service];
}

- (void)nb_removeService:(CBMutableService *)service {
    [self nb_stateCheck];
    [self nb_removeService:service];
}

- (void)nb_removeAllServices {
    [self nb_stateCheck];
    [self nb_removeAllServices];
}

- (void)nb_startAdvertising:(NSDictionary<NSString *,id> *)advertisementData {
    [self nb_stateCheck];
    [self nb_startAdvertising:advertisementData];
}

- (void)nb_stopAdvertising {
    [self nb_stateCheck];
    [self nb_stopAdvertising];
}

- (BOOL)nb_updateValue:(NSData *)value forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:(NSArray<CBCentral *> *)centrals {
    [self nb_stateCheck];
    return [self nb_updateValue:value forCharacteristic:characteristic onSubscribedCentrals:centrals];
}

- (void)nb_respondToRequest:(CBATTRequest *)request withResult:(CBATTError)result {
    [self nb_stateCheck];
    [self respondToRequest:request withResult:result];
}

- (void)nb_setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *)central {
    [self nb_stateCheck];
    [self nb_setDesiredConnectionLatency:latency forCentral:central];
}

@end

#endif
