
float xStart, yStart;
float xLimit, yLimit;
float zNoiseDim;
float zNoiseDimIncrement;

/*
[
 [0,1,2]
 [3,4,5] -> 4 is actual point
 [6,7,8]
 ]
 */

int resolution = 50;

PVector[] particlePos;
PVector[] particleVel;
PVector[] particleAccel;
float dampening = 0.95;
;
float samplingUnit; // RESOLUTION FOR NOISE SAMPLING FOR PARTICLES, IN PIXELS

float sigmoidContrastStrength;

boolean showNoisePlane = false;
boolean showGradientVectors = false;

void setup() {
  size(800, 800);
  fill(0);
  noStroke();

  xStart = yStart = 0;
  xLimit = yLimit = 5;
  zNoiseDim = random(1000);
  zNoiseDimIncrement = 0.005;

  particlePos = new PVector[1000];
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

  sigmoidContrastStrength = mouseX / float(width);

  showNoiseField();

  for (int i=0; i < particlePos.length; i++) {
    PVector posInField = new PVector(map(particlePos[i].x, 0, width, xStart, xLimit), map(particlePos[i].y, 0, height, yStart, yLimit));
    PVector posInField1 = new PVector(posInField.x, map(particlePos[i].y - samplingUnit, 0, height, yStart, yLimit));
    PVector posInField3 = new PVector(map(particlePos[i].x - samplingUnit, 0, width, xStart, xLimit), posInField.y);

    float xGradient = contrastSigmoid(noise(posInField3.x, posInField3.y, zNoiseDim), sigmoidContrastStrength) - contrastSigmoid(noise(posInField.x, posInField.y, zNoiseDim), sigmoidContrastStrength);
    float yGradient = contrastSigmoid(noise(posInField1.x, posInField1.y, zNoiseDim), sigmoidContrastStrength) - contrastSigmoid(noise(posInField.x, posInField.y, zNoiseDim), sigmoidContrastStrength);

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

    noFill();
    stroke(0, 255, 0);
    ellipse(particlePos[i].x, particlePos[i].y, 5, 5);

    stroke(0, 255, 0);
    line(particlePos[i].x, particlePos[i].y, particlePos[i].x + particleVel[i].x, particlePos[i].y  + particleVel[i].y);

    particleAccel[i].set(0, 0);
  }



  //showNoiseField();

  zNoiseDim += zNoiseDimIncrement;
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
        float tamanio = contrastSigmoid(noise(nX4, nY4, zNoiseDim), sigmoidContrastStrength) * 255;

        fill(tamanio);
        noStroke();
        rect(posX, posY, sizeUnit, sizeUnit);
      }

      if (showGradientVectors) {
        // VECTOR GRADIENT

        float xNoiseGrad = contrastSigmoid(noise(nX4, nY4, zNoiseDim), sigmoidContrastStrength) - contrastSigmoid(noise(nX3, nY3, zNoiseDim), sigmoidContrastStrength);
        float yNoiseGrad = contrastSigmoid(noise(nX4, nY4, zNoiseDim), sigmoidContrastStrength) - contrastSigmoid(noise(nX1, nY1, zNoiseDim), sigmoidContrastStrength);

        stroke(255, 0, 0);
        ellipse(posX, posY, 2, 2);
        line(posX, posY, posX - (xNoiseGrad * 50), posY - (yNoiseGrad * 50));
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

void mouseDragged() {
  xLimit = xStart + map(mouseX, 0, width, 0, 50);
  yLimit = yStart + map(mouseY, 0, height, 0, 50);
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