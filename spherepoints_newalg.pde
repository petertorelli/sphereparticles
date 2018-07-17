PShape composite;
PShape sphere;
BoundedParticle[] particles;

int frame = 0;
float radius = 50.0;
float particleRadius = 0.5;
float velocityScalar = 1e3;

float annealingRate = 10;

int numPrims = 400;

float vectorSize = 100 / annealingRate;
boolean drawForces = true;
int firstMouseX, firstMouseY;
float rotX, rotY;

void mousePressed() {
  rotX = mouseX / (float)width * TWO_PI;
  rotY = mouseY / (float)height * TWO_PI;
}

void mouseDragged() {
  rotY = -1 *  mouseX / (float)width * TWO_PI;
  rotX = -1 * mouseY / (float)height * TWO_PI;
}

public class BoundedParticle {
  public PShape particle;
  public float phi, theta;
  public float r;
  public float x, y, z;
  
  float nextX, nextY, nextZ;
  
  void nextPosition(Vector3D P) {
    nextX = P.x;
    nextY = P.y;
    nextZ = P.z;
  }
  
  void moveToNextPosition() {
    pushMatrix();
    particle.translate(-x, -y, -z);
    x = nextX;
    y = nextY;
    z = nextZ;
    particle.translate(x, y, z);
    popMatrix();
  }
  
  public boolean isVisible;
  
  public void hilight(Boolean set) {
    if (set) {
      this.particle.setFill(color(0, 0, 0xff, 0xff));
    } else {
      this.particle.setFill(color(0xff, 0, 0, 0xff));
    }
  }
  
  public BoundedParticle() {
    this.particle = createShape(SPHERE, particleRadius);
    this.particle.setFill(color(0xff, 0, 0, 0xff));
  }
  
  public void positionShape() {
    pushMatrix();
    this.particle.translate(-this.x, -this.y, -this.z);
    this.z = sin(this.phi) * this.r;
    float w = cos(this.phi) * this.r;
    this.x = sin(theta) * w;
    this.y = cos(theta) * w;
    this.particle.translate(this.x, this.y, this.z);
    popMatrix();
  }
};

void setup() {
  size(600, 600, P3D);
  randomSeed(0);

  noStroke();

  sphere = createShape(SPHERE, radius);
  sphere.setFill(color(0, 0, 0, 0x1f));
  
  particles = new BoundedParticle[numPrims];

  firstMouseX = firstMouseY = 0;
  rotX = rotY = PI / 4;
  
  composite = createShape(GROUP);

  for (int i = 0; i < numPrims; ++i) {
    particles[i] = new BoundedParticle();
    composite.addChild(particles[i].particle);
    //particles[i].theta = TWO_PI * ((float)(i+1) / (float)numPrims);//(float)random(TWO_PI);
    particles[i].theta = (float)random(TWO_PI);
    particles[i].phi = (float)random(PI / 8);
    particles[i].r = radius;
    particles[i].positionShape();
  }
  
  //ortho();
}

public class Vector3D {
  public float x, y, z;
  Vector3D() {
    x = y = z = 0;
  }
  Vector3D(float _x, float _y, float _z) {
    x = _x;
    y = _y;
    z = _z;
  }
  Vector3D(BoundedParticle P) {
    x = P.x;
    y = P.y;
    z = P.z;
  }
  Vector3D minus(Vector3D V2) {
    Vector3D V1 = new Vector3D();
    V1.x = this.x - V2.x;
    V1.y = this.y - V2.y;
    V1.z = this.z - V2.z;
    return V1;
  }
  Vector3D plus(Vector3D V2) {
    Vector3D V1 = new Vector3D();
    V1.x = this.x + V2.x;
    V1.y = this.y + V2.y;
    V1.z = this.z + V2.z;
    return V1;
  }
  void scaleTo(float newMagnitude) {
    float magnitude = sqrt(x * x + y * y + z * z);
    x = x / magnitude * newMagnitude;
    y = y / magnitude * newMagnitude;
    z = z / magnitude * newMagnitude;
  }
}

int hotIndex = -1;

void draw() {
  ++frame;
  background(255);
  pushMatrix();
  translate(width / 2, height / 2, 400);
  rotateX(rotX);
  rotateY(rotY);
  shape(composite);
  shape(sphere);

  //pause
  if (frame < 50) {
    popMatrix();
    return;
  }
  
  if (frame % 100 == 0) {
    hotIndex = (int)random(numPrims);
  }
   
  for (int i = 0; i < numPrims; ++i) {
    
    // First, compute the "force" vector
    float fx, fy, fz;
    fx = fy = fz = 0;
    for (int j = 0; j < numPrims; ++j) {
      if (i == j) {
        continue;
      }
      float dx, dy, dz;
      float localAnnealing = annealingRate;
      if (hotIndex > 0 && j == hotIndex) {
        particles[j].hilight(true);
        localAnnealing = 3000;
      } else {
        particles[j].hilight(false);
      }
        
      dx = particles[j].x - particles[i].x;
      dy = particles[j].y - particles[i].y;
      dz = particles[j].z - particles[i].z;
      float dist = sqrt(dx * dx + dy * dy + dz * dz);
      float force;
      if (dist == 0) {
        force = localAnnealing;
      } else {
        force = localAnnealing / (dist * dist);
      }
      dx /= dist;
      dy /= dist;
      dz /= dist;
      dx *= force;
      dy *= force;
      dz *= force;
      fx -= dx;
      fy -= dy;
      fz -= dz;
    }

    // 1. Compute goal vector
    Vector3D F = new Vector3D(fx, fy, fz);
    Vector3D P = new Vector3D(particles[i]);
    Vector3D G = P.plus(F);

    stroke(0xbf);
    line(P.x, P.y, P.z, P.x + fx * vectorSize, P.y + fy * vectorSize, P.z + fz * vectorSize);
    
    G.scaleTo(radius);
    // Insert test for distance!!!
    particles[i].nextPosition(G);
  }
  
  for (int i = 0; i < numPrims; ++i) {
    particles[i].moveToNextPosition();
  }

  ++frame;
 // draw force lines in same matrix...
  popMatrix();
}