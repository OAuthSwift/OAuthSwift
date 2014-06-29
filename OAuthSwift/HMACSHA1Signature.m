//
//  HMACSHA1Signature.m
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

#import "HMACSHA1Signature.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation HMACSHA1Signature

+ (NSData *)signatureForKey:(NSData *)keyData data:(NSData *)data
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CCHmacContext cx;
    CCHmacInit(&cx, kCCHmacAlgSHA1, keyData.bytes, keyData.length);
    CCHmacUpdate(&cx, data.bytes, data.length);
    CCHmacFinal(&cx, digest);

    return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

@end
