class Voronoi {
  PVector center;
  ArrayList<PVector> pixels;
  
  Voronoi(PVector center) {
    this.center = center;
    this.pixels = new ArrayList<PVector>();
  }
  
  void addPixel(int x, int y) {
    pixels.add(new PVector(x, y));
  }

  
  void update() {
  }
}
