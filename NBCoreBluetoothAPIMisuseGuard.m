//
//  NBCoreBluetoothAPIMisuseGuard.m
//
//  Created by Nick Brook on 03/05/2016.
//  Copyright © 2016 Nick Brook. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <objc/runtime.h>
#import <objc/message.h>

#if DEBUG

static BOOL isCentralPoweredOn(CBCentralManager * c) {
#if TARGET_OS_IPHONE
    if (@available(iOS 10.0, *)) {
        return c.state == CBManagerStatePoweredOn;
    } else {
        return c.state == CBCentralManagerStatePoweredOn;
    }
#else
    return c.state == CBCentralManagerStatePoweredOn;
#endif
}

static BOOL isPeripheralPoweredOn(CBPeripheralManager * c) {
#if TARGET_OS_IPHONE
    if (@available(iOS 10.0, *)) {
        return c.state == CBManagerStatePoweredOn;
    } else {
        return c.state == CBPeripheralManagerStatePoweredOn;
    }
#else
    return c.state == CBPeripheralManagerStatePoweredOn;
#endif
}

static void swizzleForwarding(Class class, NSString * swizzledPrefix, void (^before)(NSInvocation * invocation), void (^after)(NSInvocation * invocation)) {
    SEL selector = @selector(forwardInvocation:);
    Method method = class_getInstanceMethod(class, selector);
    
    void(^block)(id self, NSInvocation *) = ^void(id self, NSInvocation * invocation) {
        NSString *origSelectorName = NSStringFromSelector(invocation.selector);
        NSString *altSelectorName = [NSString stringWithFormat:@"%@%@", swizzledPrefix, origSelectorName];
        SEL altSelector = NSSelectorFromString(altSelectorName);
        if([self respondsToSelector:altSelector]) {
            if(before) {
                before(invocation);
            }
            invocation.selector = altSelector;
            [invocation invoke];
            if(after) {
                after(invocation);
            }
        }
    };
    
    IMP newImp = imp_implementationWithBlock(block);
    class_addMethod(class, selector, newImp, method_getTypeEncoding(method));
}

static void removeAllFromList(Class class, NSString *toSwizzlePrefix, SEL selectors[], unsigned int numSelectors) {
    SEL selectorWithNoImplementation = sel_registerName("methodWhichMustNotExist::::");
    IMP forwarderIMP = class_getMethodImplementation(class, selectorWithNoImplementation);
    for (int i = 0; i < numSelectors; i++) {
        Method originalMethod = class_getInstanceMethod(class, selectors[i]);
        IMP originalIMP = method_getImplementation(originalMethod);
        const char *types = method_getTypeEncoding(originalMethod);
        NSString *aliasSelectorName = [NSString stringWithFormat:@"%@%@", toSwizzlePrefix, NSStringFromSelector(selectors[i])];
        class_replaceMethod(class, selectors[i], forwarderIMP, types);
        class_addMethod(class, NSSelectorFromString(aliasSelectorName), originalIMP, types);
    }
}

static void surroundMethods(Class class, SEL *selectors, unsigned int numSelectors, void (^before)(NSInvocation * invocation), void (^after)(NSInvocation * invocation)) {
    NSString *prefix = @"nb_";
    swizzleForwarding(class, prefix, before, after);
    removeAllFromList(class, prefix, selectors, numSelectors);
}

@implementation CBCentralManager (APIMisuseGuard)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selectors[] = {
            @selector(connectPeripheral:options:),
            @selector(retrieveConnectedPeripheralsWithServices:),
            @selector(cancelPeripheralConnection:),
            @selector(scanForPeripheralsWithServices:options:),
            @selector(stopScan)
        };
        surroundMethods(self.class, selectors, sizeof(selectors) / sizeof(SEL), ^(NSInvocation *invocation) {
            CBCentralManager * s = invocation.target;
            if(!isCentralPoweredOn(s)) {
                NSString *stack = [[NSThread callStackSymbols] componentsJoinedByString:@"\n"];
                NSAssert(NO, @"CBCentralManager was not in powered on state when %@ was called. State was %ld\n\nStacktrace:\n%@", NSStringFromSelector(invocation.selector), (long)s.state, stack);
            }
        }, nil);
    });
}

@end

@implementation CBPeripheral (APIMisuseGuard)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selectors[] = {
            @selector(discoverServices:),
            @selector(discoverIncludedServices:forService:),
            @selector(discoverCharacteristics:forService:),
            @selector(discoverDescriptorsForCharacteristic:),
            @selector(readValueForCharacteristic:),
            @selector(readValueForDescriptor:),
            @selector(writeValue:forCharacteristic:type:),
            @selector(writeValue:forDescriptor:),
            @selector(setNotifyValue:forCharacteristic:),
            @selector(readRSSI)
        };
        surroundMethods(self.class, selectors, sizeof(selectors) / sizeof(SEL), ^(NSInvocation *invocation) {
            CBPeripheral * s = invocation.target;
            if(s.state != CBPeripheralStateConnected) {
                NSString *stack = [[NSThread callStackSymbols] componentsJoinedByString:@"\n"];
                NSAssert(NO, @"CBPeripheral was not in connected state when %@ was called. State was %ld\n\nStacktrace:\n%@", NSStringFromSelector(invocation.selector), (long)s.state, stack);
            }
        }, nil);
    });
}

@end

@implementation CBPeripheralManager (APIMisuseGuard)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selectors[] = {
            @selector(addService:),
            @selector(removeService:),
            @selector(removeAllServices),
            @selector(startAdvertising:),
            @selector(stopAdvertising),
            @selector(updateValue:forCharacteristic:onSubscribedCentrals:),
            @selector(respondToRequest:withResult:),
            @selector(setDesiredConnectionLatency:forCentral:)
        };
        surroundMethods(self.class, selectors, sizeof(selectors) / sizeof(SEL), ^(NSInvocation *invocation) {
            CBPeripheralManager * s = invocation.target;
            if(!isPeripheralPoweredOn(s)) {
                NSString *stack = [[NSThread callStackSymbols] componentsJoinedByString:@"\n"];
                NSAssert(NO, @"CBPeripheralManager was not in powered on state when %@ was called. State was %ld\n\nStacktrace:\n%@", NSStringFromSelector(invocation.selector), (long)s.state, stack);
            }
        }, nil);
    });
}

@end

#endif
