// --- Enumerate the simulation types.
enum AttractorType {
  POISSON_SATURNE, SOLAR_SAIL
}

// --- Global configuration selector.
final AttractorType CURRENT_TYPE = AttractorType.POISSON_SATURNE;
SimulationSettings config;

// --- SimulationSettings class.
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

// --- Configuration helper functions.
SimulationSettings getPoissonSaturneSettings() {
  int w = 1920;
  int h = 1080;
  int iterations = 100_000_000;
  int chunkSize = 10_000;
  float scaleFactor = 1.0;
  float viewAngle = 5.5;
  float halfDivisor = 2.0;
  
  float[] coeffX = {0.021, 1.182, -1.183, 0.128, -1.12, -0.641, -1.152, -0.834, -0.97, 0.722};
  float[] coeffY = {0.243038, -0.825, -1.2, -0.835443, -0.835443, -0.364557, 0.458, 0.622785, -0.394937, -1.032911};
  float[] coeffZ = {-0.455696, 0.673, 0.915, -0.258228, -0.495, -0.264, -0.432, -0.416, -0.877, -0.3};
  
  EulerAxisRotation viewRot = new EulerAxisRotation(
      new PVector(0.304289493528802, 0.760492682863655, 0.573636455813981), 1.78268191887446);
  PVector centerCam = new PVector(-0.005, 0.262, -0.246);
  
  return new SimulationSettings(w, h, iterations, chunkSize, scaleFactor, viewAngle, halfDivisor,
                                  coeffX, coeffY, coeffZ, viewRot, centerCam);
}

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
