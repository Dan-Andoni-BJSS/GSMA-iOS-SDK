//
//  KeyValueHelper.m
//  MobileConnectDemo
//
//  Created by Andoni Dan on 13/05/16.
//  Copyright © 2016 dan. All rights reserved.
//

#import "KeyValueHelper.h"

@implementation KeyValueHelper

+ (nonnull NSDictionary*)queryParamsFromString:(nullable NSString*)string;
{
    if (string) {
        
        NSMutableArray *keys = [@[] mutableCopy];
        NSMutableArray *values = [@[] mutableCopy];
        
        NSArray<NSString*> *queryKeyValues = [string componentsSeparatedByString:@"&"];
        
        [queryKeyValues enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSArray *keyValue = [obj componentsSeparatedByString:@"="];
            
            if (keyValue.count == 2) {
                
                [keys addObject:keyValue[0]];
                [values addObject:keyValue[1]];
            }
            else
            {
                NSLog(@"unable to process key value %@", keyValue);
            }
        }];
        
        if (keys.count > 0) {
            return [NSDictionary dictionaryWithObjects:values forKeys:keys];
        }
        else
        {
            NSLog(@"no keys and values found in string [%@]", string);
        }
    }
    else
    {
        NSLog(@"could not obtain values and keys from nil string");
    }
    
    return @{};
}

@end
