import controlP5.*;
import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;


/*
[
 [0,1,2]
 [3,4,5] -> 4 is actual point
 [6,7,8]
 ]
 */

float xStart, yStart;
float xLimit, yLimit;
float zNoiseDim;
float zNoiseDimIncrement;


int resolution = 80;

int particleCount = 300;

PVector[] particlePos;
PVector[] particleVel;
PVector[] particleAccel;
float dampening = 0.95;
;
float samplingUnit; // RESOLUTION FOR NOISE SAMPLING FOR PARTICLES, IN PIXELS

float sigmoidContrastStrength;

// VIZ
boolean showNoisePlane = false;
boolean showGradientVectors = false;
float zMultiplier = 1000;

PeasyCam cam;
ControlP5 controls;
Slider2D scaleControl;

void setup() {
  size(800, 800, P3D);
  fill(0);
  noStroke();

  cam = new PeasyCam(this, 1500);
  controls = new ControlP5(this);
  controls.setAutoDraw(false);

  createControllers();

  xStart = yStart = 0;
  xLimit = yLimit = 5;
  zNoiseDim = random(1000);
  zNoiseDimIncrement = 0.01;

  particlePos = new PVector[particleCount];
  particleVel = new PVector[particlePos.length];
  particleAccel = new PVector[particlePos.length];
  samplingUnit = 1;


  for (int i=0; i < particlePos.length; i++) {
    particlePos[i] = new PVector(random(width), random(height));
    particleVel[i] = new PVector();
    particleAccel[i] = new PVector();
  }
}

void draw() {
  background(50);

  //sigmoidContrastStrength = mouseX / float(width);

  if (controls.isMouseOver()) {
    cam.setActive(false);
  } else {
    cam.setActive(true);
  }

  setScale();

  pushMatrix();
  rotateX(HALF_PI);
  translate(-(width * 0.5), -(height * 0.5));
  
  showNoiseField();

  for (int i=0; i < particlePos.length; i++) {
    PVector posInField = new PVector(map(particlePos[i].x, 0, width, xStart, xLimit), map(particlePos[i].y, 0, height, yStart, yLimit));
    PVector posInField1 = new PVector(posInField.x, map(particlePos[i].y - samplingUnit, 0, height, yStart, yLimit));
    PVector posInField3 = new PVector(map(particlePos[i].x - samplingUnit, 0, width, xStart, xLimit), posInField.y);

    float noiseInPlace =  contrastSigmoid(noise(posInField.x, posInField.y, zNoiseDim), sigmoidContrastStrength);
    float noiseIn3 =  contrastSigmoid(noise(posInField3.x, posInField3.y, zNoiseDim), sigmoidContrastStrength);
    float noiseIn1 = contrastSigmoid(noise(posInField1.x, posInField1.y, zNoiseDim), sigmoidContrastStrength);

    float xGradient = noiseIn3 - noiseInPlace;
    float yGradient = noiseIn1 - noiseInPlace;

    /*
    if (i == 0 ) {
     fill(0, 0, 255);
     text(nf(xGradient, 2, 3) + " - " + nf(yGradient, 2, 3), 15, 15);
     }
     */

    particleAccel[i].set(xGradient, yGradient);
    particleAccel[i].mult(50);
    particleVel[i].add(particleAccel[i]);
    particleVel[i].mult(dampening);
    particlePos[i].add(particleVel[i]);
    particlePos[i].z = noiseInPlace * zMultiplier;

    // 3D VIZ
    pushMatrix();
    translate(particlePos[i].x, particlePos[i].y, particlePos[i].z);

    noFill();
    stroke(0, 255, 0);
    ellipse(0, 0, 5, 5);

    stroke(0, 255, 0);
    line(0, 0, particleVel[i].x, particleVel[i].y);

    popMatrix();


    // 2D VIZ
    /*
    noFill();
     stroke(0, 255, 0);
     ellipse(particlePos[i].x, particlePos[i].y, 5, 5);
     
     stroke(0, 255, 0);
     line(particlePos[i].x, particlePos[i].y, particlePos[i].x + particleVel[i].x, particlePos[i].y  + particleVel[i].y);
     */


    particleAccel[i].set(0, 0);
  }

  popMatrix();

  //showNoiseField();

  zNoiseDim += zNoiseDimIncrement;

  hint(DISABLE_DEPTH_TEST);
  cam.beginHUD();
  controls.draw();
  cam.endHUD();
  hint(ENABLE_DEPTH_TEST);
}

float contrastSigmoid(float t, float strength) {
  float y = 0;
  if (t <= 0.5) {
    y = (strength * t) / (strength + 0.5 - t);
  } else {
    float t2 = 1-t;
    y = (strength * t2) / (strength + 0.5 - t2);
    y = 1-y;
  }
  return y;
}

void showNoiseField() {
  noFill();

  float sizeUnit =  width / (float) resolution;

  for (int y=1; y < resolution - 1; y++) {
    float posY = (y / float(resolution)) * height;

    for (int x=1; x < resolution - 1; x++) {
      float posX = (x / float(resolution)) * width;

      //float nY0 = map(y-1, 0, resolution, yStart, yLimit);
      //float nX0 = map(x-1, 0, resolution, xStart, xLimit);
      float nY1 = map(y-1, 0, resolution, yStart, yLimit);
      float nX1 = map(x, 0, resolution, xStart, xLimit);

      float nY3 = map(y, 0, resolution, yStart, yLimit);
      float nX3 = map(x-1, 0, resolution, xStart, xLimit);
      float nY4 = map(y, 0, resolution, yStart, yLimit);
      float nX4 = map(x, 0, resolution, xStart, xLimit);

      //float xNoiseGrad = contrastSigmoid(noise(nX4, nY4, zNoiseDim), sigmoidContrastStrength) - contrastSigmoid(noise(nX3, nY3, zNoiseDim), sigmoidContrastStrength);
      //float yNoiseGrad = contrastSigmoid(noise(nX4, nY4, zNoiseDim), sigmoidContrastStrength) - contrastSigmoid(noise(nX1, nY1, zNoiseDim), sigmoidContrastStrength);

      if (showNoisePlane) {
        // PUNTO
        float noiseInPlace =  contrastSigmoid(noise(nX4, nY4, zNoiseDim), sigmoidContrastStrength);

        fill(noiseInPlace * 255);
        noStroke();

        pushMatrix();
        translate(posX, posY, 0);
        rect(0, 0, sizeUnit, sizeUnit);

        stroke(0, 127, 200);
        point(0, 0, (noiseInPlace * zMultiplier) - 2);
        popMatrix();
      }

      if (showGradientVectors) {
        // VECTOR GRADIENT

        float xNoiseGrad = contrastSigmoid(noise(nX4, nY4, zNoiseDim), sigmoidContrastStrength) - contrastSigmoid(noise(nX3, nY3, zNoiseDim), sigmoidContrastStrength);
        float yNoiseGrad = contrastSigmoid(noise(nX4, nY4, zNoiseDim), sigmoidContrastStrength) - contrastSigmoid(noise(nX1, nY1, zNoiseDim), sigmoidContrastStrength);

        stroke(255, 0, 0);
        ellipse(posX, posY, 2, 2);
        line(posX, posY, posX - (xNoiseGrad * 100), posY - (yNoiseGrad * 100));
      }
    }
  }
}

void reSeedNoise() {
  float seedX = random(1000);
  float seedY = random(1000);
  float noiseDistance = xLimit - xStart;

  xStart = seedX;
  yStart = seedY;
  xLimit = xStart + noiseDistance;
  yLimit = yStart + noiseDistance;
}

void createControllers() {
  scaleControl = controls.addSlider2D("noise scale").setPosition(10, 10).setSize(80, 80).setMinMax(0, 0, 10, 10).setValue(2, 2);
  controls.addSlider("sigmoidContrastStrength").setPosition(10, 110).setRange(0.0, 1.0).setValue(0.5);
  controls.addSlider("zMultiplier").setPosition(10, 120).setRange(0, 500).setValue(200);
  controls.addSlider("Z Increment").setPosition(10, 130).setRange(0, 1.0).setValue(0.1).plugTo(this, "setZIncrement");
  controls.addSlider("surface friction").setPosition(10, 140).setRange(0.0, 1.0).setValue(0.1).plugTo(this, "setParticleDamping");


  controls.addToggle("showNoisePlane").setSize(50, 20).setPosition(10, 160);
  controls.addToggle("showGradientVectors").setSize(50, 20).setPosition(10, 200);
  controls.addButton("reSeed Noise").setSize(80, 20).setPosition(10, 240).plugTo(this, "reSeedNoise");
  controls.addButton("reset Particles").setSize(80, 20).setPosition(10, 260).plugTo(this, "resetParticles");
}

void setZIncrement(float value) {
  println("changing Z Increment");
  zNoiseDimIncrement = value / 100.0;
}
void setScale() {
  xLimit = xStart + scaleControl.getArrayValue()[0];
  yLimit = yStart +  scaleControl.getArrayValue()[1];
}

void resetParticles() {
  for (int i=0; i < particlePos.length; i++) {
    particlePos[i].set(random(width), random(height));
    particleVel[i].set(0, 0, 0);
    particleAccel[i].set(0, 0, 0);
  }
}

void setParticleDamping(float value) {
  dampening = map(value, 1, 0, 0.8, 1);
}

void mouseDragged() {
  //xLimit = xStart + map(mouseX, 0, width, 0, 50);
  //yLimit = yStart + map(mouseY, 0, height, 0, 50);
}

void keyPressed() {
  if (key == 's') {
    reSeedNoise();
  }

  if (key == 'n') {
    showNoisePlane = !showNoisePlane;
  }

  if (key == 'v') {
    showGradientVectors = !showGradientVectors;
  }
}