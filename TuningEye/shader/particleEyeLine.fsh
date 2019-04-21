//
//  particleEyeLine.fsh
//  TuningEye
//
//  Created by Makoto Okabe on 2015/01/04.
//  Copyright (c) 2015 MAKOTO OKABE. All rights reserved.
//

uniform sampler2D texture;
varying lowp vec4 color;

void main()
{
    gl_FragColor = color;
}
