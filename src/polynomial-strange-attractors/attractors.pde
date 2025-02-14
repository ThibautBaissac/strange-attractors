// --- PolynomialSprott2Degree attractor class.
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

// --- EulerAxisRotation class.
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
