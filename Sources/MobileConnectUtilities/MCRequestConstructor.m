//
//  MCRequestConstructor.m
//  DiscoveryDemoSDK
//
//  Created by Andoni Dan on 19/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "MCRequestConstructor.h"

@implementation MCRequestConstructor

- (NSURLRequest*)authorizationRequestWithClientId:(NSString*)clientID
                                         acrValue:(MCLevelOfAssurance)levelOfAssurance
                                     subscriberId:(NSString*)subscriberId
                         atAuthorizationURLString:(NSString*)authorizationURLString
{
    NSString *nonce = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *state = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    NSMutableDictionary *parameters = [@{@"client_id" : clientID, @"response_type" : @"code", @"redirect_uri" : self.redirectURL, @"scope" : @"openid", @"acr_values" : [NSString stringWithFormat:@"%d", levelOfAssurance], @"state" : state, @"nonce" : nonce} mutableCopy];
    
    if (subscriberId) {
        parameters[@"login_hint"] = [NSString stringWithFormat:@"ENCR_MSISDN:%@", subscriberId];
    }
    
    return [[self defaultSerializer] requestWithMethod: @"GET" URLString:authorizationURLString parameters:[parameters copy] error:nil];
}

- (NSURLRequest*)tokenRequestAtTokenURLString:(NSString*)tokenURLString withCode:(NSString*)code
{
    NSDictionary *parameters = @{@"code" : code, @"grant_type" : @"authorization_code", @"redirect_uri" : self.redirectURL};
    
    return [[self defaultSerializer] requestWithMethod:@"POST" URLString:tokenURLString parameters:parameters error:nil];
}

@end
