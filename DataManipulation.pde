import geomerative.*; //<>//

import processing.video.*; 
import java.util.ArrayList;

// CLICK TO BREAK THE SCREEN
Capture vid;

int numPoints = 10;
PVector[] points = new PVector[numPoints];
boolean shatter = false;
PVector impactPoint;
ArrayList<Triangle> delaunayTriangles = new ArrayList<Triangle>();
ArrayList<Triangle> allTriangles = new ArrayList<Triangle>();
int shatterCounter = 0;
int[] genTriCount = new int[5];

void setup() {
  size(640, 480);
  RG.init(this);
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
  if(shatterCounter == 2) {
    shatterCounter = 0;
    for(int i = 0; i < genTriCount.length; i++) {
      println("i " +  genTriCount[i]);
    }
    for(int i = 0; i < genTriCount[0]; i++) {
      allTriangles.remove(0);
    }
  }
  if(!shatter) {
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
      
      shiftPix(minX, minY, maxX, maxY, tri, tri.shift);
    }
  }
    
  
  image(vid, 0, 0);
  
  /* crack lines
  for (Triangle tri : allTriangles) {
    line(tri.p1.x, tri.p1.y, tri.p2.x, tri.p2.y);
    line(tri.p3.x, tri.p3.y, tri.p2.x, tri.p2.y);
    line(tri.p1.x, tri.p1.y, tri.p3.x, tri.p3.y);
  }*/
}

void mousePressed() {
  //cracks(mouseX, mouseY);
  crackDelaunay(mouseX, mouseY);
  
}

void crackDelaunay(int x, int y) {
  
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
  genTriCount[shatterCounter] = delaunayTriangles.size();
  shatterCounter++;
  println("Number of Delaunay Triangles: " + delaunayTriangles.size());
  
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

void shiftPix(float x1, float y1, float x2, float y2, Triangle tri, PVector shift) {
  vid.loadPixels();
  
  int w = vid.width;
  int h = vid.height;
  int[] ogPixels = new int[w * h];
  
  for (int i = 0; i < w * h; i++) {
    ogPixels[i] = vid.pixels[i];
  }
  
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
  vid.updatePixels();
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
