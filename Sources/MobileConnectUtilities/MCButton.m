//
//  MCButton.m
//  DiscoveryDemoSDK
//
//  Created by Andoni Dan on 23/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "MCButton.h"
#import "MobileConnectSDK.h"

#pragma mark - Local constants

#define kMobileConnectImageName @"mobileConnectButtonImage"

@interface UIView (mxcl)
- (UIViewController *)parentViewController;
@end

@implementation UIView (mxcl)
- (UIViewController *)parentViewController {
    UIResponder *responder = self;
    while ([responder isKindOfClass:[UIView class]])
        responder = [responder nextResponder];
    return (UIViewController *)responder;
}
@end

@implementation MCButton

#pragma mark - Constructor methods

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self configureButton];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self configureButton];
    }
    
    return self;
}

+ (instancetype)buttonWithType:(UIButtonType)buttonType
{
    return [[self alloc] init];
}

#pragma mark - View configuration

- (void)configureButton
{
    [self configureView];
    
    [self addTarget:self action:@selector(touchedUpInside) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureView
{
    [self setBackgroundImage:[UIImage imageNamed:kMobileConnectImageName] forState:UIControlStateNormal];
    [self sizeToFit];
}

#pragma mark - Events

- (void)touchedUpInside
{
    [self launchDiscovery];
}

#pragma mark - Discovery

- (void)launchDiscovery
{
    [MobileConnectSDK getTokenInController:[self parentViewController] withCompletitionHandler:nil];
}

@end

