class Voronoi {
  PVector center;
  ArrayList<PVector> pixels;
  PVector velocity;
  
  Voronoi(PVector center) {
    this.center = center;
    this.pixels = new ArrayList<PVector>();
    this.velocity = new PVector(0, 0);
  }
  
  void addPixel(int x, int y) {
    pixels.add(new PVector(x, y));
  }
  
  void setVelocity(PVector velocity) {
    this.velocity = velocity;
  }
  
  void update() {
    for (PVector p : pixels) {
      p.add(velocity);
    }
  }
}
