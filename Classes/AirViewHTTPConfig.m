//
//  AirViewHTTPConfig.m
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import "AirViewHTTPConfig.h"

@implementation AirViewHTTPConfig

@synthesize airplay;

- (instancetype)initWithServer:(HTTPServer *)aServer
                  documentRoot:(NSString *)aDocumentRoot
                         queue:(dispatch_queue_t)q
                       airplay:(AirViewController *)airplayController {
    self = [super init];
    if (self)
    {
        server = aServer;
        
        documentRoot = [aDocumentRoot stringByStandardizingPath];
        if ([documentRoot hasSuffix:@"/"])
        {
            documentRoot = [documentRoot stringByAppendingString:@"/"];
        }
        
        if (q)
        {
            dispatch_retain(q);
            queue = q;
        }
        
        airplay = airplayController;
    }
    return self;
}

@end
