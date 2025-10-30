//
//  LocationModule.m
//  Tracking
//
//  Created by Gaurav on 16/10/25.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>   // ✅ must import this, not Foundation

@interface RCT_EXTERN_MODULE(LocationModule, NSObject)

// Expose Swift method to JS
RCT_EXTERN_METHOD(startLogging:(NSString *)arg1
                  arg2:(NSString *)arg2
                  interval:(nonnull NSNumber *)interval
                  stopAfterMs:(nonnull NSNumber *)duration
                  arg5:(NSString *)duration
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(stopLogging:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
@end
