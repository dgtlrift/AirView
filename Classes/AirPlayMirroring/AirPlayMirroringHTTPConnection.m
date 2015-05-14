//
//  AirPlayMirroringHTTPConnection.m
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import "AirPlayMirroringHTTPConnection.h"
#import "HTTPDataResponse.h"
#import "AirViewServerInfo.h"
#import "HTTPLogging.h"
#import "HTTPMessage.h"
#import "airtunesd_wrapper.h"
#import "GCDAsyncSocket.h"

const char *stringFromData(CFDataRef data, size_t *size);

#define CHUNK 1024 * 3
#define TIMEOUT_NONE 300

enum tag_stream {
    TAG_BITSTREAM,
    TAG_CODEC_DATA,
    TAG_HEARTBEAT,
    TAG_HEADER,
};

@interface NoResponse : NSObject<HTTPResponse>
@end

@implementation NoResponse

- (BOOL)delayResponeHeaders {
    return YES;
}

@end

@interface HTTPConnection () <GCDAsyncSocketDelegate>
@end

@interface AirPlayMirroringHTTPConnection () <GCDAsyncSocketDelegate>

@end

@implementation AirPlayMirroringHTTPConnection

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig {
    self = [super initWithAsyncSocket:newSocket configuration:aConfig];
    if (self) {
        [self createSocketAndStartListening];
    }
    return self;
}

- (NSDictionary *)supportedGETEndpoints {
    NSMutableDictionary *dict = [[super supportedGETEndpoints] mutableCopy];
    if (dict == nil) {
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict addEntriesFromDictionary:@{
                                     @"/stream.xml": @"streamPlist",
                                     }];
    return dict;
}

- (NSDictionary *)supportedPOSTEndpoints {
    NSMutableDictionary *dict = [[super supportedPOSTEndpoints] mutableCopy];
    if (dict == nil) {
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict addEntriesFromDictionary:@{
                                     @"/fp-setup": @"fpSetup",
                                     @"/stream": @"stream",
                                     }];
    NSLog(@"%@", dict);
    return dict;
}

- (id<HTTPResponse>)POST_fpSetup {
    NSData *content = [request body];
    
    uint8_t fply_header[12];
    [content getBytes:fply_header length:sizeof(fply_header)];
    
    uint8_t data[content.length];
    memset(data, 0, content.length);
    [content getBytes:data length:content.length];
    
    _print_data(data, content.length);
    
    NSLog(@".");
    uint8_t *response_data;
    response_data = getChallengeResponse(data);
    
    int response_length = ((fply_header[6] == 1) ? 142 : 32);
    
    _print_data(response_data, response_length);
    
    
    return [[HTTPDataResponse alloc] initWithData:[NSData dataWithBytesNoCopy:response_data length:response_length freeWhenDone:NO]];
}

- (id)GET_streamPlist {
    UIScreen *screen = [UIScreen mainScreen];
    NSDictionary *dict = @{
                           @"height": @(screen.applicationFrame.size.height),
                           @"width": @(screen.applicationFrame.size.width),
                           @"refreshRate": @(0.016666666666666666),
                           @"version": [[AirViewServerInfo alloc] init].srcvers,
                           @"overscanned": @(YES),
                           };
    
    NSError *error = nil;
    NSData *response = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    HTTPDataResponse *res = [[HTTPDataResponse alloc] initWithData:response];
    [res setHttpHeaderValue:@"text/x-apple-plist+xml" forKey:@"Content-Type"];
    return res;
}

- (id)POST_stream {
    NSDictionary *data = [self dictFromPlistBody];
    NSLog(@"%@", data);
    
    size_t aes_size = 0;
    const char *aes_key_encrypted = stringFromData((__bridge CFDataRef)data[@"param1"], &aes_size);
    size_t aes_i_size = 0;
    const char *aes_initializer = stringFromData((__bridge CFDataRef)data[@"param2"], &aes_i_size);
    NSLog(@"%s  %zu\n%s  %zu\n\n", aes_key_encrypted, aes_size, aes_initializer, aes_i_size);
    
    uint8_t *aes_key;
    if (aes_key_encrypted && aes_size == 72) {
        aes_key = decryptAESKey(aes_key_encrypted);
        _print_data(aes_key, 16);
    }
    
    self.aes_key = crypt_aes_create(aes_key, aes_initializer, aes_i_size);
    
    _print_data(self.aes_key, sizeof(self.aes_key));
    
    [asyncSocket readDataToLength:128 withTimeout:-1 tag:TAG_HEADER];
    
    return [[NoResponse alloc] init];
    return [[HTTPDataResponse alloc] initWithData:nil];
}

- (void)createSocketAndStartListening {
    self.asyncSocketMirroring = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.asyncSocketMirroring setIPv6Enabled:NO];
    NSError *error = nil;
    if (![self.asyncSocketMirroring acceptOnPort:7010/*49152*/ error:&error])
    {
        NSLog(@"Error in acceptOnPort:error: -> %@", error);
    }
}

struct stream_header {
    UInt32 data_length;
    UInt16 data_type;
    UInt16 unknown;
    UInt64 timestamp;
};

struct codec_data {
    int version : 8;
    int profile : 8;
    int compatibility : 8;
    int level : 8;
    int reserved_1 : 6;
    int nal : 2;
    int reserved_2 : 3;
    int sps_number : 5;
    int sps_length : 16;
    UInt32 sequence_parameter_set_1;
    UInt32 sequence_parameter_set_2;
    UInt32 sequence_parameter_set_3;
    UInt32 sequence_parameter_set_4;
    int pps_number : 8;
    int pps_length : 16;
    UInt32 picture_parameter_set;
};

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"socket %@ did accept new socket %@", sock, newSocket);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"tag: %li data length: %i", tag, data.length);
    switch (tag)
    {
        case TAG_HEADER:
        {
            struct stream_header header;
            [data getBytes:&header length:sizeof(header)];
            
            NSLog(@"%u %u %u", header.data_length, header.data_type, header.timestamp);
            
            requestContentLengthReceived = 0;
            requestContentLength = header.data_length;
            NSUInteger bytesToRead = requestContentLength;
//            if(header.data_length < CHUNK)
//                bytesToRead = requestContentLength;
//            else
//                bytesToRead = CHUNK;
            [asyncSocket readDataToLength:bytesToRead withTimeout:TIMEOUT_NONE tag:header.data_type];
            return;
        }
            
        case TAG_CODEC_DATA:
        {
            struct codec_data codec;
            NSLog(@"size of codec data: %lu", sizeof(codec));
            [data getBytes:&codec length:sizeof(codec)];
            
            break;
        }
            
        case TAG_BITSTREAM:
        {
            int len = data.length;
            char* packet_data = malloc(len);
            [data getBytes:packet_data length:len];
            char* decoded_video_data = (char*)malloc(len);
            len = crypt_aes_decrypt(self.aes_key, packet_data, len, decoded_video_data, len);
            NSLog(@"%@ -> (%i)", data, len);
            _print_data(decoded_video_data, len);
            break;
        }
            
        case TAG_HEARTBEAT:
        {
            requestContentLengthReceived += [data length];
            
            if (requestContentLengthReceived < requestContentLength)
            {
                UInt64 bytesLeft = requestContentLength - requestContentLengthReceived;
                
                NSUInteger bytesToRead = bytesLeft < CHUNK ? (NSUInteger)bytesLeft : CHUNK;
                [asyncSocket readDataToLength:bytesToRead
                                  withTimeout:TIMEOUT_NONE
                                          tag:TAG_HEARTBEAT];
                return;
            }
            break;
        }
            
        default:
            [super socket:sock didReadData:data withTag:tag];
            return;
        
    }
    
    [asyncSocket readDataToLength:128 withTimeout:TIMEOUT_NONE tag:TAG_HEADER];
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    NSLog(@"stream closed: %@", sock);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"disconnected with error: %@", err);
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    NSLog(@"should timeout");
    return 100;
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"partial data (%i)", partialLength);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    [super socket:sock didWriteDataWithTag:tag];
    NSLog(@"write");
}

@end

const char *stringFromData(CFDataRef data, size_t *size) {
    int data_length = CFDataGetLength(data);
    UInt8 data_bytes[data_length];
    CFDataGetBytes(data, CFRangeMake(0, data_length), data_bytes);
    
    _print_data(data_bytes, data_length);
    
    *size = data_length;
    const char *output = malloc(sizeof(data_bytes));
    memcpy(output, data_bytes, data_length);
    return output;
}
