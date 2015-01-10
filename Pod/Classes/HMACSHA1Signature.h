//
//  HMACSHA1Signature.h
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMACSHA1Signature : NSObject

+ (NSData *)signatureForKey:(NSData *)keyData data:(NSData *)data;

@end
