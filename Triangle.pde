class Triangle {
  PVector p1, p2, p3;
  PVector circumcenter;
  float circumradius;
  PVector shift;

  Triangle(PVector p1, PVector p2, PVector p3) {
    this.p1 = p1;
    this.p2 = p2;
    this.p3 = p3;
    this.shift = new PVector((int)random(-15, 15),(int)random(-15, 15));
    calculateCircumcircle();
  }

  void calculateCircumcircle() {
    float ax = p1.x, ay = p1.y;
    float bx = p2.x, by = p2.y;
    float cx = p3.x, cy = p3.y;

    float d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));
    float ux = ((ax*ax + ay*ay) * (by - cy) + (bx*bx + by*by) * (cy - ay) + (cx*cx + cy*cy) * (ay - by)) / d;
    float uy = ((ax*ax + ay*ay) * (cx - bx) + (bx*bx + by*by) * (ax - cx) + (cx*cx + cy*cy) * (bx - ax)) / d;

    circumcenter = new PVector(ux, uy);
    circumradius = dist(ux, uy, ax, ay);
  }

  boolean circumcircleContains(PVector p) {
    return dist(p.x, p.y, circumcenter.x, circumcenter.y) < circumradius;
  }

  boolean hasVertex(PVector p) {
    return p.equals(p1) || p.equals(p2) || p.equals(p3);
  }

  ArrayList<Edge> getEdges() {
    ArrayList<Edge> edges = new ArrayList<Edge>();
    edges.add(new Edge(p1, p2));
    edges.add(new Edge(p2, p3));
    edges.add(new Edge(p3, p1));
    return edges;
  }
}

class Edge {
  PVector p1, p2;

  Edge(PVector p1, PVector p2) {
    this.p1 = p1;
    this.p2 = p2;
  }

  boolean equals(Edge other) {
    return (p1.equals(other.p1) && p2.equals(other.p2)) || (p1.equals(other.p2) && p2.equals(other.p1));
  }
}
