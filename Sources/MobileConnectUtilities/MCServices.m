//
//  MCServices.m
//  DiscoveryDemoSDK
//
//  Created by Andoni Dan on 17/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "MCServices.h"
#import "MCServices_InternalAPI.h"

@implementation MCServices

#pragma mark - Factory methods

+ (instancetype)sharedInstance
{
    static MCServices *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

+ (void)setClientKey:(nonnull NSString *)clientKey
{
    [MCServices sharedInstance].clientKey = clientKey;
}

+ (void)setClientSecret:(nonnull NSString *)clientSecret
{
    [MCServices sharedInstance].clientSecret = clientSecret;
}

+ (void)setRedirectURL:(nonnull NSString *)redirectURL
{
    [MCServices sharedInstance].redirectURL = redirectURL;
}

@end
