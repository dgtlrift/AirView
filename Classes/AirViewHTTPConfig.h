//
//  AirViewHTTPConfig.h
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import "HTTPConnection.h"
#import "AirViewController.h"

@interface AirViewHTTPConfig : HTTPConfig {
    AirViewController *airplay;
}

- (id)initWithServer:(HTTPServer *)server documentRoot:(NSString *)documentRoot queue:(dispatch_queue_t)q airplay:(AirViewController *)airplay;

@property (nonatomic, readonly) AirViewController *airplay;

@end
