//
//  micRender.m
//  TuningEye
//
//  Created by Makoto Okabe on 2015/01/06.
//  Copyright (c) 2015 MAKOTO OKABE. All rights reserved.
//
//Log2	9	samples:512		time:0.011610sec	FFTrezolution:86.132812
//Log2	10	samples:1024		time:0.023220sec	FFTrezolution:43.066406
//Log2	11	samples:2048		time:0.046440sec	FFTrezolution:21.533203
//Log2	12	samples:4096		time:0.092880sec	FFTrezolution:10.766602
//Log2	13	samples:8192		time:0.185760sec	FFTrezolution:5.383301
//Log2	14	samples:16384		time:0.371519sec	FFTrezolution:2.691650
//Log2	15	samples:32768		time:0.743039sec	FFTrezolution:1.345825
//Log2	16	samples:65536		time:1.486077sec	FFTrezolution:0.672913
//Log2	17	samples:131072		time:2.972154sec	FFTrezolution:0.336456
//Log2	18	samples:262144		time:5.944308sec	FFTrezolution:0.168228
//Log2	19	samples:524288		time:11.888617sec	FFTrezolution:0.084114
//Log2	20	samples:1048576		time:23.777233sec	FFTrezolution:0.042057
//Log2	21	samples:2097152		time:47.554466sec	FFTrezolution:0.021029
//Log2	22	samples:4194304		time:95.108932sec	FFTrezolution:0.010514
//Log2	23	samples:8388608		time:190.217865sec	FFTrezolution:0.005257
//Log2	24	samples:16777216	time:380.435730sec	FFTrezolution:0.002629
//Log2	25	samples:33554432	time:760.871460sec	FFTrezolution:0.001314
//Log2	26	samples:67108864	time:1521.742920sec	FFTrezolution:0.000657


#import "micRender.h"

@implementation micRender

static OSStatus renderer(void *inRef,
                         AudioUnitRenderActionFlags *ioActionFlags,
                         const AudioTimeStamp *inTimeStamp,
                         UInt32 inBusNumber,
                         UInt32 inNumberFrames,
                         AudioBufferList *ioData){
    
    micRender *bridgedMicRender = (__bridge micRender *)inRef;
    
    AudioUnitRender(bridgedMicRender->_remoteIOUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    
    //Buffering
    for (int i = 0; i<bridgedMicRender->_channels; i++) {
        Float32 *input = (Float32 *)ioData->mBuffers[i].mData;

        //Set input data to self.buffer, and set new index for next data.
        memcpy(bridgedMicRender->_buffer + bridgedMicRender.currentInputIndex, input, inNumberFrames * sizeof(float));
        bridgedMicRender.currentInputIndex += inNumberFrames;
        if(bridgedMicRender.currentInputIndex > bridgedMicRender->bufferLength){
            bridgedMicRender.currentInputIndex = 0;
        }
        
        //Reset memory for output to zero.
        memset(input, 0, inNumberFrames * sizeof(Float32));
    }
    
    return noErr;
}

- (instancetype)init_soundBuffer:(float *)inBuffer bufferLength:(long)inLength mChannelsPerFrame:(UInt32)channels {
    self = [super init];
    if (self) {
	//ioData channels.
        _channels = channels;

        _buffer = inBuffer;
        bufferLength = inLength;

        _currentInputIndex = 0;
        
        AudioComponentDescription acd;
        acd.componentType = kAudioUnitType_Output;
        acd.componentSubType = kAudioUnitSubType_RemoteIO;
        acd.componentManufacturer = kAudioUnitManufacturer_Apple;
        acd.componentFlags = 0;
        acd.componentFlagsMask = 0;
        
        AudioComponent ac = AudioComponentFindNext(NULL, &acd);
        AudioComponentInstanceNew(ac, &_remoteIOUnit);
        
        AURenderCallbackStruct callbackStruct;
        callbackStruct.inputProc = renderer;
        callbackStruct.inputProcRefCon = (__bridge void*)self;
        
        AudioUnitSetProperty(_remoteIOUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, sizeof(AURenderCallbackStruct));
        
        AudioStreamBasicDescription asbd;
        asbd.mSampleRate = 44200.0;
        asbd.mFormatID = kAudioFormatLinearPCM;
        asbd.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
        asbd.mChannelsPerFrame = channels;
        asbd.mBytesPerPacket = sizeof(SInt32);
        asbd.mBytesPerFrame = sizeof(SInt32);
        asbd.mFramesPerPacket = 1;
        asbd.mBitsPerChannel = 8 * sizeof(SInt32);
        asbd.mReserved = 0;
        
        AudioUnitSetProperty(_remoteIOUnit,
                             kAudioUnitProperty_StreamFormat,
                             kAudioUnitScope_Output,
                             0,
                             &asbd,
                             sizeof(asbd));
        
        UInt32 flag = 1;
        AudioUnitSetProperty(_remoteIOUnit,
                             kAudioOutputUnitProperty_EnableIO,
                             kAudioUnitScope_Input,
                             1,
                             &flag,
                             sizeof(UInt32));
        
        AudioUnitInitialize(_remoteIOUnit);
        
        UInt32 propSize = sizeof(Float64);
        Float64 samplerate;
        AudioUnitGetProperty(_remoteIOUnit, kAudioUnitProperty_SampleRate, kAudioUnitScope_Output, 0, &samplerate, &propSize);
        
        NSLog(@"micRender %f",samplerate);
        
        AudioOutputUnitStart(_remoteIOUnit);
    }
    return self;
}

- (void)stop{
    AudioOutputUnitStop(_remoteIOUnit);
    AudioUnitUninitialize(_remoteIOUnit);
    AudioComponentInstanceDispose(_remoteIOUnit);
    _remoteIOUnit = NULL;
}

@end
