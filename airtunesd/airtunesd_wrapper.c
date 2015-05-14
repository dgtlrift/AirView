//
//  airtunesd_wrapper.c
//  AirView
//
//  Created by Łukasz Przytuła on 12.05.2015.
//
//

#include "airtunesd_wrapper.h"
#include <mach-o/dyld.h>
#include <dlfcn.h>

typedef int (*initFunction)(int, int);
typedef int (*challengeFunction)(int, int, int, int, int, int, int*, int*);
typedef int (*decryptFunction)(int, int, int, int, int*);

int retrieveAirtunesdIndex();
void initAirtunesd();

initFunction init;
challengeFunction challenge;
decryptFunction decrypt;

void *sap_info;

char *aitrtunesdPath() {
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    CFStringRef filename = CFStringCreateWithCString(kCFAllocatorDefault, "airtunesd", kCFStringEncodingASCII);
    CFStringRef empty_string = CFStringCreateWithCString(kCFAllocatorDefault, "", kCFStringEncodingASCII);
    CFURLRef pathURL = CFBundleCopyResourceURL(mainBundle, filename, empty_string, empty_string);
    CFStringRef str = CFURLCopyFileSystemPath(pathURL, kCFURLPOSIXPathStyle);
    CFRelease(pathURL);
    char path[PATH_MAX];
    CFStringGetCString(str, path, FILENAME_MAX, kCFStringEncodingASCII);
    CFRelease(str);
    fprintf(stderr, "%s", path);
    return path;
}

void loadAirtunesd() {
//    char *lib_path = aitrtunesdPath();
//    void *lib = dlopen(lib_path, RTLD_LAZY);
//
//    if (!lib) {
//        printf("%s\n", dlerror());
//    }
    
    int airtunesd_index = retrieveAirtunesdIndex();
    printf("airtunesd index %i\n", airtunesd_index);
    
    const struct mach_header *airtunesd_header = _dyld_get_image_header(airtunesd_index);
    printf("%p\n", airtunesd_header);
    
    int init_offset = 0x435B4 - 0x1000;
    init = (initFunction)((int)airtunesd_header + init_offset);
    
    int challenge_offset = 0xEB00C - 0x1000;
    challenge = (challengeFunction)((int)airtunesd_header + challenge_offset);
    
    int decrypt_offset = 0xEB964 - 0x1000;
    decrypt = (decryptFunction)((int)airtunesd_header + decrypt_offset);
}

void initAirtunesd() {
    sap_info = malloc(4);
    
    int init_result = init(&sap_info, 0x123);
    printf("init result: %i\n", init_result);
}

uint8_t *getChallengeResponse(uint8_t data[]) {    
    int type = data[4];
    
    void *out_data = malloc(4);
    int out_length = 0;
    int stage = 0;
    if (data[6] > 1) {
        stage = 1;
    } else {
        initAirtunesd();
    }
    
    int challenge_result = challenge(type, 0x123, sap_info, data, 0xABC, &out_data, &out_length, &stage);
    printf("challenge result: %i stage: %i\n", challenge_result, stage);
    
    printf("\n\noutput:\n");
    for (int x = 0; x < out_length; ++x) {
        unsigned char c = ((char*)out_data)[x] ;
        printf ("%02x ", c);
    }
    printf("\n\n");
    
    return out_data;
}

uint8_t *decryptAESKey(uint8_t data[]) {
    void *out_key = malloc(4);
    int out_key_length = 0;
    int decrypt_result = decrypt(sap_info, data, 72, &out_key, &out_key_length);
    printf("decrypt result: %i\n", decrypt_result);
    
    printf("\n\naes:\n");
    for (int x = 0; x < out_key_length; ++x) {
        unsigned char c = ((char*)out_key)[x] ;
        printf ("%02x ", c);
    }
    printf("\n\n");
    
    return out_key;
}

int retrieveAirtunesdIndex() {
    int appLibraryIndex = -1;
    for (int i = 0; i < _dyld_image_count(); ++i) {
        const char *imageName = _dyld_get_image_name(i);
        if (strstr(imageName, "airtunesd")) {
            appLibraryIndex = i;
            break;
        }
    }
    return appLibraryIndex;
}
