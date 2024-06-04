class Particle {
  PVector position;
  float velocity;
  float lifespan;
  color inkColor;
  
  Particle(float x, float y) {
    position = new PVector(x, y);
    velocity = random(2, 3);
    lifespan = 255;
    inkColor = color(0, 0, 0, lifespan); // black color with alpha
  }
  
  void update() {
    position.y += velocity;
    lifespan -= 5.0;
    inkColor = color(0, 0, 0, lifespan);
  }
  
  void display() {
    noStroke();
    fill(inkColor);
    ellipse(position.x, position.y, 7, 10);
  }
  
  boolean isFinished() {
    return lifespan < 0;
  }
}
