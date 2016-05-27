//
//  MobileConnectSDK.m
//  DiscoveryDemoSDK
//
//  Created by Andoni Dan on 23/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "MobileConnectSDK.h"
#import "MCServices.h"
#import "DSDiscoveryService.h"
#import "MCMobileConnectService.h"
#import "Reachability.h"

@interface MobileConnectSDK()

@property (nullable) NSObject<MobileConnectSDKDelegate> *delegate;
@property (nullable) NSString *applicationEndpoint;

@end

@implementation MobileConnectSDK

#pragma mark - Getters
+ (instancetype)sharedInstance
{
    static MobileConnectSDK *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

+ (NSObject<MobileConnectSDKDelegate>*)delegate
{
    return [MobileConnectSDK sharedInstance].delegate;
}

#pragma mark - Setters
+ (void)setClientKey:(nonnull NSString*)clientKey
{
    [MCServices setClientKey:clientKey];
}

+ (void)setClientSecret:(nonnull NSString*)clientSecret
{
    [MCServices setClientSecret:clientSecret];
}

+ (void)setRedirectURL:(nonnull NSString*)redirectURL
{
    [MCServices setRedirectURL:redirectURL];
}

+ (void)setApplicationEndpoint:(nonnull NSString*)applicationEndpoint
{
    [MobileConnectSDK sharedInstance].applicationEndpoint = applicationEndpoint;
}

+ (void)setDelegate:(nullable NSObject<MobileConnectSDKDelegate>*)delegate
{
    [MobileConnectSDK sharedInstance].delegate = delegate;
}

#pragma mark - UI elements
+ (nonnull MCButton*)button
{
    return nil;
}

#pragma mark - Actions

+ (void)willStart
{
    if ([[self delegate] respondsToSelector:@selector(mobileConnectWillStart)]) {
        [[self delegate] mobileConnectWillStart];
    }
}

+ (void)mobileConnectWillPresentWebController
{
    if ([[self delegate] respondsToSelector:@selector(mobileConnectWillPresentWebController)]) {
        [[self delegate] mobileConnectWillPresentWebController];
    }
}

+ (void)failedGettingTokenWithError:(NSError*)error
{
    if ([[self delegate] respondsToSelector:@selector(mobileConnectFailedGettingTokenWithError:)]) {
        [[self delegate] mobileConnectFailedGettingTokenWithError:error];
    }
}

+ (void)willDismissWebController
{
    if ([[self delegate] respondsToSelector:@selector(willDismissWebController)]) {
        [[self delegate] mobileConnectWillDismissWebController];
    }
}

+ (BOOL)checkInternetWithCallback:(MobileConnectSDKResponseBlock)handler
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == 0) {
        
        NSError *noInternetError = [NSError errorWithDomain:kMobileConnectErrorDomain code: MCNoInternetConnection userInfo:@{NSLocalizedDescriptionKey : @"Please check your internet connection. The process was interrupted"}];
        
        if (handler) {
            handler(nil, noInternetError);
        }
        else
        {
            [self failedGettingTokenWithError:noInternetError];
        }
        
        return NO;
    }
    else
    {
        return YES;
    }
}

+ (void)getTokenInController:(nonnull UIViewController*)controller withCompletitionHandler:(nullable MobileConnectSDKResponseBlock)handler
{
    if (!handler) {
        [self willStart];
    }
    
    if (![self checkInternetWithCallback:handler]) {
        return;
    }
    
    DSDiscoveryService *discoveryService = [[DSDiscoveryService alloc] initWithApplicationEndpoint:[MobileConnectSDK sharedInstance].applicationEndpoint];
    
    [self mobileConnectWillPresentWebController];
    
    [discoveryService startOperatorDiscoveryInController:controller withCompletitionHandler:^(UIViewController *localController, DiscoveryResponse * _Nullable operatorsData, NSError * _Nullable error)
    {
        if (error) {
            if (handler) {
                handler(nil, error);
            }
            else
            {
                [self failedGettingTokenWithError:error];
            }
            
            [self willDismissWebController];
            
            [controller dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            MCMobileConnectService *mobileConnectService = [[MCMobileConnectService alloc] initWithClientId:operatorsData.response.client_id authorizationURL:[operatorsData.response.apis.operatorid  authorizationLink] tokenURL:[operatorsData.response.apis.operatorid  tokenLink]];
            
            if (![self checkInternetWithCallback:handler]) {
                return;
            }
            
            if (operatorsData.subscriber_id) {
                
                [mobileConnectService getTokenWithSubscriberId:operatorsData.subscriber_id completitionHandler:^(TokenModel * _Nullable tokenModel, NSError * _Nullable error)
                {
                    [self treatTokenResponse:tokenModel error:error withHandler:handler inController:localController];
                }];
                
            }
            else
            {
                [self willDismissWebController];
                
                [localController dismissViewControllerAnimated:YES completion:nil];
                
                [mobileConnectService getTokenInController:controller withCompletitionHandler:^(UIViewController * _Nonnull tmpController, TokenModel * _Nullable tokenModel, NSError * _Nullable error) {
                    
                    [self treatTokenResponse:tokenModel error:error withHandler:handler inController:tmpController];
                }];
            }
        }
    }];
}

+ (void)treatTokenResponse:(TokenModel*)tokenModel error:(NSError*)error withHandler:(MobileConnectSDKResponseBlock)handler inController:(UIViewController*)controller
{
    if (handler) {
        
        handler([[TokenResponseModel alloc] initWithTokenModel:tokenModel], error);
    }
    else
    {
        error ? [[MobileConnectSDK sharedInstance].delegate mobileConnectFailedGettingTokenWithError:error] :
        [[MobileConnectSDK sharedInstance].delegate mobileConnectDidGetTokenResponse:[[TokenResponseModel alloc] initWithTokenModel:tokenModel]];
    }
    
    [self willDismissWebController];
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
