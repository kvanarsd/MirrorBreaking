import processing.video.*;

// FOLDER MUST CONTAIN A FILE CALLED "image.jpg"

PImage img;
PImage ogImg;

Capture vid;

ArrayList<float[]> crackLines = new ArrayList<float[]>(); // Store crack lines
ArrayList<ArrayList<PVector>> closedShapes = new ArrayList<ArrayList<PVector>>(); // Store closed shapes
ArrayList<int[]> shapeShifts = new ArrayList<int[]>();

void setup() {
  size(640, 480);
  vid = new Capture(this, width, height);
  vid.start();
  img = loadImage("image.jpg");
  ogImg = loadImage("image.jpg");
  img.resize(600,600);
  ogImg.resize(600,600);
  //image(img, 0, 0);
  stroke(255);
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
  for(ArrayList<PVector> shape : shapesToShift) {
    float minX = Float.MAX_VALUE;
    float minY = Float.MAX_VALUE;
    float maxX = Float.MIN_VALUE;
    float maxY = Float.MIN_VALUE;
    int index = 0;
    for (PVector vertex : shape) {
      minX = min(minX, vertex.x);
      minY = min(minY, vertex.y);
      maxX = max(maxX, vertex.x);
      maxY = max(maxY, vertex.y);
      shiftPix(minX,minY,maxX,maxY, shape, shapeShifts.get(index)[0],shapeShifts.get(index)[1]);
      index++;
    }
  }
}

void draw() {
  image(vid, 0, 0);
  
  for(int i = 1; i < crackLines.size(); i++) {
    line(crackLines.get(i)[0], crackLines.get(i)[1], crackLines.get(i)[2], crackLines.get(i)[3]);
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
    for(int j = 0; j < numBends; j++) {
      dist = random(25, 100);
      secX = cos(radians(angle)) * dist + firstX;
      secY = sin(radians(angle)) * dist + firstY;
      line(firstX, firstY, secX, secY);
      
      // add line to array
      float[] line = {firstX, firstY, secX, secY};
      crackLines.add(line);
      
      firstX = secX;
      firstY = secY;
      angle = random(angle - 45, angle + 45);
    }
  }
  
  detectClosedShapes();
}

void detectClosedShapes() {
  for (int i = 0; i < crackLines.size(); i++) {
    float[] line1 = crackLines.get(i);
    PVector start1 = new PVector(line1[0], line1[1]);
    PVector end1 = new PVector(line1[2], line1[3]);
    
    for (int j = i + 1; j < crackLines.size(); j++) {
      float[] line2 = crackLines.get(j);
      PVector start2 = new PVector(line2[0], line2[1]);
      PVector end2 = new PVector(line2[2], line2[3]);
      
      // Check if lines intersect to form closed shape
      if (linesIntersect(start1, end1, start2, end2)) {
        ArrayList<PVector> closedShape = new ArrayList<PVector>();
        closedShape.add(start1);
        closedShape.add(end1);
        closedShape.add(end2);
        closedShape.add(start2);
        closedShapes.add(closedShape);
        
        // add shift
        int shiftX = (int)random(-50, 50);
        int shiftY = (int)random(-50, 50);
        int[] shift = {shiftX,shiftY};
        shapeShifts.add(shift);
      }
    }
  }
}

boolean linesIntersect(PVector p1, PVector p2, PVector p3, PVector p4) {
  float uA = ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / ((p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y));
  float uB = ((p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)) / ((p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y));
  return uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1;
}

void shiftPix(float x1, float y1, float x2, float y2, ArrayList<PVector> shape, int shiftX, int shiftY) {
  //shift
  

  vid.loadPixels();
  
  /*/ if shift is negative but close to edge
  if(x - (w/2) + shiftX < 0) {
    shiftX = (int)random(50);
  } else if(x + w + shiftX > width) {   
    shiftX = (int)random(-200, -w);
  }
  // check y shift
  if(y - (h/2) + shiftY < 0) {
    shiftY = (int)random(50);
  } else if(y + h + shiftY > height) {   
    shiftY = (int)random(-200, -h);
  }*/
  
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
  /*
  // put shifted pixels into displayed image
  for (int i = 0; i < w && (x + i - (w/2)) < width; i++) {
    // don't update anypixels that are out of range
    if((x + i - (w/2)) < 0) { continue; }
    
    for (int j = 0; j < h && (y + j - (h/2)) < height; j++) {
      // don't update anypixels that are out of range
      if((y + j - (h/2)) < 0) { continue; }
      
      // put shifted pixels in the middle of the mouse
      img.pixels[(x + i - (w/2)) + (y + j - (h/2)) * img.width] = tempPixels[i + j * w];
    }
  }*/

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
