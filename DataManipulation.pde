import processing.video.*;

// CLICK TO BREAK THE SCREEN

PImage img;
PImage ogImg;

Capture vid;

ArrayList<PVector[]> crackSegments = new ArrayList<PVector[]>(); // Store line segments
ArrayList<ArrayList<PVector[]>> crackLines = new ArrayList<ArrayList<PVector[]>>(); // Store each crack with all of its segments
ArrayList<ArrayList<PVector>> closedShapes = new ArrayList<ArrayList<PVector>>(); // Store closed shapes
ArrayList<int[]> shapeShifts = new ArrayList<int[]>();
ArrayList<PVector[]> intersect = new ArrayList<PVector[]>();

boolean addingCracks = false;

void setup() {
  size(640, 480);
  vid = new Capture(this, width, height);
  vid.start();
  stroke(255);
  frameRate(24);
} //<>//

void draw() {
  if(vid.available()) {
    vid.read();
    
    if(!addingCracks) {
      for(int i = 0; i < closedShapes.size(); i++) {
        ArrayList<PVector> shape = closedShapes.get(i);
        float minX = Float.MAX_VALUE;
        float minY = Float.MAX_VALUE;
        float maxX = Float.MIN_VALUE;
        float maxY = Float.MIN_VALUE;
        
        // Calculate the bounding box of the shape
        for (PVector vertex : shape) {
          minX = min(minX, vertex.x);
          minY = min(minY, vertex.y);
          maxX = max(maxX, vertex.x);
          maxY = max(maxY, vertex.y);
        }
        
        // Check if the index is within the bounds of shapeShifts
        if (i < shapeShifts.size()) {
          int[] shift = shapeShifts.get(i);
          shiftPix(minX, minY, maxX, maxY, shape, shift[0], shift[1]);
        }
      }
    }
    
    
  }
  image(vid, 0, 0);
  for(int i = 1; i < crackSegments.size(); i++) {
      line(crackSegments.get(i)[0].x, crackSegments.get(i)[0].y, crackSegments.get(i)[1].x, crackSegments.get(i)[1].y);
    }
}

void mousePressed() {
  cracks(mouseX, mouseY);
}

void cracks(int x, int y) {
  addingCracks = true;
  int numCracks = (int)random(2, 5);
  int numBends;
  float dist = 50;
  float firstX = x;
  float firstY = y;
  float secX;
  float secY;
  float angle;
  ArrayList<PVector> closedShape = new ArrayList<PVector>();
  
  for(int i = 0; i < numCracks; i++) {
    numBends = (int)random(1, 10);
    //start from origin
    firstX = x;
    firstY = y;
    angle = random(0, 360);
    
    if((i+1) % 2 == 0) {
      if(closedShape.size() > 0) {
        closedShape.add(new PVector(0, 0));
        closedShape.add(new PVector(width, 0));
        closedShape.add(new PVector(width, height));
        closedShape.add(new PVector(0, height));
        closedShapes.add(closedShape);
        closedShape.clear();
        
        int[] shift = {(int)random(25, 50),(int)random(25, 50)};
        shapeShifts.add(shift);
      }
    }
    
    for(int j = 0; j < numBends; j++) {
      dist = random(25, 100);
      secX = cos(radians(angle)) * dist + firstX;
      secY = sin(radians(angle)) * dist + firstY;
      
      // if last bend then make it reach the edge
      if(j == numBends -1) {
        // if none of the points reach an edge
        if(!(secX > width || secX < 0 || secY > height || secY < 0)) {
          float distX = width - secX;
          float newX = width;
          float distY = height - secY;
          float newY = height;
          // if closer to left edge
          if(distX > secX) {
            distX = secX;
            newX = 0;
          }
          if(distY > secY) {
            distY = secY;
            newY = 0;
          }
          if(distX < distY) {
            secX = newX;
          } else {
            secY = newY;
          }
        }
      }
      
      line(firstX, firstY, secX, secY);
      
      // add line to array
      PVector[] line = {new PVector(firstX, firstY), new PVector(secX, secY)};
      crackSegments.add(line);
      closedShape.add(new PVector(firstX, firstY));
      closedShape.add(new PVector(secX, secY));
    
      firstX = secX;
      firstY = secY;
      angle = random(angle - 45, angle + 45);
    }
  }
  addingCracks = false;
}


// Function to check if two intersecting segments form a closed shape
boolean segmentsFormClosedShape(PVector[] inter1, PVector[] inter2) {
  // Check if the end points of one segment match the start or end points of the other segment
  return inter1[0].equals(inter2[0]) || inter1[0].equals(inter2[1]) ||
         inter1[1].equals(inter2[0]) || inter1[1].equals(inter2[1]);
}
boolean linesIntersect(PVector p1, PVector p2, PVector p3, PVector p4) {
  float uA = ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / ((p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y));
  float uB = ((p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)) / ((p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y));
  return uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1;
}

void shiftPix(float x1, float y1, float x2, float y2, ArrayList<PVector> shape, int shiftX, int shiftY) {
  vid.loadPixels();
  
  // shift from og image
  for (int i = (int)x1; i <= x2; i++) {
    for (int j = (int)y1; j < y2; j++) {
      if (pointInPolygon(i, j, shape)) {
        int newX = i + shiftX; 
        int newY = j + shiftY;
        if (newX >= 0 && newX < width && newY >= 0 && newY < height && i > 0 && j  > 0 && i < width && j < height) {
          vid.pixels[i + j * vid.width] = vid.pixels[newX + newY * vid.width];
        }
      }
    }
  }
  vid.updatePixels();
}

boolean pointInPolygon(int x, int y, ArrayList<PVector> shape) {
  int crossings = 0;
  int numVertices = shape.size();
  for (int i = 0; i < numVertices; i++) {
    PVector v1 = shape.get(i);
    PVector v2 = shape.get((i + 1) % numVertices);
    
    // Check if the point is on the edge of the polygon
    if ((v1.y == y && v1.x <= x && v2.y == y && v2.x >= x) || (v2.y == y && v2.x <= x && v1.y == y && v1.x >= x)) {
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
