//
//  baseEffectEye.h
//  TuningEye
//
//  Created by Makoto Okabe on 2015/01/05.
//  Copyright (c) 2015 MAKOTO OKABE. All rights reserved.
//
//Log2 9 samples:512 time:0.011610sec rezolution:86.132812
//Log2 10 samples:1024 time:0.023220sec rezolution:43.066406
//Log2 11 samples:2048 time:0.046440sec rezolution:21.533203
//Log2 12 samples:4096 time:0.092880sec rezolution:10.766602
//Log2 13 samples:8192 time:0.185760sec rezolution:5.383301
//Log2 14 samples:16384 time:0.371519sec rezolution:2.691650
//Log2 15 samples:32768 time:0.743039sec rezolution:1.345825
//Log2 16 samples:65536 time:1.486077sec rezolution:0.672913
//Log2 17 samples:131072 time:2.972154sec rezolution:0.336456
//Log2 18 samples:262144 time:5.944308sec rezolution:0.168228
//Log2 19 samples:524288 time:11.888617sec rezolution:0.084114
//Log2 20 samples:1048576 time:23.777233sec rezolution:0.042057
//Log2 21 samples:2097152 time:47.554466sec rezolution:0.021029
//Log2 22 samples:4194304 time:95.108932sec rezolution:0.010514
//Log2 23 samples:8388608 time:190.217865sec rezolution:0.005257
//Log2 24 samples:16777216 time:380.435730sec rezolution:0.002629
//Log2 25 samples:33554432 time:760.871460sec rezolution:0.001314
//Log2 26 samples:67108864 time:1521.742920sec rezolution:0.000657



#import <GLKit/GLKit.h>
#import "micRender.h"
@interface baseEffectEye : GLKViewController<GLKViewControllerDelegate>{
    
    micRender *render;
    
    float x_Frames;
    float *vertBuffer;
    float *soundData;
    long soundDataFlames;
    long shift;
    float speed;
    float shiftFrames;
    
    GLKBaseEffect *baseEffect;
    float vertBufferSizeByte;
    }

- (IBAction)shiftStepper:(UIStepper *)sender;
@property (strong, nonatomic) IBOutlet UIStepper *shiftStepper;
@property (strong, nonatomic) IBOutlet UILabel *shiftLabel;

- (IBAction)newDataJump:(id)sender;

@end
