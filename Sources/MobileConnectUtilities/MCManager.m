//
//  MCManager.m
//  DiscoveryDemoSDK
//
//  Created by Andoni Dan on 19/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "MCManager.h"
#import "MCServices_InternalAPI.h"
#import "KeyValueHelper.h"
#import "MCConstants.h"
#import <AFNetworking/AFNetworking.h>

@interface MCManager()<MCWebControllerDelegate>

@property (nullable, readonly) MCWebController *webController;

@end

@implementation MCManager

@synthesize webController = _webController;

- (MCWebController *)webController
{
    if (!_webController) {
        _webController = [[UIStoryboard storyboardWithName:@"MCWebController" bundle:nil] instantiateInitialViewController];
        _webController.delegate = self;
    }
    
    return _webController;
}

#pragma mark - Networking

- (void)executeRequest:(NSURLRequest *)request withCompletitionHandler:(AFNetworkingResponseBlock)completitionHandler
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:completitionHandler];
    
    [dataTask resume];
}

- (void)executeRequest:(nonnull NSURLRequest*)request withSuccessBlock:(void (^ _Nullable)(NSDictionary * _Nullable responseDictionary))successBlock errorBlock:(void (^ _Nullable)(NSError * _Nonnull error))errorBlock
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error)
    {
        self.isAwaitingResponse = NO;
        
        if (error) {
            errorBlock(error);
        }
        else
        {
            successBlock(responseObject);
        }
    }];
    
    [dataTask resume];
}

#pragma mark - Web controller delegate methods

- (void)didReceiveResponseWithParameters:(nullable NSDictionary*)parameters fromController:(nullable MCWebController*)controller
{
    
}

- (BOOL)webController:(MCWebController *)controller shouldRedirectToURL:(NSURL *)url
{
    return ![self isValidRedirectWithURL:url inController:controller];
}

- (BOOL)isValidRedirectWithURL:(nonnull NSURL*)url inController:(MCWebController*)controller;
{
    BOOL isTheSameHost = [url.host isEqualToString:[NSURL URLWithString:[MCServices sharedInstance].redirectURL].host];
    
    NSDictionary *queryParams = [KeyValueHelper queryParamsFromString:[url query]];
    
    if (isTheSameHost & (queryParams.allKeys.count > 0)) {
        
        self.isAwaitingResponse = NO;
        
        [self didReceiveResponseWithParameters:queryParams fromController:controller];
        
        return YES;
    }
    
    return NO;
}

- (void)webControllerDidCancel:(MCWebController *)controller
{
    [self finishWebBrowsingForController:controller withError:[NSError errorWithDomain:kMobileConnectErrorDomain code:MCErrorCodeUserCancelled userInfo:@{NSLocalizedDescriptionKey : @"User cancelled action"}]];
}

- (void)webController:(MCWebController *)controller failedLoadingRequestWithError:(NSError*)error
{
    [self finishWebBrowsingForController:controller withError:error];
}

#pragma mark - Helpers
- (void)finishWebBrowsingForController:(MCWebController*)controller withError:(NSError*)error
{
    self.isAwaitingResponse = NO;
}

- (BOOL)canStartRequesting
{
    BOOL canStartRequesting = [self hasCredentials] && !self.isAwaitingResponse;
    
    self.isAwaitingResponse = YES;
    
    return canStartRequesting;
}

- (BOOL)hasCredentials
{
    MCServices *sharedInstance = [MCServices sharedInstance];
    
    BOOL hasCredentials = sharedInstance.clientSecret && sharedInstance.clientSecret;
    
    if (!hasCredentials) {
        [NSException raise:@"NoCredentials" format:@"Please provide client secret and client key for accessing Mobile Connect SDK"];
    }
    
    return hasCredentials;
}

@end
