import processing.video.*;

Capture cam;

int[] blendingModes = {ADD, SCREEN, OVERLAY, SOFT_LIGHT, DODGE};
int blendingMode = blendingModes[0];

float mirrorAlpha = 0;
boolean increasingAlpha = true;
float alphaLimit = 128;

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
    
    cam = new Capture(this, cameras[0]);
    cam.start();
  }      
}

void draw() {
  if (cam.available() == true) {
    cam.read();
  }
  
  updateMirrorAlpha();
  
  // give me the orange delight
  fill(255, 179, 119);
  rect(0, 0, width, height);
  
  // set the camera alpha
  cam.loadPixels();
  for (int i = 0; i < cam.width; i++) {
    for (int j = 0; j < cam.height; j++) {
       int loc = i + j * cam.width;
       color pixel = cam.pixels[loc];
       cam.pixels[loc] = color(red(pixel), green(pixel), blue(pixel), mirrorAlpha);
    }
  }
  
  // cool modes: ADD, SCREEN, OVERLAY, SOFT_LIGHT, DODGE
  blend(cam, 0, 0, width, height, 0, 0, width, height, blendingMode);
}

void updateMirrorAlpha() {
  float increment = increasingAlpha? random(0.1, 1.3) : random(-2.5, -0.25);
  mirrorAlpha += increment;
  
  if (increasingAlpha && mirrorAlpha > alphaLimit) {
    increasingAlpha = false;
    alphaLimit = random(0, 25); // set the bottom threshold
  }
  else if (!increasingAlpha && mirrorAlpha < alphaLimit) {
    increasingAlpha = true;
    alphaLimit = random(30, 255); // set the top threshold
    blendingMode = blendingModes[int(random(blendingModes.length))]; // pick a fresh blending mode
  }  
}

