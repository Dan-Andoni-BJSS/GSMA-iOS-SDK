//
//  WebController.m
//  DiscoveryDemoSDK
//
//  Created by Andoni Dan on 18/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "MCWebController.h"
#import <WebKit/WebKit.h>

@interface MCWebController ()<UIToolbarDelegate, WKNavigationDelegate>

@property (nullable, readonly) WKWebView *webView;

@end

@implementation MCWebController
{
    __weak IBOutlet UIView *webViewContainer;
}

@synthesize webView = _webView;

#pragma mark - Getters
- (WKWebView*)webView
{
    if (!_webView) {
        [self configureWebView];
    }
    
    return _webView;
}

#pragma mark - Web View configuration
- (void)configureWebView
{
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    
    configuration.preferences = [WKPreferences new];
    
    _webView = [[WKWebView alloc] initWithFrame:webViewContainer.bounds configuration:configuration];
    
    _webView.navigationDelegate = self;
    
    [webViewContainer addSubview:_webView];
}

#pragma mark - View life cycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.webView loadRequest:self.requestToLoad];
}

#pragma mark - Web view delegate methods
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    decisionHandler([self.delegate webController:self shouldRedirectToURL:navigationAction.request.URL] ?WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self.delegate webController:self failedLoadingRequestWithError:error];
}

#pragma mark - Tool bar delegate
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return  UIBarPositionTopAttached;
}

#pragma mark - Events
- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [self.delegate webControllerDidCancel:self];
}

@end
