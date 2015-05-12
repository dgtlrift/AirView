//
//  airtunesd_wrapper.h
//  AirView
//
//  Created by Łukasz Przytuła on 12.05.2015.
//
//

#ifndef __AirView__airtunesd_wrapper__
#define __AirView__airtunesd_wrapper__

#include <stdio.h>
#include <CoreFoundation/CoreFoundation.h>

void loadAirtunesd();
void initAirtunesd();
uint8_t *getChallengeResponse(uint8_t data[]);
uint8_t *decryptAESKey(uint8_t data[]);

#endif /* defined(__AirView__airtunesd_wrapper__) */
