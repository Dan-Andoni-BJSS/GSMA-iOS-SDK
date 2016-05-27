//
//  TokenResponseModel.h
//  DiscoveryDemoSDK
//
//  Created by Andoni Dan on 24/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "MCModel.h"
#import "TokenModel.h"

@interface TokenResponseModel : MCModel

- (instancetype)initWithTokenModel:(TokenModel*)tokenModel;

@property (nullable) TokenModel *tokenData;
@property (nullable) NSDictionary *decodedToken;

@end
