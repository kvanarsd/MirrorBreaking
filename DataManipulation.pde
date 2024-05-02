import processing.video.*;

// FOLDER MUST CONTAIN A FILE CALLED "image.jpg"

PImage img;
PImage ogImg;

Capture vid;

ArrayList<PVector[]> crackSegments = new ArrayList<PVector[]>(); // Store line segments
ArrayList<ArrayList<PVector[]>> crackLines = new ArrayList<ArrayList<PVector[]>>(); // Store each crack with all of its segments
ArrayList<ArrayList<PVector>> closedShapes = new ArrayList<ArrayList<PVector>>(); // Store closed shapes
ArrayList<int[]> shapeShifts = new ArrayList<int[]>();
ArrayList<PVector[]> intersect = new ArrayList<PVector[]>();

void setup() {
  size(640, 480);
  vid = new Capture(this, width, height);
  vid.start();
  stroke(255);
  
  // added edges
  PVector[] edge1 = {new PVector(0, 0), new PVector(width, 0)};
  crackSegments.add(edge1);
  PVector[] edge2 = {new PVector(0, 0), new PVector(0, height)};
  crackSegments.add(edge2);
  PVector[] edge3 = {new PVector(0, height), new PVector(width, height)};
  crackSegments.add(edge3);
  PVector[] edge4 = {new PVector(width, 0), new PVector(width, height)};
  crackSegments.add(edge4);
  crackLines.add(crackSegments);
}

void captureEvent(Capture vid) {
  vid.read();
  ArrayList<ArrayList<PVector>> shapesToShift = new ArrayList<ArrayList<PVector>>();
  
  // Iterate over the closed shapes
  for(ArrayList<PVector> shape : closedShapes) {
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
    
    // Add the shape to the list of shapes to be shifted
    shapesToShift.add(shape);
  }
  
  // Process the list of shapes to be shifted
  for(int i = 0; i < shapesToShift.size(); i++) {
    ArrayList<PVector> shape = shapesToShift.get(i);
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
} //<>//

void draw() {
  image(vid, 0, 0);
  
  for(int i = 1; i < crackSegments.size(); i++) {
    line(crackSegments.get(i)[0].x, crackSegments.get(i)[0].y, crackSegments.get(i)[1].x, crackSegments.get(i)[1].y);
  }
}

void mousePressed() {
  cracks(mouseX, mouseY);
}

void cracks(int x, int y) {
  int numCracks = (int)random(2, 5);
  int numBends;
  float dist = 50;
  float firstX = x;
  float firstY = y;
  float secX;
  float secY;
  float angle;
  
  for(int i = 0; i < numCracks; i++) {
    numBends = (int)random(1, 10);
    //start from origin
    firstX = x;
    firstY = y;
    angle = random(0, 360);
    
    ArrayList<PVector[]> crack = new ArrayList<PVector[]>();;
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
      crack.add(line);
      
      firstX = secX;
      firstY = secY;
      angle = random(angle - 45, angle + 45);
    }
    crackLines.add(crack);
  }
  
  detectClosedShapes();
}

void detectClosedShapes() {
  for (int i = 0; i < crackSegments.size(); i++) {
    PVector start1 = crackSegments.get(i)[0];
    PVector end1 = crackSegments.get(i)[1];
    
    for (int j = i + 1; j < crackSegments.size(); j++) {
      PVector start2 = crackSegments.get(j)[0];
      PVector end2 = crackSegments.get(j)[1];
      
      // Check if lines intersect to form closed shape
      if (linesIntersect(start1, end1, start2, end2)) {
        PVector[] inter = {start1, end1, start2, end2};
        intersect.add(inter);
      }
    }
  }
  
  for (int i = 0; i < intersect.size(); i++) {
    for (int j = i + 1; j < intersect.size(); j++) {
      PVector[] inter1 = intersect.get(i);
      PVector[] inter2 = intersect.get(j);
      
      // Check if the two intersecting segments form a closed shape
      if (segmentsFormClosedShape(inter1, inter2)) {
        // Store the closed shape
        ArrayList<PVector> closedShape = new ArrayList<PVector>();
        closedShape.add(inter1[0]);
        closedShape.add(inter1[1]);
        closedShape.add(inter1[2]);
        closedShape.add(inter1[3]);
        closedShapes.add(closedShape);
        
        // Remove the segments used to form the closed shape
        intersect.remove(j);
        intersect.remove(i);
        
        // Reset loop indices
        i = 0;
        j = 0;
      }
    }
  }
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
        if (newX >= 0 && newX < width && newY >= 0 && newY < height) {
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
    if (((v1.y > y) != (v2.y > y)) &&
        (x < (v2.x - v1.x) * (y - v1.y) / (v2.y - v1.y) + v1.x)) {
      crossings++;
    }
  }
  return crossings % 2 != 0;
}
