//
//  baseEffectEye.m
//  TuningEye
//
//  Created by Makoto Okabe on 2015/01/05.
//  Copyright (c) 2015 MAKOTO OKABE. All rights reserved.
//

#import "baseEffectEye.h"

@implementation baseEffectEye

- (IBAction)shiftStepper:(UIStepper *)sender{
    shiftFrames = _shiftStepper.value;
    _shiftLabel.text = [NSString stringWithFormat:@"%f",shiftFrames];
    
}

- (float *)loadSoundData:(long *)retDataFlames{
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"441HzViolin"  ofType:@"pcm"];
    NSData *readData = [[NSData alloc] initWithContentsOfFile:filepath];
    long dataSizeByte = [readData length];
    *retDataFlames = dataSizeByte / sizeof(float);
    float *rdata = malloc(dataSizeByte);
    memcpy(rdata, [readData bytes], dataSizeByte);
    
    return rdata;
}

- (float *)generateSineWave_SampleRate:(float)sampleRate frequency:(float)frequency LengthFrames:(float)LengthFrames{
    float *sinData = malloc(LengthFrames * sizeof(float));
    for (long i = 0; i<LengthFrames; i++) {
        sinData[i] = sinf(2. * M_PI * frequency * i / sampleRate);
    }
    return sinData;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    float sampleRate = 44100.0;
    float fps = 60;
    
    soundDataFlames = sampleRate * 5 * 60;

    x_Frames = 2048;

    shiftFrames = 700;
    _shiftLabel.text = [NSString stringWithFormat:@"%f",shiftFrames];
    _shiftStepper.minimumValue = 0;
    _shiftStepper.maximumValue = 100000;
    _shiftStepper.value = shiftFrames;
    _shiftStepper.stepValue = 0.5;
    
    
    //Datas for one flame. vertBuffer[Even]:x-axis [Odd]:y-axis
    float vertBufferLength = x_Frames * 2.0;
    vertBufferSizeByte = vertBufferLength * sizeof(float);
    vertBuffer = calloc(vertBufferLength, sizeof(float));
    
    for (int i = 0; i<x_Frames; i++) {
        //X-axisdata . Left side -1.0, Right side +1.0.
        vertBuffer[2 * i + 0] = -1.0 + 2 / x_Frames * i;
    }
    
    //Get data.
//    soundData = [self generateSineWave_SampleRate:sampleRate frequency:441.0 LengthFrames:soundDataFlames];
//    soundData = [self loadSoundData:&soundDataFlames];
    soundData = calloc(soundDataFlames, sizeof(float));
    render = [[micRender alloc] init_soundBuffer:soundData bufferLength:soundDataFlames mChannelsPerFrame:1];
    
    
//    micrender = [[com_amakusaweb_micInputRender alloc] initAndStart_SampleRate:sampleRate chanks:1 maxFramesPerSlice:maxFramesPerSlice micBuffa:soundData];
    
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView *)self.view;
    [view setContext:context];
    [self setPreferredFramesPerSecond:fps];
    [self setDelegate:self];
    
    [EAGLContext setCurrentContext:context];
    [view setDrawableDepthFormat:24];
    
    baseEffect = [[GLKBaseEffect alloc] init];
    baseEffect.useConstantColor = GL_TRUE;
    baseEffect.constantColor = GLKVector4Make(0.7f, 1.0f, 0.6f, 1.0f);
    glLineWidth(2.0);
    
    GLuint vertBufferID;
    glGenBuffers(1, &vertBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, vertBufferID);
}

//Draw with BaseEffect
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    
    [baseEffect prepareToDraw];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBufferData(GL_ARRAY_BUFFER,vertBufferSizeByte, vertBuffer,GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE,2 * sizeof(float), 0);
    glDrawArrays(GL_LINE_STRIP, 0, x_Frames);
}

- (void)glkViewControllerUpdate:(GLKViewController *)controller{
    
    for (int i = 0; i<x_Frames; i++) {
        //Y-axis data
        vertBuffer[2 * i + 1] = soundData[i+shift];
    }
    shift += shiftFrames;
    
    if (shift > soundDataFlames) {
        shift = 0;
    }
}

- (IBAction)newDataJump:(id)sender {
    shift = render.currentInputIndex;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated{
    free(vertBuffer);
    free(soundData);
}
@end
