//
//  particleEye.m
//  TuningEye
//
//  Created by Makoto Okabe on 2015/01/04.
//  Copyright (c) 2015 MAKOTO OKABE. All rights reserved.
//
// setupGL(),glkViewControllerUpdate(),glkView(),setUniform() are based on OpenGLES_ProgrammingGuide.
// https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/OpenGLES_ProgrammingGuide/DrawingWithOpenGLES/DrawingWithOpenGLES.html

#import "particleEye.h"

@implementation particleEye

#pragma mark - Initialize
- (void)viewDidLoad {
    [super viewDidLoad];
    float sampleRate = 44100.0;
    float videoRate = 60;
    _infoLabel.text = @"";
    
    //Shif value for display sound data.
    //If DefaultShiftFrames = sampleRate / input frequency * N, graph is look like not move.(N is an integer.)
    //e.g. sampleRate = 44100.0, N = 7,frequency of input sound = 441Hz.
    drawDataPointer = 0;
    drawOffsetAmount = sampleRate / 441 * 7 + 1;
    _shiftValueLabel.text = [NSString stringWithFormat:@"%f",drawOffsetAmount];
    
    _shiftStepperOne.minimumValue = 0;
    _shiftStepperOne.maximumValue = 1000;
    _shiftStepperOne.value = drawOffsetAmount;
    _shiftStepperOne.stepValue = 1;
    
    _shiftStepperTen.minimumValue = 0;
    _shiftStepperTen.maximumValue = 1000;
    _shiftStepperTen.value = drawOffsetAmount;
    _shiftStepperTen.stepValue = 10;
    
    //Default pointsize of draw line.
    _pointSize.minimumValue = 0;
    _pointSize.maximumValue = 100;
    _pointSize.stepValue = 1;
    _pointSize.value = 10.0;
    
    //Size of soundData.
    soundDataFlames = sampleRate * 60;
    
    //Input data Frames for display.
    x_Frames = 512;
    
    //Datas for one flame. vertBuffer[Even]:x-axis [Odd]:y-axis
    float vertBufferLength = x_Frames * 2.0;
    vertBuffer = calloc(vertBufferLength, sizeof(float));
    
    for (int i = 0; i<x_Frames; i++) {
        //X-axisdata . Left side -1.0, Right side +1.0.
        vertBuffer[2 * i + 0] = -1.0 + 2 / x_Frames * i;
    }
    
    micData = calloc(soundDataFlames, sizeof(float));
    fileData = calloc(soundDataFlames, sizeof(float));
    sinData = calloc(soundDataFlames, sizeof(float));
    
    // Set up for input datas.
    //Mic input
    render = [[micRender alloc] init_soundBuffer:micData bufferLength:soundDataFlames mChannelsPerFrame:1];
    
    //Data from file.
    [self loadSoundDatafromFile:fileData];
    
    //Sin wave generator.
    [self genSinData:sinData length:soundDataFlames frequency:441.0 sampleRate:44100.0];
    
    //Set default input data.
    drawData = sinData;
    _switchInput.selectedSegmentIndex = 2;
    
    [self setupGL:videoRate];
}
- (void)setupGL:(float)videoFrameRate{
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView *)self.view;
    [view setContext:context];
    [view setDrawableDepthFormat:GLKViewDrawableDepthFormat24];
    
    [self setPreferredFramesPerSecond:videoFrameRate];
    
    [self setDelegate:self];
    
    [EAGLContext setCurrentContext:context];
    
    //Load vertexShader and compile.
    GLuint vs;
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *vertexSourceFile = [bundle pathForResource:@"particleEye" ofType:@"vsh"];
    const GLchar *vertexSourceText = (GLchar *)[[NSString stringWithContentsOfFile:vertexSourceFile encoding:NSUTF8StringEncoding error:nil] UTF8String];
    vs = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vs, 1, &vertexSourceText, NULL);
    glCompileShader(vs);
    
    GLint LogLength;
    glGetShaderiv(vs, GL_INFO_LOG_LENGTH, &LogLength);
    if (LogLength > 0) {
        GLchar *log = (GLchar *)malloc(LogLength);
        glGetShaderInfoLog(vs, LogLength, &LogLength, log);
        NSLog(@"vertShader compile log:\n%s",log);
        free(log);
    }
    
    //Load fragmentShader and compile for particle.
    GLuint fs;
    NSString *fragmentSourceFile = [bundle pathForResource:@"particleEye" ofType:@"fsh"];
    const GLchar *fragmentSourceText = (GLchar *)[[NSString stringWithContentsOfFile:fragmentSourceFile encoding:NSUTF8StringEncoding error:nil] UTF8String];
    fs = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fs, 1, &fragmentSourceText, NULL);
    glCompileShader(fs);
    
    glGetShaderiv(fs, GL_INFO_LOG_LENGTH, &LogLength);
    if (LogLength > 0) {
        GLchar *log = (GLchar *)malloc(LogLength);
        glGetShaderInfoLog(fs, LogLength, &LogLength, log);
        NSLog(@"fragShader compile log:\n%s",log);
        free(log);
    }
    
    //Load fragmentShader and compile for line.
    GLuint fsl;
    NSString *fragmentSourceFileLine = [bundle pathForResource:@"particleEyeLine" ofType:@"fsh"];
    const GLchar *fragmentSourceTextLine = (GLchar *)[[NSString stringWithContentsOfFile:fragmentSourceFileLine encoding:NSUTF8StringEncoding error:nil] UTF8String];
    fsl = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fsl, 1, &fragmentSourceTextLine, NULL);
    glCompileShader(fsl);
    
    glGetShaderiv(fs, GL_INFO_LOG_LENGTH, &LogLength);
    if (LogLength > 0) {
        GLchar *log = (GLchar *)malloc(LogLength);
        glGetShaderInfoLog(fs, LogLength, &LogLength, log);
        NSLog(@"fragShader compile log:\n%s",log);
        free(log);
    }
    
    //Load texture.
    NSString *textureImageFile = [bundle pathForResource:@"Particle" ofType:@"png"];
    NSError *error;
    GLKTextureInfo *texture = [GLKTextureLoader textureWithContentsOfFile:textureImageFile options:nil error:&error];
    if(error){
        NSLog(@"faild to make complete texture object");
    }
    glBindTexture(GL_TEXTURE_2D,texture.name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    
    //Program for draw with particle.
    particleProgram = glCreateProgram();
    glAttachShader(particleProgram, vs);
    glAttachShader(particleProgram, fs);
    glLinkProgram(particleProgram);
    glGetProgramiv(particleProgram, GL_INFO_LOG_LENGTH, &LogLength);
    if (LogLength > 0) {
        GLchar *log = (GLchar *)malloc(LogLength);
        glGetProgramInfoLog(particleProgram, LogLength, &LogLength, log);
        NSLog(@"linker log particle:\n%s",log);
        free(log);
    }
    
    //Program for draw with line.
    lineProgram = glCreateProgram();
    glAttachShader(lineProgram, vs);
    glAttachShader(lineProgram, fsl);
    glLinkProgram(lineProgram);
    glGetProgramiv(lineProgram, GL_INFO_LOG_LENGTH, &LogLength);
    if (LogLength > 0) {
        GLchar *log = (GLchar *)malloc(LogLength);
        glGetProgramInfoLog(lineProgram, LogLength, &LogLength, log);
        NSLog(@"linker log line:\n%s",log);
        free(log);
    }
    
    //Set particle blend mode.
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    //Set texture.
    glActiveTexture(GL_TEXTURE0);
    glEnable(GL_TEXTURE_2D);
    glUniform1i(texture.name, 0);
    
    //Set point size.
    _pointSizeLabel.text = [NSString stringWithFormat:@"%f",_pointSize.value];
    
    //Set point size to uniform variable.
    [self setUniform];
    
    //Generate data object.
    glGenBuffers(1, &vboId);
    
    //Default program.
    glUseProgram(lineProgram);
}
- (void)setUniform{
    //particle
    GLint location;
    location = glGetUniformLocation(particleProgram, "pointSize");
    glUseProgram(particleProgram);
    glUniform1f(location,_pointSize.value * 2.0f);
    
    //line
    glLineWidth(_pointSize.value);
}
- (float)loadSoundDatafromFile:(float *)pData{
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"441HzViolin"  ofType:@"pcm"];
    NSData *readData = [[NSData alloc] initWithContentsOfFile:filepath];
    long dataSizeByte = [readData length];
    long flames = dataSizeByte / sizeof(float);
    
    long repeats = soundDataFlames / flames;
    
    for (long i = 0; i<repeats; i++) {
        memcpy(pData+(i*flames), [readData bytes], dataSizeByte);
    }
    
    return flames;
}
- (void)genSinData:(float *)data length:(long)length frequency:(float)frequency sampleRate:(float)sampleRate {
    for (long i = 0; i<length; i++) {
        sinData[i] = 0.3 * sinf(2. * M_PI * frequency * i / sampleRate);
    }}

#pragma mark - update
- (void)glkViewControllerUpdate:(GLKViewController *)controller{
    //Update Y-axis data.
    for (int i = 0; i<x_Frames; i++) {
        vertBuffer[2 * i + 1] = drawData[i+drawDataPointer] * 2;
    }
    if(_switchInput.selectedSegmentIndex == 0) {
        drawDataPointer = render.currentInputIndex;
    }
    drawDataPointer += drawOffsetAmount;
    if (drawDataPointer > soundDataFlames) {
        drawDataPointer = 0;
        NSLog(@"%ld",(long)self.framesPerSecond);
        _infoLabel.text = @"refresh buffer";
        [NSTimer scheduledTimerWithTimeInterval:1.0f repeats:false block:^(NSTimer*timer){self.infoLabel.text =@"";}];
    }
}
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindBuffer(GL_ARRAY_BUFFER, vboId);
    glBufferData(GL_ARRAY_BUFFER, x_Frames * 2 * sizeof(float), vertBuffer, GL_DYNAMIC_DRAW);
    
    glViewport(0, 0, view.bounds.size.width * 2, view.bounds.size.height * 2);
    
    GLint location = 0;
    glVertexAttribPointer(location, 2, GL_FLOAT, GL_FALSE,0, 0);
    if (_lineType.selectedSegmentIndex == 0) {
        //line
        glUseProgram(lineProgram);
        location = glGetAttribLocation(lineProgram, "inVertex");
        glEnableVertexAttribArray(location);
        glDrawArrays(GL_LINE_STRIP, 0, x_Frames);
    }else if (_lineType.selectedSegmentIndex == 1){
        //particle
        glUseProgram(particleProgram);
        location = glGetAttribLocation(particleProgram, "inVertex");
        glEnableVertexAttribArray(location);
        glDrawArrays(GL_POINTS, 0, x_Frames);
    }
}

#pragma mark - UI component action
- (IBAction)switchInput:(id)sender {
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    switch (seg.selectedSegmentIndex) {
        case 0:
            //micData
            drawData = micData;
            drawDataPointer = render.currentInputIndex;
            drawOffsetAmount = 0;
            break;
            
        case 1:
            //fileData
            drawData = fileData;
            drawDataPointer = 0;
            drawOffsetAmount = 701;
            
            break;
            
        case 2:
            //sinData
            drawData = sinData;
            drawDataPointer = 0;
            drawOffsetAmount = 701;
            break;
            
        default:
            break;
    }
    _shiftValueLabel.text = [NSString stringWithFormat:@"%.2f",drawOffsetAmount];
}
- (IBAction)shiftStepperOne:(id)sender {
    //Sync stepper value.
    _shiftStepperTen.value = _shiftStepperOne.value;
    drawOffsetAmount = _shiftStepperOne.value;
    _shiftValueLabel.text = [NSString stringWithFormat:@"%.2f",drawOffsetAmount];
}
- (IBAction)shiftStepperTen:(UIStepper *)sender {
    //Sync stepper value.
    _shiftStepperOne.value = _shiftStepperTen.value;
    drawOffsetAmount = _shiftStepperTen.value;
    _shiftValueLabel.text = [NSString stringWithFormat:@"%.2f",drawOffsetAmount];
}
- (IBAction)shiftReset:(UIButton *)sender {
    _shiftStepperOne.value = drawOffsetAmount;
    _shiftValueLabel.text = [NSString stringWithFormat:@"%.2f",drawOffsetAmount];
}
- (IBAction)pointSizeStepper:(UIStepper *)sender {
    //uniform
    [self setUniform];
    _pointSizeLabel.text = [NSString stringWithFormat:@"%f",_pointSize.value];
}

#pragma mark - 
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillDisappear:(BOOL)animated{
    [render stop];
    free(vertBuffer);
    free(micData);
    free(fileData);
    free(sinData);
}
@end
