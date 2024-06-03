class Triangle {
  PVector p1, p2, p3;
  PVector circumcenter;
  float circumradius;

  Triangle(PVector p1, PVector p2, PVector p3) {
    this.p1 = p1;
    this.p2 = p2;
    this.p3 = p3;
    calculateCircumcircle();
  }

  void calculateCircumcircle() {
    float dA = p1.x * p1.x + p1.y * p1.y;
    float dB = p2.x * p2.x + p2.y * p2.y;
    float dC = p3.x * p3.x + p3.y * p3.y;

    float aux1 = (dA * (p3.y - p2.y) + dB * (p1.y - p3.y) + dC * (p2.y - p1.y));
    float aux2 = -(dA * (p3.x - p2.x) + dB * (p1.x - p3.x) + dC * (p2.x - p1.x));
    float div = (2 * (p1.x * (p3.y - p2.y) + p2.x * (p1.y - p3.y) + p3.x * (p2.y - p1.y)));

    if (div == 0) {
      circumcenter = new PVector(Float.MAX_VALUE, Float.MAX_VALUE);
      circumradius = Float.MAX_VALUE;
    } else {
      circumcenter = new PVector(aux1 / div, aux2 / div);
      circumradius = PVector.dist(circumcenter, p1);
    }
  }

  boolean circumcircleContains(PVector p) {
    return PVector.dist(circumcenter, p) <= circumradius;
  }

  Edge[] getEdges() {
    return new Edge[] {
      new Edge(p1, p2),
      new Edge(p2, p3),
      new Edge(p3, p1)
    };
  }

  boolean hasVertex(PVector p) {
    return (p.equals(p1) || p.equals(p2) || p.equals(p3));
  }

  PVector[] getPoints() {
    return new PVector[] { p1, p2, p3 };
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
