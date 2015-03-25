import processing.video.*;

float FILL_INCREMENT = 0.4;

Capture cam;

// cool modes: ADD, SCREEN, OVERLAY, SOFT_LIGHT, DODGE
int[] blendingModes = {ADD, SCREEN, OVERLAY, SOFT_LIGHT, DODGE};
int blendingMode = blendingModes[0];

float mirrorAlpha = 0;
boolean increasingAlpha = true;
float alphaLimit = 30;

float fillRed = 255;
float fillGreen = 179;
float fillBlue = 119;

float fillRedTarget = 245;
float fillGreenTarget = 185;
float fillBlueTarget = 125;

int glowRadius = 5;
int glowBrightness = 20;

float glitchProbability = 0.05;
int glitchRegionSize = 10;
int glitchRegionSizeSquared = 100;
int glitchType = 0;
int[] glitchTypes = {0, 1};

void setup() {
  size(1280, 720); // default size
  
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
  }      
}

void draw() {
  if (cam.available() == true) {
    cam.read();
  }
  
  updateFill();
  updateMirrorAlpha();
  
  // give me the orange delight
  fill(fillRed, fillGreen, fillBlue);
  rect(0, 0, width, height);
  
  // set the camera alpha and glitch some shit
  cam.loadPixels();
  boolean glitch = false;
  int pixelCount = 0;
  for (int i = 0; i < cam.width; i++) {
    for (int j = 0; j < cam.height; j++) {
       if (pixelCount % glitchRegionSizeSquared == 0) {
         glitch = (random(0.0, 1.0) < glitchProbability);
       }
      
       int loc = i + j * cam.width;
       color pixel = cam.pixels[loc];
       
       if (glitch && glitchType == 0) {
         cam.pixels[loc] = color(pixel <<7 & 0xff, pixel << 4 & 0xaa, pixel & 0xff, max(mirrorAlpha, 0));
         cam.pixels[loc] += random(24000, 150000);
       } else {
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
    
  // blend camera into fill
  blend(cam, 0, 0, width, height, 0, 0, width, height, blendingMode);
  
  // add glow and blur
  glow(glowRadius, glowBrightness);
}

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
    glitchProbability = random(0.0, 0.2);
    glitchRegionSize = int(random(3, 15));
  } else {
    glitchProbability = random(0.0, 0.2);
    glitchRegionSize = int(random(20, 60));  
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

