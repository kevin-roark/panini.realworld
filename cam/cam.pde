
// help on removing bg: http://www.learningprocessing.com/examples/chapter-16/example-16-12/

import processing.video.*;

// le webcam
Capture cam;

// Saved background
PImage backgroundImage;
boolean needsBackgroundUpdate = false;

// How different must a pixel be to be a foreground pixel
float bgThreshold = 20;

// cool modes: ADD, OVERLAY
int[] blendingModes = {ADD, OVERLAY};
int blendingMode = blendingModes[1];

// alpha changes
float mirrorAlpha = 0;
boolean increasingAlpha = true;
float alphaLimit = 150;

// current fill color
float fillRed = 255;
float fillGreen = 179;
float fillBlue = 119;

// target fill color and palette definitions
// current palettes: orange-red, green, blue, pink, teal, purple, gray, yellow
int currentColorPaletteIndex = 0;
float[] fillRedTargetMins = {245, 50, 20, 230, 75, 122, 50, 230};
float[] fillRedTargetMaxes = {255, 90, 70, 255, 120, 165, 80, 255};
float[] fillGreenTargetMins = {155, 225, 145, 15, 235, 40, 50, 208};
float[] fillGreenTargetMaxes = {205, 255, 195, 60, 255, 82, 80, 250};
float[] fillBlueTargetMins = {95, 58, 230, 125, 235, 190, 50, 19};
float[] fillBlueTargetMaxes = {140, 105, 255, 173, 235, 237, 80, 65};
float fillRedTarget = 245;
float fillGreenTarget = 185;
float fillBlueTarget = 125;

// transitioning between fill colors
int timeBetweenPalettes = int(1000 * 60 * 5); // last thing the minute count
int lastPaletteSwitchTime = 0;
int minFramesToReachFillTarget = 30;
int maxFramesToReachFillTarget = 90;
int framesToTransitionPalettes = 120;
int framesToReachFillTarget = 10;
int incrementalFillCount = 0;
float fillRedIncrement, fillGreenIncrement, fillBlueIncrement;

// glowy parameters
int glowRadius = 5;
int glowBrightness = 20;

// glitchy parameters
float glitchProbability = 0.05;
int glitchRegionSize = 10;
int glitchRegionSizeSquared = 100;
int glitchType = 0;
int[] glitchTypes = {0, 1};

int preferredCameraIndex = 1; // 1 is facetime, 4 is full hd 960 x 540 at 15 fps

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
     // println(cameras[i]);
    }

    cam = new Capture(this, cameras[preferredCameraIndex]);
    cam.start();

    backgroundImage = createImage(cam.width, cam.height, RGB);

    calculateFillIncrements();
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

/// Mirror

void updateMirrorAlpha() {
  float increment = increasingAlpha? random(0.25, 2.5) : random(-2.5, -0.25);
  mirrorAlpha += increment;

  if (increasingAlpha && mirrorAlpha > alphaLimit) {
    increasingAlpha = false;
    alphaLimit = random(10, 20); // set the bottom threshold
  }
  else if (!increasingAlpha && mirrorAlpha < alphaLimit) {
    increasingAlpha = true;
    alphaLimit = random(75, 225); // set the top threshold

    blendingMode = blendingModes[int(random(blendingModes.length))]; // pick a fresh blending mode
    updateGlowValues();
    updateGlitchValues();
  }
}

void updateGlowValues() {
  glowRadius = int(random(0, 5));
  glowBrightness = int(random(0, 40));
}

/// Color

void updateFill() {
  // get a fresh target if necessary
  if (incrementalFillCount == framesToReachFillTarget) {
    if (millis() - lastPaletteSwitchTime > timeBetweenPalettes) {
      lastPaletteSwitchTime = millis();

      int newPalette = currentColorPaletteIndex;
      while (newPalette == currentColorPaletteIndex) {
        newPalette = int(random(0, fillRedTargetMins.length - 0.01)); // pick a new color palette
      }
      currentColorPaletteIndex = newPalette;
      println("new color palette: " + currentColorPaletteIndex);

      framesToReachFillTarget = framesToTransitionPalettes;
    }
    else {
      framesToReachFillTarget = (int) random(minFramesToReachFillTarget, maxFramesToReachFillTarget);
    }

    fillRedTarget = random(fillRedTargetMins[currentColorPaletteIndex], fillRedTargetMaxes[currentColorPaletteIndex]);
    fillGreenTarget = random(fillGreenTargetMins[currentColorPaletteIndex], fillGreenTargetMaxes[currentColorPaletteIndex]);
    fillBlueTarget = random(fillBlueTargetMins[currentColorPaletteIndex], fillBlueTargetMaxes[currentColorPaletteIndex]);

    println("new fill target: " + fillRedTarget + "," + fillGreenTarget + "," + fillBlueTarget);

    incrementalFillCount = 0;
    calculateFillIncrements();

    println("i will reach it in " + framesToReachFillTarget + " frames");
  }

  fillRed += fillRedIncrement;
  fillGreen += fillGreenIncrement;
  fillBlue += fillBlueIncrement;

  incrementalFillCount += 1;
}

void calculateFillIncrements() {
  fillRedIncrement = (fillRedTarget - fillRed) / framesToReachFillTarget;
  fillGreenIncrement = (fillGreenTarget - fillGreen) / framesToReachFillTarget;
  fillBlueIncrement = (fillBlueTarget - fillBlue) / framesToReachFillTarget;
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

/// Glitch

void updateGlitchValues() {
  glitchType = glitchTypes[int(random(glitchTypes.length))];

  if (glitchType == 0) {
    glitchProbability = random(0.0, 0.09);
    glitchRegionSize = int(random(3, 15));
  } else {
    glitchProbability = random(0.0, 0.03);
    glitchRegionSize = int(random(4, 8));
  }

  glitchRegionSizeSquared = glitchRegionSize * glitchRegionSize;

  println("glitch prob: " + glitchProbability);
  println("glitch region size: " + glitchRegionSize);
  println("glitch type: " + glitchType);
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
