//
//  DSDiscoveryManager.m
//  DiscoveryDemoSDK
//
//  Created by Andoni Dan on 17/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "DSDiscoveryService.h"
#import <SafariServices/SafariServices.h>
#import "MCWebController.h"
#import "DSDiscoveryRequestConstructor.h"
#import "MCServices_InternalAPI.h"
#import "KeyValueHelper.h"
#import "MCConstants.h"
#import "OperatorDataRedirectModel.h"
#import <AFNetworking/AFNetworking.h>

@interface DSDiscoveryService()<MCWebControllerDelegate>

@property (nonnull) NSString *endpoint;
@property (nullable, readonly) DSDiscoveryRequestConstructor *requestConstructor;

@property (nullable) DiscoveryDataResponse currentResponseBlock;
@property (nullable) DiscoveryResponseBlock currentControllerResponseBlock;

@end

@implementation DSDiscoveryService

@synthesize requestConstructor = _requestConstructor;

#pragma mark - Initial configuration
- (instancetype)initWithApplicationEndpoint:(NSString*)endpoint
{
    if (self = [super init]) {
        [self setApplicationEndpoint:endpoint];
    }
    
    return self;
}

#pragma mark - Setters
- (void)setApplicationEndpoint:(nonnull NSString*)endpoint
{
    if (!endpoint) {
        [NSException raise:@"NillEndpoint" format:@"A nil application endpoint is not allowed"];
    }
    
    self.endpoint = endpoint;
}

#pragma mark - Getters

- (DSDiscoveryRequestConstructor*)requestConstructor
{
    if (!_requestConstructor) {
        
        MCServices *sharedInstance = [MCServices sharedInstance];
        
        _requestConstructor = [[DSDiscoveryRequestConstructor alloc] initWithApplicationURLString:self.endpoint redirectURLString:sharedInstance.redirectURL clientKey:sharedInstance.clientKey clientSecret:sharedInstance.clientSecret];
    }
    
    return _requestConstructor;
}

#pragma mark - 
- (void)didReceiveResponseWithParameters:(NSDictionary*)parameters fromController:(nullable MCWebController *)controller
{
    NSError *mappingError;
    
    OperatorDataRedirectModel *operatorData = [[OperatorDataRedirectModel alloc] initWithDictionary:parameters error:&mappingError];
    
    self.isAwaitingResponse = NO;
    
    if (!mappingError)
    {
        [self startOperatorDiscoveryWithResponse:operatorData withCompletitionHandler:^(DiscoveryResponse * _Nullable operatorsData, NSError * _Nullable error)
        {
            self.currentControllerResponseBlock(controller, operatorsData, error);
        }];
    }
    else
    {
        self.currentControllerResponseBlock(controller, nil, mappingError);
    }
}

#pragma mark - Discovery actions
//start discovery with absolutely no data
- (void)startOperatorDiscoveryInController:(nonnull UIViewController*)controller withCompletitionHandler:(nullable DiscoveryResponseBlock)completitionHandler
{
    if ([self canStartRequesting]) {
        
        self.currentControllerResponseBlock = completitionHandler;
        
        self.webController.requestToLoad = [self.requestConstructor requestWithParameters:@{}];
        
        [controller presentViewController:self.webController animated:YES completion:nil];
    }
}

//start discovery with operator data received from web form
//launch discovery with the received parameters and obtain operators urls
- (void)startOperatorDiscoveryWithResponse:(OperatorDataRedirectModel*)model withCompletitionHandler: (nullable DiscoveryDataResponse)completitionHandler
{
    [self startOperatorDiscoveryWithCountryCode:[model mcc] networkCode:[model mnc] withCompletitionHandler:^(DiscoveryResponse * _Nullable operatorsData, NSError * _Nullable error) {
        
        if (model.subscriber_id) {
            operatorsData.subscriber_id = model.subscriber_id;
            operatorsData.response.subscriber_id = model.subscriber_id;
        }
        
        completitionHandler(operatorsData, error);
    }];
}

//start discovery with mcc_mnc data
- (void)startOperatorDiscoveryWithCountryCode:(nonnull NSString*)countryCode networkCode:(nonnull NSString*)networkCode withCompletitionHandler: (nullable DiscoveryDataResponse)completitionHandler
{
    if (!countryCode || !networkCode) {
        completitionHandler(nil, [NSError errorWithDomain:kMobileConnectErrorDomain code:MCErrorNoMNC_MCC userInfo:@{NSLocalizedDescriptionKey : @"Could not obtain mcc or mnc code"}]);
    }
    else
    {
        NSURLRequest *request = [[self requestConstructor] requestWithMCC:countryCode andMNC:networkCode];
        
        [self startOperatorDiscoveryWithRequest:request completitionHandler:completitionHandler];
    }
}

//start discovery with phone number
- (void)startOperatorDiscoveryForPhoneNumber:(nonnull NSString*)phoneNumber withCompletitionHandler:(nullable DiscoveryDataResponse)completitionHandler
{
    if (!phoneNumber) {
        completitionHandler(nil, [NSError errorWithDomain:kMobileConnectErrorDomain code:MCErrorNoPhoneNumber userInfo:@{NSLocalizedDescriptionKey : @"The provided phone number was nil"}]);
    }
    else
    {
        NSURLRequest *request = [[self requestConstructor] requestWithPhoneNumber:phoneNumber];
        
        [self startOperatorDiscoveryWithRequest:request completitionHandler:completitionHandler];
    }
}

- (void)startOperatorDiscoveryWithRequest:(NSURLRequest*)request completitionHandler:(nullable DiscoveryDataResponse)completitionHandler
{
    if ([self canStartRequesting]) {
        
        [self executeRequest:request withSuccessBlock:^(NSDictionary * _Nullable responseDictionary) {
            
            NSError *mappableError;
            
            DiscoveryResponse *discoveryResponse = [[DiscoveryResponse alloc] initWithDictionary:responseDictionary error:&mappableError];
            
            if (mappableError) {
                completitionHandler(nil, mappableError);
            }
            else
            {
                completitionHandler(discoveryResponse, nil);
            }
            
        } errorBlock:^(NSError * _Nonnull error) {
            completitionHandler(nil, error);
        }];
    }
    else
    {
        completitionHandler(nil, [NSError errorWithDomain:kMobileConnectErrorDomain code:MCErrorConcurrentDiscoveryOperations userInfo:@{NSLocalizedDescriptionKey : @"Cannot launch a concurrent discovery operation. Please make sure you have no other running discovery requests"}]);
    }
}

#pragma mark - Web controller delegate
- (void)finishWebBrowsingForController:(MCWebController *)controller withError:(NSError *)error
{
    [super finishWebBrowsingForController:controller withError:error];
    
    self.currentControllerResponseBlock(controller, nil, error);
}

@end
