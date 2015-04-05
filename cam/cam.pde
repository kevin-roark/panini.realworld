
// help on removing bg: http://www.learningprocessing.com/examples/chapter-16/example-16-12/

import processing.video.*;

// le webcam
Capture cam;

// Saved background
PImage backgroundImage;
boolean needsBackgroundUpdate = false;

// How different must a pixel be to be a foreground pixel
float bgThreshold = 20;

// cool modes: ADD, SCREEN, OVERLAY, SOFT_LIGHT, DODGE
int[] blendingModes = {ADD, SCREEN, OVERLAY, SOFT_LIGHT, DODGE};
int blendingMode = blendingModes[0];

// alpha changes
float mirrorAlpha = 0;
boolean increasingAlpha = true;
float alphaLimit = 30;

// current fill color
float fillRed = 255;
float fillGreen = 179;
float fillBlue = 119;

// target fill color
float fillRedTarget = 245;
float fillGreenTarget = 185;
float fillBlueTarget = 125;

// transitioning between fill colors
float FILL_INCREMENT = 0.4;

// glowy parameters
int glowRadius = 5;
int glowBrightness = 20;

// glitchy parameters
float glitchProbability = 0.05;
int glitchRegionSize = 10;
int glitchRegionSizeSquared = 100;
int glitchType = 0;
int[] glitchTypes = {0, 1};

/// Processing Functions

void setup() {
  size(displayWidth, displayHeight); // full screen size
  
  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    
    cam = new Capture(this, cameras[1]);
    cam.start();
    
    backgroundImage = createImage(cam.width, cam.height, RGB);
  }      
}

void draw() {
  if (cam.available() == true) {
    cam.read();
    
    if (needsBackgroundUpdate) {
      println("GETTING A NEW BACKGROUND IMAGE");
      backgroundImage = createImage(cam.width, cam.height, RGB);
      backgroundImage.copy(cam, 0,0,cam.width,cam.height, 0,0,cam.width,cam.height);
      backgroundImage.updatePixels(); 
      needsBackgroundUpdate = false;
    }
  }
  
  updateFill();
  updateMirrorAlpha();
  
  // give me the orange delight
  color bgColor = color(fillRed, fillGreen, fillBlue, max(mirrorAlpha, 0));
  fill(fillRed, fillGreen, fillBlue);
  rect(0, 0, width, height);
  
  // load all the pixels 'cause we gobbing them all to remove background
  cam.loadPixels();
  backgroundImage.loadPixels();
  
  // iterate through each camera pixel (for alpha control, glitching, and bg removal)
  boolean glitch = false;
  int pixelCount = 0;
  for (int i = 0; i < cam.width; i++) {
    for (int j = 0; j < cam.height; j++) {
      if (pixelCount % glitchRegionSizeSquared == 0) {
        // glitch occurs in regional chunks, so if at a chunk boundary decide if we should glitch
        glitch = (random(0.0, 1.0) < glitchProbability);
      }
      
      int loc = i + j * cam.width; // 1D pixel loc
      color pixel = cam.pixels[loc]; // foreground
      
      float diff = 1000;
      if (loc < backgroundImage.pixels.length) {
        color bgPixel = backgroundImage.pixels[loc]; // background
        diff = colorDiff(pixel, bgPixel); // foreground <-> background difference
      }
       
      if (glitch && glitchType == 0) {
        cam.pixels[loc] = color(pixel <<7 & 0xff, pixel << 4 & 0xaa, pixel & 0xff, max(mirrorAlpha, 0));
        cam.pixels[loc] += random(24000, 150000);
      }
      else if (diff < bgThreshold) {
        cam.pixels[loc] = bgColor;
      }
      else {
        cam.pixels[loc] = color(red(pixel), green(pixel), blue(pixel), max(mirrorAlpha, 0));
      }
      
      pixelCount += 1;
    }
  }
  
  if (glitchType == 1) {
    int glitchRegions = int(glitchProbability * cam.pixels.length / glitchRegionSizeSquared);
    int halfGlitchRegionSize = int(glitchRegionSize / 2);
    for (int gl = 0; gl < glitchRegions; gl++) {
      int idx = int(random(cam.pixels.length));
      for (int i = idx - halfGlitchRegionSize; i < idx + halfGlitchRegionSize; i++) {
        for (int j = -halfGlitchRegionSize; j < halfGlitchRegionSize; j++) {
          int loc = i + j * cam.width;
          if (loc >= 0 && loc < cam.pixels.length) {
             color pixel = cam.pixels[loc];
             cam.pixels[loc] = color(pixel <<7 & 0xff, pixel << 4 & 0xaa, pixel & 0xff, max(mirrorAlpha, 0));
             cam.pixels[loc] += random(24000, 150000);
          } 
        }
      }
    }
  }
  
  cam.updatePixels();
    
  // blend camera into fill
  blend(cam, 0, 0, width, height, 0, 0, width, height, blendingMode);
  
  // add glow and blur
  glow(glowRadius, glowBrightness);
}

void mousePressed() {
  needsBackgroundUpdate = true;
}

/// Helper functions

void updateMirrorAlpha() {
  float increment = increasingAlpha? random(0.25, 2.5) : random(-2.5, -0.25);
  mirrorAlpha += increment;
  
  if (increasingAlpha && mirrorAlpha > alphaLimit) {
    increasingAlpha = false;
    alphaLimit = random(10, 20); // set the bottom threshold
  }
  else if (!increasingAlpha && mirrorAlpha < alphaLimit) {
    increasingAlpha = true;
    alphaLimit = random(35, 140); // set the top threshold
    
    blendingMode = blendingModes[int(random(blendingModes.length))]; // pick a fresh blending mode
    updateGlowValues();
    updateGlitchValues();
  }  
}

void updateGlowValues() {
  glowRadius = int(random(0, 5));
  glowBrightness = int(random(0, 40)); 
}

void updateGlitchValues() {
  glitchType = glitchTypes[int(random(glitchTypes.length))];
  
  if (glitchType == 0) {
    glitchProbability = random(0.0, 0.14);
    glitchRegionSize = int(random(3, 15));
  } else {
    glitchProbability = random(0.0, 0.06);
    glitchRegionSize = int(random(4, 8));  
  }
  
  glitchRegionSizeSquared = glitchRegionSize * glitchRegionSize;
    
  println("glitch prob: " + glitchProbability);
  println("glitch region size: " + glitchRegionSize);
  println("glitch type: " + glitchType);
}

void updateFill() {
  if (fillRed < fillRedTarget) {
    fillRed += FILL_INCREMENT; 
  } else if (fillRed > fillRedTarget) {
    fillRed -= FILL_INCREMENT; 
  } else {
    fillRedTarget = random(245, 255);  
  }
  
  if (fillGreen < fillGreenTarget) {
    fillGreen += FILL_INCREMENT; 
  } else if (fillGreen > fillGreenTarget) {
    fillGreen -= FILL_INCREMENT; 
  } else {
    fillGreenTarget = random(155, 205);  
  }
  
  if (fillBlue < fillBlueTarget) {
    fillBlue += FILL_INCREMENT; 
  } else if (fillBlue > fillBlueTarget) {
    fillBlue -= FILL_INCREMENT; 
  } else {
    fillBlueTarget = random(90, 150);  
  }
}

float colorDiff(color a, color b) {
  float r1 = red(a);
  float g1 = green(a);
  float b1 = blue(a);
  float r2 = red(b);
  float g2 = green(b);
  float b2 = blue(b);
  return dist(r1, g1, b1, r2, g2, b2);
}

// Following from http://www.openprocessing.org/sketch/5286

void glow(int r, int b) {
  loadPixels();
  blur(1); // just adding a little smoothness ...
  int[] px = new int[pixels.length];
  arrayCopy(pixels, px);
  blur(r);
  mix(px, b);
  updatePixels();
}
 
void blur(int dd) {
   int[] px = new int[pixels.length];
   for(int d=1<<--dd; d>0; d>>=1) { 
      for(int x=0;x<width;x++) for(int y=0;y<height;y++) {
        int p = y*width + x;
        int e = x >= width-d ? 0 : d;
        int w = x >= d ? -d : 0;
        int n = y >= d ? -width*d : 0;
        int s = y >= (height-d) ? 0 : width*d;
        int r = ( r(pixels[p+w]) + r(pixels[p+e]) + r(pixels[p+n]) + r(pixels[p+s]) ) >> 2;
        int g = ( g(pixels[p+w]) + g(pixels[p+e]) + g(pixels[p+n]) + g(pixels[p+s]) ) >> 2;
        int b = ( b(pixels[p+w]) + b(pixels[p+e]) + b(pixels[p+n]) + b(pixels[p+s]) ) >> 2;
        px[p] = 0xff000000 + (r<<16) | (g<<8) | b;
      }
      arrayCopy(px,pixels);
   }
}
 
void mix(int[] px, int n) {
  for(int i=0; i< pixels.length; i++) {
    int r = (r(pixels[i]) >> 1)  + (r(px[i]) >> 1) + (r(pixels[i]) >> n)  - (r(px[i]) >> n) ;
    int g = (g(pixels[i]) >> 1)  + (g(px[i]) >> 1) + (g(pixels[i]) >> n)  - (g(px[i]) >> n) ;
    int b = (b(pixels[i]) >> 1)  + (b(px[i]) >> 1) + (b(pixels[i]) >> n)  - (b(px[i]) >> n) ;
    pixels[i] =  0xff000000 | (r<<16) | (g<<8) | b;
  }
}
 
int r(color c) {return (c >> 16) & 255; }
int g(color c) {return (c >> 8) & 255;}
int b(color c) {return c & 255; }

