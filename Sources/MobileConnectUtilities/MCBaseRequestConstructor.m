//
//  MCRequestConstructor.m
//  DiscoveryDemoSDK
//
//  Created by Andoni Dan on 18/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "MCBaseRequestConstructor.h"

@implementation MCBaseRequestConstructor
{
    NSString *_clientKey;
    NSString *_clientSecret;
}

- (instancetype)initWithClientKey:(NSString*)clientKey
                     clientSecret:(NSString*)clientSecret
                      redirectURL:(NSString *)redirectURL
{
    if (self = [super init]) {
        
        _clientKey = clientKey;
        _clientSecret = clientSecret;
        self.redirectURL = redirectURL;
    }
    
    return self;
}

- (AFHTTPRequestSerializer*)defaultSerializer
{
    return [self authorizeSerializer: [AFHTTPRequestSerializer serializer]];
}

- (AFHTTPRequestSerializer*)authorizeSerializer:(AFHTTPRequestSerializer*)serializer
{
    [serializer setAuthorizationHeaderFieldWithUsername:_clientKey
                                               password:_clientSecret];
    
    return serializer;
}

@end
