//
//  particleEye.h
//  TuningEye
//
//  Created by Makoto Okabe on 2015/01/04.
//  Copyright (c) 2015 MAKOTO OKABE. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "micRender.h"

@interface particleEye : GLKViewController<GLKViewControllerDelegate>{

    //Use in viewDidLoad.
    micRender *render;

    //Use in update and draw.
    float *vertBuffer;
    float *micData;
    float *fileData;
    float *sinData;
    float *drawData;
    long drawDataPointer;
    float drawOffsetAmount;
    long soundDataFlames;

    GLuint particleProgram;
    GLuint lineProgram;
    GLuint viewFramebuffer,viewRenderbuffer,vboId;
    EAGLContext *context;

     //Only use in draw.
    float x_Frames;
}

//Switch data.File or mic input.
- (IBAction)switchInput:(id)sender;
@property (strong, nonatomic) IBOutlet UISegmentedControl *switchInput;

//Draw type and size.
@property (strong, nonatomic) IBOutlet UISegmentedControl *lineType;
@property (strong, nonatomic) IBOutlet UIStepper *pointSize;

- (IBAction)pointSizeStepper:(UIStepper *)sender;
@property (strong, nonatomic) IBOutlet UILabel *pointSizeLabel;

//Data offset at draw.
- (IBAction)shiftStepperOne:(id)sender;
@property (strong, nonatomic) IBOutlet UIStepper *shiftStepperOne;

- (IBAction)shiftStepperTen:(UIStepper *)sender;
@property (strong, nonatomic) IBOutlet UIStepper *shiftStepperTen;

@property (strong, nonatomic) IBOutlet UILabel *shiftValueLabel;

- (IBAction)shiftReset:(UIButton *)sender;

@property (strong, nonatomic) IBOutlet UILabel *infoLabel;

@end
