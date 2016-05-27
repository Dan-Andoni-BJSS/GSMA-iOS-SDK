//
//  DiscoveryRequestConstructor.m
//  DiscoveryDemoSDK
//
//  Created by Andoni Dan on 18/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "DSDiscoveryRequestConstructor.h"
#import <AFNetworking/AFNetworking.h>

#define kRedirectURLKey @"Redirect_URL"

@implementation DSDiscoveryRequestConstructor
{
    NSString *_applicationURLString;
}

- (instancetype)initWithApplicationURLString:(NSString*)applicationURLString
                           redirectURLString:(NSString*)redirectURLString
                                   clientKey:(NSString*)clientKey
                                clientSecret:(NSString*)clientSecret;
{
    if (self = [super initWithClientKey:clientKey clientSecret:clientSecret redirectURL:redirectURLString])
    {
        _applicationURLString = applicationURLString;
    }
    
    return self;
}

- (NSURLRequest*)requestWithPhoneNumber:(NSString*)phoneNumber
{
    return [self requestWithParameters:@{@"MSISDN" : phoneNumber}];
}

- (NSURLRequest*)requestWithMCC:(NSString*)mcc andMNC:(NSString*)mnc
{
    NSDictionary *parametersDictionary = @{@"Identified-MCC" : mcc, @"Identified-MNC" : mnc};
    
    return [self requestWithParameters:parametersDictionary];
}

- (NSURLRequest*)requestWithParameters:(NSDictionary*)parametersDictionary
{
    NSDictionary *localParametersDictionary = parametersDictionary ? parametersDictionary : @{};
    
    NSMutableDictionary *localMutableParametersDictionary = [localParametersDictionary mutableCopy];
    
    [localMutableParametersDictionary setValue:self.redirectURL forKey:kRedirectURLKey];
    
    return [[self defaultSerializer] requestWithMethod:[localParametersDictionary.allKeys containsObject:@"MSISDN"] ? @"POST" : @"GET" URLString:_applicationURLString parameters:localMutableParametersDictionary error:nil];
}

@end
