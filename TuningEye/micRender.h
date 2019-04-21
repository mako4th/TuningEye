//
//  micRender.h
//  TuningEye
//
//  Created by Makoto Okabe on 2015/01/06.
//  Copyright (c) 2015 MAKOTO OKABE. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface micRender : NSObject{
    AudioUnit _remoteIOUnit;
    UInt32 _channels;
    
    float *_buffer;
    long bufferLength;
}

- (instancetype)init_soundBuffer:(float *)inBuffer bufferLength:(long)inLength mChannelsPerFrame:(UInt32)channels;

- (void)stop;

@property long currentInputIndex;
@end
