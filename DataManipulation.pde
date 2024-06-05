import processing.sound.*; //<>//

import geomerative.*;

import processing.video.*; 
import java.util.ArrayList;

// CLICK TO BREAK THE SCREEN
Capture vid;
SoundFile[] sounds = new SoundFile[3];
SoundFile break2;
SoundFile break3;

int numPoints = 10;
PVector[] points = new PVector[numPoints];
boolean shatter = false;
int shatterCounter = 0;
PVector impactPoint;
ArrayList<Triangle> delaunayTriangles = new ArrayList<Triangle>();
ArrayList<Triangle> allTriangles = new ArrayList<Triangle>();
ArrayList<Integer> genTriCount = new ArrayList<Integer>();
ArrayList<Particle> particles = new ArrayList<Particle>();

int time = 0;
int startTime = 0;
int endTime = 20;
PGraphics vignette;
float tintVignette = 2;

void setup() {
  size(640, 480);
  RG.init(this);
  sounds[0] = new SoundFile(this, "break1.mp3");
  sounds[1] = new SoundFile(this, "break2.mp3");
  sounds[2] = new SoundFile(this, "break3.mp3");
  
  vid = new Capture(this, width, height);
  vid.start();
  stroke(0);
  frameRate(16);

  for (int i = 0; i < numPoints; i++) {
    points[i] = new PVector(random(width), random(height));
  }
}

void draw() {
  if (vid.available()) {
    vid.read();
  }
  pushMatrix();
  scale(-1,1);
  translate(-width, 0); 
  
  time++;
  
  // only show 2 triangle sets at a time
  if(shatterCounter == 3 || time - startTime > endTime && shatterCounter > 0) {
    startTime = time;
    endTime = (int)random(50, 100);
    shatterCounter--;
    for(int i = 0; i < genTriCount.get(0); i++) {
      allTriangles.remove(0);
    }
    genTriCount.remove(0);
  }
  
  if(!shatter) {
    int[] ogPixels = new int[width * height];
    
    for (int i = 0; i < width * height; i++) {
      ogPixels[i] = vid.pixels[i];
    }
    for (Triangle tri : allTriangles) {
      float minX = Float.MAX_VALUE;
      float minY = Float.MAX_VALUE; 
      float maxX = Float.MIN_VALUE;
      float maxY = Float.MIN_VALUE; 
      
      PVector[] vertices = {tri.p1, tri.p2, tri.p3};

      for (PVector vertex : vertices) {
        minX = min(minX, vertex.x);
        minY = min(minY, vertex.y);
        maxX = max(maxX, vertex.x);
        maxY = max(maxY, vertex.y);
      }
      
      shiftPix(minX, minY, maxX, maxY, tri, tri.shift, ogPixels);
    }
  }
  
  image(vid, 0, 0);
  
  // particle inks
  if(impactPoint != null && time % 2 == 0 && time - startTime < endTime) {
    int cur = 0;
    for(int i = 0; i < genTriCount.size()-1; i++) {
      cur += genTriCount.get(i);
    }
    for (int i = cur; i < allTriangles.size(); i++) {
      Triangle tri = allTriangles.get(i);
      particles.add(new Particle(tri.p1.x, tri.p1.y));
    }
  }
  // Update and display all particles
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.isFinished()) {
      particles.remove(i);
    }
  }
  
  if(particles.size() > 100 && tintVignette > 0.5) {
    tintVignette -= 0.02;
  } else if(particles.size() < 100 && tintVignette < 2) {
    tintVignette += 0.02;
  }
  
  vignette = createVignette(width,height, tintVignette);
  image(vignette, 0, 0);
  popMatrix();
}

PGraphics createVignette(int w, int h, float tint) {
  PGraphics pg = createGraphics(w, h);
  pg.beginDraw();
  pg.noFill();
  
  // Draw the radial gradient for vignette
  for (int r = 0; r < w; r++) {
    float alpha = map(r, 0, w * tint, 0, 255);
    pg.stroke(0, 0, 0, alpha);
    pg.ellipse(w / 2, h / 2, r * 2, r * 2);
  }
  
  pg.endDraw();
  return pg;
}

void mousePressed() {
  //play random sound
  sounds[(int)random(0,3)].play();
  crackDelaunay(width-mouseX, mouseY);
  startTime = time;
  endTime = (int)random(50, 100);
  impactPoint = new PVector(width-mouseX, mouseY);
}

void crackDelaunay(int x, int y) {
  //x = width - x;
  // Add the mouse click point as the first point
  PVector[] points = new PVector[numPoints];
  points[0] = new PVector(x, y);
  points[1] = new PVector(0, 0);
  points[2] = new PVector(width, 0);
  points[3] = new PVector(0, height);
  points[4] = new PVector(width, height);

  // Generate random points around the mouse click position
  for (int i = 5; i < numPoints; i++) {
    // Calculate random angle and distance
    float angle = random(0, TWO_PI);
    float distance = random(0, 300); // Adjust the maximum distance as needed

    // Calculate the position of the point
    float xPos = x + cos(angle) * distance;
    float yPos = y + sin(angle) * distance;
    points[i] = new PVector(xPos, yPos);
  }

  // Generate Delaunay triangles
  ArrayList<Triangle> delaunayTriangles = generateDelaunay(points);
  genTriCount.add(delaunayTriangles.size());
  shatterCounter++;

  shatter = true;
  for(Triangle tri: delaunayTriangles) {
    allTriangles.add(tri);
  }
  shatter = false;
}


ArrayList<Triangle> generateDelaunay(PVector[] points) {
  ArrayList<Triangle> triangles = new ArrayList<Triangle>();
  
  // Create a super triangle that encompasses all the points
  float maxX = width, maxY = height;
  float minX = 0, minY = 0;

  PVector p1 = new PVector(minX - 10, minY - 10);
  PVector p2 = new PVector(maxX + 10, minY - 10);
  PVector p3 = new PVector((minX + maxX) / 2, maxY + 10);

  Triangle superTriangle = new Triangle(p1, p2, p3);
  triangles.add(superTriangle);

  for (PVector point : points) {
    ArrayList<Triangle> badTriangles = new ArrayList<Triangle>();
    ArrayList<Edge> polygon = new ArrayList<Edge>();

    for (Triangle triangle : triangles) {
      if (triangle.circumcircleContains(point)) {
        badTriangles.add(triangle);
        for (Edge edge : triangle.getEdges()) {
          polygon.add(edge);
        }
      }
    }

    for (Triangle triangle : badTriangles) {
      triangles.remove(triangle);
    }

    ArrayList<Edge> badEdges = new ArrayList<Edge>();
    for (int i = 0; i < polygon.size(); i++) {
      for (int j = i + 1; j < polygon.size(); j++) {
        if (polygon.get(i).equals(polygon.get(j))) {
          badEdges.add(polygon.get(i));
          badEdges.add(polygon.get(j));
        }
      }
    }

    for (Edge edge : badEdges) {
      polygon.remove(edge);
    }

    for (Edge edge : polygon) {
      triangles.add(new Triangle(edge.p1, edge.p2, point));
    }
  }

  ArrayList<Triangle> validTriangles = new ArrayList<Triangle>();
  for (Triangle triangle : triangles) {
    if (!triangle.hasVertex(p1) && !triangle.hasVertex(p2) && !triangle.hasVertex(p3)) {
      validTriangles.add(triangle);
    }
  }

  return validTriangles;
}

void shiftPix(float x1, float y1, float x2, float y2, Triangle tri, PVector shift, int[] ogPixels) {
  vid.loadPixels();
  
  int w = vid.width;
  int h = vid.height;
  //x1 = width - x1; 
  //x2 = width - x2;
  
  // shift from og image
  for (int i = (int)x1; i <= x2; i++) {
    for (int j = (int)y1; j < y2; j++) {
      if(pointInTriangle(i,j,tri)) {
        int newX = i + (int)shift.x; 
        int newY = j + (int)shift.y;
        if (newX >= 0 && newX < w && newY >= 0 && newY < h && i > 0 && j  > 0 && i < w && j < h) {
          vid.pixels[i + j * w] = ogPixels[newX + newY * w];
        }
      }
    }
  }
  
  drawLine((int)tri.p1.x, (int)tri.p1.y, (int)tri.p2.x, (int)tri.p2.y, color(0));
  drawLine((int)tri.p3.x, (int)tri.p3.y, (int)tri.p2.x, (int)tri.p2.y, color(0));
  drawLine((int)tri.p1.x, (int)tri.p1.y, (int)tri.p3.x, (int)tri.p3.y, color(0));
  
  vid.updatePixels();
}

void drawLine(int x0, int y0, int x1, int y1, color lineColor) {
 // x0 = width - x0; // Flip the x coordinate
  //x1 = width - x1; // Flip the x coordinate
  
  int dx = abs(x1 - x0); // horizontal dist
  int dy = abs(y1 - y0); // vertical dist
  // direction
  int sx = x0 < x1 ? 1 : -1; 
  int sy = y0 < y1 ? 1 : -1;
  // which way to step
  int err = dx - dy;
  
  while (true) {
    if (x0 >= 0 && x0 < width && y0 >= 0 && y0 < height) { // within bounds
      vid.pixels[x0 + y0 * width] = lineColor;
    }
    
    if (x0 == x1 && y0 == y1) break; // reached end
    int e2 = 2 * err; // double step
    // choose direction
    if (e2 > -dy) {
      err -= dy;
      x0 += sx;
    }
    if (e2 < dx) {
      err += dx;
      y0 += sy;
    }
  }
}


boolean pointInTriangle(int x, int y, Triangle tri) { 
  int crossings = 0;

  PVector[] vertices = {tri.p1, tri.p2, tri.p3};

  for (int i = 0; i < 3; i++) {
    PVector v1 = vertices[i];
    PVector v2 = vertices[(i + 1) % 3];

    // Check if the point is on the edge of the triangle
    if ((v1.y == y && v1.x <= x && v2.y == y && v2.x >= x) || 
        (v2.y == y && v2.x <= x && v1.y == y && v1.x >= x)) {
      return true;
    }

    // Check for normal crossings
    if (((v1.y > y) != (v2.y > y)) &&
        (x < (v2.x - v1.x) * (y - v1.y) / (v2.y - v1.y) + v1.x)) {
      crossings++;
    }
  }

  return crossings % 2 != 0;
}
