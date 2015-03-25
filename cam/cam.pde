import processing.video.*;

float FILL_INCREMENT = 0.05;

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

float fillRedTarget = 240;
float fillGreenTarget = 200;
float fillBlueTarget = 100;

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
  
  // set the camera alpha
  cam.loadPixels();
  for (int i = 0; i < cam.width; i++) {
    for (int j = 0; j < cam.height; j++) {
       int loc = i + j * cam.width;
       color pixel = cam.pixels[loc];
       cam.pixels[loc] = color(red(pixel), green(pixel), blue(pixel), max(mirrorAlpha, 0));
    }
  }
  
  blend(cam, 0, 0, width, height, 0, 0, width, height, blendingMode);
}

void updateMirrorAlpha() {
  float increment = increasingAlpha? random(0.25, 2.5) : random(-2.5, -0.25);
  mirrorAlpha += increment;
  
  if (increasingAlpha && mirrorAlpha > alphaLimit) {
    increasingAlpha = false;
    alphaLimit = random(-75, 15); // set the bottom threshold
  }
  else if (!increasingAlpha && mirrorAlpha < alphaLimit) {
    increasingAlpha = true;
    alphaLimit = random(30, 140); // set the top threshold
    blendingMode = blendingModes[int(random(blendingModes.length))]; // pick a fresh blending mode
  }  
}

void updateFill() {
  if (fillRed < fillRedTarget) {
    fillRed += FILL_INCREMENT; 
  } else if (fillRed > fillRedTarget) {
    fillRed -= FILL_INCREMENT; 
  } else {
    fillRedTarget = random(200, 255);  
  }
  
  if (fillGreen < fillGreenTarget) {
    fillGreen += FILL_INCREMENT; 
  } else if (fillGreen > fillGreenTarget) {
    fillGreen -= FILL_INCREMENT; 
  } else {
    fillGreenTarget = random(100, 220);  
  }
  
  if (fillBlue < fillBlueTarget) {
    fillBlue += FILL_INCREMENT; 
  } else if (fillBlue > fillBlueTarget) {
    fillBlue -= FILL_INCREMENT; 
  } else {
    fillBlueTarget = random(40, 160);  
  }
}

