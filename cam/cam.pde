import processing.video.*;

Capture cam;

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
  
  fill(255, 179, 119);
  rect(0, 0, width, height);
  
  blendMode(DIFFERENCE);
  image(cam, 0, 0);
}
