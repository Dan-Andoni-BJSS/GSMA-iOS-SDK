//
//  MCMobileConnectManager.m
//  DiscoveryDemoSDK
//
//  Created by Andoni Dan on 19/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "MCMobileConnectService.h"
#import "MCRequestConstructor.h"
#import "MCServices_InternalAPI.h"
#import "MCWebController.h"
#import "AuthorizationModel.h"
#import "TokenModel.h"
#import <AFNetworking/AFNetworking.h>

@interface MCMobileConnectService()<MCWebControllerDelegate>

@property (readonly, nonnull) MCRequestConstructor *requestConstructor;

@end

@implementation MCMobileConnectService
{
    MCLevelOfAssurance _levelOfAssurance;
    NSString *_clientId;
    NSString *_authorizationURL;
    NSString *_tokenURL;
    MobileConnectDataResponseBlock _currentResponseBlock;
    MobileConnectControllerResponseBlock _controllerResponseBlock;
}

@synthesize requestConstructor = _requestConstructor;

#pragma mark - Getters
- (MCRequestConstructor*)requestConstructor
{
    if (!_requestConstructor) {
        
        MCServices *services = [MCServices sharedInstance];
        
        _requestConstructor = [[MCRequestConstructor alloc] initWithClientKey:services.clientKey clientSecret:services.clientSecret redirectURL:services.redirectURL];
        
    }
    
    return _requestConstructor;
}

#pragma mark - Initialization
- (instancetype)initWithLevelOfAssurance:(MCLevelOfAssurance)levelOfAssurance
{
    if (self = [super init]) {
        _levelOfAssurance = levelOfAssurance;
    }
    
    return self;
}

- (instancetype)initWithLevelOfAssurance:(MCLevelOfAssurance)levelOfAssurance
                                clientId:(NSString*)clientId
                        authorizationURL:(NSString*)authorizationURL
                                tokenURL:(NSString*)tokenURL
{
    if (self = [self initWithLevelOfAssurance:levelOfAssurance]) {
        _clientId = clientId;
        _authorizationURL = authorizationURL;
        _tokenURL = tokenURL;
    }
    
    return self;
}

- (instancetype)initWithClientId:(NSString*)clientId
                authorizationURL:(NSString*)authorizationURL
                        tokenURL:(NSString*)tokenURL
{
    return [self initWithLevelOfAssurance:MCLevelOfAssurance2 clientId:clientId authorizationURL:authorizationURL tokenURL:tokenURL];
}


#pragma mark - Actions
- (void)getTokenWithSubscriberId:(nonnull NSString*)subscriberId completitionHandler:(nullable MobileConnectDataResponseBlock)completitionHandler
{
    if ([self checkIfParametersValidWithCompletitionHandler:completitionHandler]) {
        _currentResponseBlock = completitionHandler;
        
        NSURLRequest *request = [[self requestConstructor] authorizationRequestWithClientId:_clientId acrValue:_levelOfAssurance subscriberId:subscriberId atAuthorizationURLString:_authorizationURL];
        
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        [manager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest * _Nonnull(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLResponse * _Nonnull response, NSURLRequest * _Nonnull request)
        {
            return [self isValidRedirectWithURL:request.URL inController: nil] ? nil : request;
        }];
        
        NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            
            NSInteger statusCode = ((NSHTTPURLResponse*)response).statusCode;
            
            if (error && statusCode < 300 && statusCode >= 400) {
                completitionHandler(nil, error);
            }
        }];
        
        [dataTask resume];
    }
}

- (void)getTokenInController:(nonnull UIViewController*)controller withCompletitionHandler:(nullable MobileConnectControllerResponseBlock)completitionHandler
{
    if ([self checkIfParametersValidWithCompletitionHandler:^(TokenModel * _Nullable tokenModel, NSError * _Nullable error) {
        completitionHandler(controller, tokenModel, error);
    }])
    {
        _controllerResponseBlock = completitionHandler;
        
        [self webController].requestToLoad = [[self requestConstructor] authorizationRequestWithClientId:_clientId acrValue:_levelOfAssurance subscriberId:nil atAuthorizationURLString:_authorizationURL] ;
        
        [controller presentViewController:[self webController] animated:YES completion:nil];
    }
}

- (void)getTokenWithCode:(NSString*)code andCompletitionHandler:(MobileConnectDataResponseBlock)completitionHandler
{
    if ([self checkIfParametersValidWithCompletitionHandler:completitionHandler]) {
        NSURLRequest *request = [[self requestConstructor] tokenRequestAtTokenURLString:_tokenURL withCode:code];
        
        [self executeRequest:request withSuccessBlock:^(NSDictionary * _Nullable responseDictionary) {
            
            NSError *mappableError;
            
            TokenModel *token = [[TokenModel alloc] initWithDictionary:responseDictionary error:&mappableError];
            
            if (mappableError) {
                completitionHandler(nil, mappableError);
            }
            else
            {
                completitionHandler(token, nil);
            }
            
        } errorBlock:^(NSError * _Nonnull error) {
            completitionHandler(nil, error);
        }];
    }
}

#pragma mark - Web controller delegate methods
- (void)finishWebBrowsingForController:(MCWebController *)controller withError:(NSError *)error
{
    [super finishWebBrowsingForController:controller withError:error];
    
    _controllerResponseBlock(controller, nil, error);
}

- (void)didReceiveResponseWithParameters:(NSDictionary *)parameters fromController:(nullable MCWebController *)controller
{
    self.isAwaitingResponse = NO;
        
    NSError *mappingError;
    
    AuthorizationModel  *model = [[AuthorizationModel alloc] initWithDictionary:parameters error:&mappingError];
    
    if (mappingError) {
        if (controller) {
            _controllerResponseBlock(controller, nil, mappingError);
        }
        else
        {
            _currentResponseBlock(nil, mappingError);
        }
    }
    else
    {
        if (controller) {
            [self getTokenWithCode:model.code andCompletitionHandler:^(TokenModel * _Nullable tokenModel, NSError * _Nullable error) {
                _controllerResponseBlock(controller, tokenModel, error);
            }];
        }
        else
        {
            [self getTokenWithCode:model.code andCompletitionHandler:_currentResponseBlock];
        }
    }
}


#pragma mark - Helpers
- (NSError*)checkClientId:(NSString*)clientId authorizationURL:(NSString*)authorizationURL tokenURL:(NSString*)tokenURL levelOfAssurance:(MCLevelOfAssurance)levelOfAssurance
{
    NSString *tmpString;
    
    if (!clientId) {
        tmpString = [(tmpString ? tmpString : @"") stringByAppendingString:@"No client id provided;"];
    }
    
    if (!authorizationURL) {
        tmpString = [(tmpString ? tmpString : @"") stringByAppendingString:@"No authorization url provided;"];
    }
    
    if (!tokenURL) {
        tmpString = [(tmpString ? tmpString : @"") stringByAppendingString:@"No token url provided;"];
    }
    
    if (levelOfAssurance == 0) {
        tmpString = [(tmpString ? tmpString : @"") stringByAppendingString:@"Level of assurance was not provided"];
    }
    
    if (tmpString) {
        return [NSError errorWithDomain:kMobileConnectErrorDomain code:MCInsufficientMobileConnectParameters userInfo:@{NSLocalizedDescriptionKey : tmpString}];
    }
    
    return nil;
}

- (BOOL)checkIfParametersValidWithCompletitionHandler:(MobileConnectDataResponseBlock)completitionHandler
{
    NSError *error = [self checkClientId:_clientId authorizationURL:_authorizationURL tokenURL:_tokenURL levelOfAssurance:_levelOfAssurance];
    
    if (error)
    {
        completitionHandler(nil, error);
        return NO;
    }
    
    if (![self canStartRequesting]) {
        completitionHandler(nil, [NSError errorWithDomain:kMobileConnectErrorDomain code:MCErrorConcurrentDiscoveryOperations userInfo:@{NSLocalizedDescriptionKey : @"Cannot launch a concurrent discovery operation. Please make sure you have no other running discovery requests"}]);
        
        return NO;
    }
    
    return YES;
}

@end
