// Rossler Attractor parameters
float x = 1, y = 1, z = 1;
float a = 0.2;
float b = 0.2;
float c = 5.7;

float dt = 0.03;           // Time step for integration
float scaleFactor = 20;     // Scale factor for visualization
int maxPoints = 10000;     // Maximum number of points to store

ArrayList<PVector> points; // List to store points of the attractor

// Maximum expected absolute value for z (adjust as needed)
float maxZ = 40;

void setup() {
  size(800, 1000, P3D);
  points = new ArrayList<PVector>();
  colorMode(HSB, 360, 100, 100);
  noFill();  // We'll use stroke for drawing the attractor curve
}

void draw() {
  background(0);
  
  // Update the Lorenz system state
  updateLorenz();

  // Add the new point (scaled for visualization)
  PVector newPoint = new PVector(x, y, z).mult(scaleFactor);
  points.add(newPoint);

  // Limit the size of the points list for performance
  if (points.size() > maxPoints) {
    points.remove(0);
  }
  
  // Set up transformation for visualization
  pushMatrix();
    translate(width * 0.5, height * 0.7);
    rotateX(HALF_PI);             // Rotate so z-axis comes out of the screen
    rotateZ(frameCount * 0.01);     // Slow rotation for dynamic view

    // Draw the attractor curve with logarithmically mapped color based on z-position
    for (int i = 0; i < points.size() - 1; i++) {
      PVector p1 = points.get(i);
      PVector p2 = points.get(i + 1);
      float hueVal = getLogMappedHue(p1.z);
      stroke(hueVal, 100, 100);
      line(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z);
    }

    // Highlight the last point with a sphere whose color is based on its z-position
    if (points.size() > 0) {
      PVector lastPoint = points.get(points.size() - 1);
      pushMatrix();
        translate(lastPoint.x, lastPoint.y, lastPoint.z);
        float sphereHue = getLogMappedHue(lastPoint.z);
        fill(sphereHue, 100, 100);
        noStroke();
        sphere(5);
      popMatrix();
    }
  popMatrix();
}

// Returns a hue value based on a logarithmic mapping of the z position.
// For positive z, hue is mapped from 0 to 180.
// For negative z, hue is mapped from 180 to 360.
float getLogMappedHue(float zVal) {
  // Add 1 to avoid log(0)
  if (zVal >= 0) {
    return map(log(zVal + 1), 0, log(maxZ + 1), 0, 180);
  } else {
    return map(log(-zVal + 1), 0, log(maxZ + 1), 180, 360);
  }
}

// Function to update the Lorenz attractor's state variables
void updateLorenz() {
  float dx = -y - z;
  float dy = x + a * y;
  float dz = b + z * (x - c);
  
  x += dt * dx;
  y += dt * dy;
  z += dt * dz;
}
