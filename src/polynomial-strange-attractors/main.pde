// Global Variables & Buffers
int[] count;
float[] steps;
float[] zbuf;
int maxCount = 0;

PImage resultImage;
boolean rendered = false;

PolynomialSprott2Degree attractor;
PVector current;
float[][] rotMatrix;
float sinA, cosA;

int currentIteration = 0;

void settings() {
  // Use the appropriate configuration.
  if (CURRENT_TYPE == AttractorType.SOLAR_SAIL) {
    config = getSolarSailSettings();
  } else {
    config = getPoissonSaturneSettings();
  }
  size(config.width, config.height, P3D);
}

void setup() {
  count = new int[config.width * config.height];
  steps = new float[config.width * config.height];
  zbuf = new float[config.width * config.height];
  for (int i = 0; i < zbuf.length; i++) {
    zbuf[i] = -1.0;
  }
  
  background(0);
  
  // Initialize the attractor.
  attractor = new PolynomialSprott2Degree(config.coeffX, config.coeffY, config.coeffZ);
  current = new PVector(random(1), random(1), random(1));
  current.mult(0.1);
  
  // Settle the attractor.
  for (int i = 0; i < 1000; i++) {
    current = attractor.nextPoint(current);
  }
  
  // Setup view transformation.
  rotMatrix = config.viewRotation.toRotationMatrix();
  sinA = sin(config.viewAngle);
  cosA = cos(config.viewAngle);
  
  resultImage = createImage(config.width, config.height, RGB);
  frameRate(60);
}

void draw() {
  if (currentIteration < config.iterations) {
    int iterThisFrame = min(config.chunkSize, config.iterations - currentIteration);
    for (int i = 0; i < iterThisFrame; i++) {
      processSingleIteration();
    }
    currentIteration += iterThisFrame;
    println("Iteration " + currentIteration + " / " + config.iterations);
  } else if (!rendered) {
    colorizeImage();
    rendered = true;
  }
  image(resultImage, 0, 0);
}

void processSingleIteration() {
  float oldx = current.x, oldy = current.y, oldz = current.z;
  current = attractor.nextPoint(current);
  
  float dx = current.x - oldx;
  float dy = current.y - oldy;
  float dz = current.z - oldz;
  float deltaMag = sqrt(dx*dx + dy*dy + dz*dz);
  
  float cx = current.x, cy = current.y, cz = current.z;
  float sx = rotMatrix[0][0] * cx + rotMatrix[0][1] * cy + rotMatrix[0][2] * cz;
  float sy = rotMatrix[1][0] * cx + rotMatrix[1][1] * cy + rotMatrix[1][2] * cz;
  float sz = rotMatrix[2][0] * cx + rotMatrix[2][1] * cy + rotMatrix[2][2] * cz;
  
  float ccx = config.centerCamera.x;
  float ccy = config.centerCamera.y;
  float ccz = config.centerCamera.z;
  
  float tx = sx + ccx;
  float tz_temp = sz + ccy;
  float x2 = tx * cosA + tz_temp * sinA;
  float z2 = tx * sinA - tz_temp * cosA;
  
  float widthScaled = config.width * config.scaleFactor;
  float scaleAdjustedMid = 0.5 / config.scaleFactor;
  float halfHeight = config.height / config.halfHeightDivisor;
  float px = (scaleAdjustedMid - x2) * widthScaled;
  float py = halfHeight - (sy + ccz) * widthScaled;
  
  if (px >= 0 && px < config.width && py >= 0 && py < config.height) {
    int ix = int(px);
    int iy = int(py);
    int index = ix + iy * config.width;
    int newCount = ++count[index];
    if (newCount > maxCount) {
      maxCount = newCount;
    }
    
    if (z2 > zbuf[index]) {
      float part;
      float partx = (sx + ccx) * COS_P + (sz + ccy) * SIN_P;
      if (partx < CPOS || (C10 * partx + sy) < B1 ||
          (C1 * partx + sy) < B2 || (C05 * partx - sy) > B3) {
        part = 0.0;
      } else {
        part = 1.0;
      }
      float colorVal = (part + deltaMag) * 0.5;
      steps[index] = (colorVal - 0.1) / 0.9;
      zbuf[index] = z2;
    }
  }
}

void colorizeImage() {
  resultImage.loadPixels();
  
  float brightnessOffset = -0.15;
  float brightnessFactor = 5.0 / 3.0;
  
  // Define a simple palette.
  PVector[] palette = new PVector[7];
  palette[0] = new PVector(1, 1, 0.5);
  palette[1] = new PVector(0.5, 1, 0.5);
  palette[2] = new PVector(1, 0.5, 0.5);
  palette[3] = new PVector(0.5, 1, 1);
  palette[4] = new PVector(0.5, 0.5, 1);
  palette[5] = new PVector(1, 0.5, 1);
  palette[6] = new PVector(1, 0.5, 1);
  
  int numColors = palette.length - 1;
  
  for (int i = 0; i < config.width * config.height; i++) {
    float stepVal = constrain(steps[i], 0, 0.999999);
    float t = stepVal * numColors;
    int n = int(floor(t));
    float f = t - n;
    
    float r = lerp(palette[n].x, palette[n + 1].x, f);
    float g = lerp(palette[n].y, palette[n + 1].y, f);
    float b = lerp(palette[n].z, palette[n + 1].z, f);
    
    r = sqrt(r);
    g = sqrt(g);
    b = sqrt(b);
    
    int cnt = count[i];
    float factor = (cnt > 0) ? log(cnt + 1) / log(maxCount + 1) : 0;
    float finalR = ((r * factor + brightnessOffset) * brightnessFactor) * 255;
    float finalG = ((g * factor + brightnessOffset) * brightnessFactor) * 255;
    float finalB = ((b * factor + brightnessOffset) * brightnessFactor) * 255;
    
    resultImage.pixels[i] = color(constrain(finalR, 0, 255),
                                  constrain(finalG, 0, 255),
                                  constrain(finalB, 0, 255));
  }
  resultImage.updatePixels();
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    resultImage.save("strange_attractor.png");
    println("Image saved as strange_attractor.png");
  }
}
