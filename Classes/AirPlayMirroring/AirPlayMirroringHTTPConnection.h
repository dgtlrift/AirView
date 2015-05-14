//
//  AirPlayMirroringHTTPConnection.h
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import "AirViewHTTPConnection.h"
#import "GCDAsyncSocket.h"
#import "crypt.h"

@interface AirPlayMirroringHTTPConnection : AirViewHTTPConnection

@property(nonatomic) NSUInteger contentLength;
@property(nonatomic, strong) NSData *content;
@property(nonatomic, strong) GCDAsyncSocket *asyncSocketMirroring;
@property(nonatomic) crypt_aes_p aes_key;

@end
