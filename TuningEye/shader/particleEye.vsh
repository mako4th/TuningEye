//
//  particleEye.vsh
//  TuningEye
//
//  Created by Makoto Okabe on 2015/01/04.
//  Copyright (c) 2015 MAKOTO OKABE. All rights reserved.
//


attribute vec4 inVertex;
uniform float pointSize;
varying lowp vec4 color;

void main()
{
    gl_Position = inVertex;
    gl_PointSize = pointSize;
    color = vec4(0.5,0.75,0.85,1.0);
}
