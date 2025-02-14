// --- Enumerate the simulation types.
enum AttractorType {
  POISSON_SATURNE, SOLAR_SAIL
}

// --- Choose which configuration to use.
final AttractorType CURRENT_TYPE = AttractorType.POISSON_SATURNE;
SimulationSettings config;

// --- SimulationSettings class (without static helper methods).
class SimulationSettings {
  int width, height;
  int iterations;
  int chunkSize;
  float scaleFactor;
  float viewAngle;
  float halfHeightDivisor;
  float[] coeffX, coeffY, coeffZ;
  EulerAxisRotation viewRotation;
  PVector centerCamera;

  SimulationSettings(int width, int height, int iterations, int chunkSize,
                     float scaleFactor, float viewAngle, float halfHeightDivisor,
                     float[] coeffX, float[] coeffY, float[] coeffZ,
                     EulerAxisRotation viewRotation, PVector centerCamera) {
    this.width = width;
    this.height = height;
    this.iterations = iterations;
    this.chunkSize = chunkSize;
    this.scaleFactor = scaleFactor;
    this.viewAngle = viewAngle;
    this.halfHeightDivisor = halfHeightDivisor;
    this.coeffX = coeffX;
    this.coeffY = coeffY;
    this.coeffZ = coeffZ;
    this.viewRotation = viewRotation;
    this.centerCamera = centerCamera;
  }
}

// --- Global helper functions that return settings.
// POISSON-SATURNE
SimulationSettings getPoissonSaturneSettings() {
  int w = 1920;
  int h = 1080;
  int iterations = 100_000_000;
  int chunkSize = 10_000;
  float scaleFactor = 1.0;
  float viewAngle = 5.5;
  float halfDivisor = 2.0;  // halfHeight = h/2.0

  float[] coeffX = {0.021, 1.182, -1.183, 0.128, -1.12, -0.641, -1.152, -0.834, -0.97, 0.722};
  float[] coeffY = {0.243_038, -0.825, -1.2, -0.835443, -0.835_443, -0.364557, 0.458, 0.622785, -0.394_937, -1.032911};
  float[] coeffZ = {-0.455_696, 0.673, 0.915, -0.258_228, -0.495, -0.264, -0.432, -0.416, -0.877, -0.3};

  EulerAxisRotation viewRot = new EulerAxisRotation(
      new PVector(0.304289493528802, 0.760492682863655, 0.573636455813981), 1.78268191887446);
  PVector centerCam = new PVector(-0.005, 0.262, -0.246);

  return new SimulationSettings(w, h, iterations, chunkSize, scaleFactor, viewAngle, halfDivisor,
                                  coeffX, coeffY, coeffZ, viewRot, centerCam);
}

// SOLAR-SAIL
SimulationSettings getSolarSailSettings() {
  int w = 1800;
  int h = 2200;
  int iterations = 100_000_000;
  int chunkSize = 10_000;
  float scaleFactor = 1.0;
  float viewAngle = 3.4;
  float halfDivisor = 4.5;

  float[] coeffX = {0.744304, -0.546835, 0.121519, -0.653165, 0.399, 0.379, 0.44, 1.014, -0.805063, 0.377};
  float[] coeffY = {-0.683, 0.531646, -0.04557, -1.2, -0.546835, 0.091139, 0.744304, -0.273418, -0.349367, -0.531646};
  float[] coeffZ = {0.712, 0.744304, -0.577215, 0.966, 0.04557, 1.063291, 0.01519, -0.425316, 0.212658, -0.01519};

  EulerAxisRotation viewRot = new EulerAxisRotation(new PVector(0.02466, 0.4618, -0.54789), 2.5194998);
  PVector centerCam = new PVector(0.28, -0.16, 0.22);

  return new SimulationSettings(w, h, iterations, chunkSize, scaleFactor, viewAngle, halfDivisor,
                                  coeffX, coeffY, coeffZ, viewRot, centerCam);
}

// ===================
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

// Pre-cached constants for color transform.
final float COS_P = 0.700_909_264_299_850_898_183_308_345_323_894_172_906_875_610_351_562_5;
final float SIN_P = 0.713_250_449_154_181_564_992_427_411_198_150_366_544_723_510_742_187_5;
final float CPOS  = -0.0839;
final float C10   = 10.55;
final float B1    = 0.46 - 1.0941;
final float C1    = 1.0426;
final float B2    = 0.179 - 0.1576;
final float C05   = 0.5139;
final float B3    = -0.04 - 0.04092;

// ===================
// Processing Setup and Draw
// ===================

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

class PolynomialSprott2Degree {
  float[] coeffX;
  float[] coeffY;
  float[] coeffZ;

  PolynomialSprott2Degree(float[] x, float[] y, float[] z) {
    coeffX = x;
    coeffY = y;
    coeffZ = z;
  }

  PVector nextPoint(PVector p) {
    float x = p.x, y = p.y, z = p.z;
    float newX = coeffX[0]
               + coeffX[1] * x
               + coeffX[2] * (x*x)
               + coeffX[3] * (x*y)
               + coeffX[4] * (x*z)
               + coeffX[5] * y
               + coeffX[6] * (y*y)
               + coeffX[7] * (y*z)
               + coeffX[8] * z
               + coeffX[9] * (z*z);
    float newY = coeffY[0]
               + coeffY[1] * x
               + coeffY[2] * (x*x)
               + coeffY[3] * (x*y)
               + coeffY[4] * (x*z)
               + coeffY[5] * y
               + coeffY[6] * (y*y)
               + coeffY[7] * (y*z)
               + coeffY[8] * z
               + coeffY[9] * (z*z);
    float newZ = coeffZ[0]
               + coeffZ[1] * x
               + coeffZ[2] * (x*x)
               + coeffZ[3] * (x*y)
               + coeffZ[4] * (x*z)
               + coeffZ[5] * y
               + coeffZ[6] * (y*y)
               + coeffZ[7] * (y*z)
               + coeffZ[8] * z
               + coeffZ[9] * (z*z);
    return new PVector(newX, newY, newZ);
  }
}

class EulerAxisRotation {
  PVector axis;
  float rotation;

  EulerAxisRotation(PVector axis, float rotation) {
    this.axis = axis.copy();
    this.rotation = rotation;
    this.axis.normalize();
  }

  float[][] toRotationMatrix() {
    float c = cos(rotation);
    float s = sin(rotation);
    float c1 = 1 - c;
    float x = axis.x, y = axis.y, z = axis.z;

    float xxc1 = x * x * c1;
    float yyc1 = y * y * c1;
    float zzc1 = z * z * c1;
    float xyc1 = x * y * c1;
    float xzc1 = x * z * c1;
    float yzc1 = y * z * c1;
    float xs = x * s;
    float ys = y * s;
    float zs = z * s;

    float[][] m = new float[3][3];
    m[0][0] = c + xxc1;
    m[0][1] = xyc1 - zs;
    m[0][2] = xzc1 + ys;
    m[1][0] = xyc1 + zs;
    m[1][1] = c + yyc1;
    m[1][2] = yzc1 - xs;
    m[2][0] = xzc1 - ys;
    m[2][1] = yzc1 + xs;
    m[2][2] = c + zzc1;
    return m;
  }
}

void colorizeImage() {
  resultImage.loadPixels();

  float brightnessOffset = -0.15;
  float brightnessFactor = 5.0 / 3.0;

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
