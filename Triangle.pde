/* Triangle.pde - Triangle abstraction
 * Jai Manacsa
 * Project 2, 12/9/2022
 */
class Triangle {
  PVector vec1;
  PVector vec2;
  PVector vec3;
  Circle circum_circle;
  Triangle(PVector v1, PVector v2, PVector v3) {
    vec1 = v1;
    vec2 = v2;
    vec3 = v3;
    float c = 2 * ((v2.x - v1.x) * (v3.y - v1.y) - (v2.y - v1.y) * (v3.x - v1.x));
    float x = ((v3.y - v1.y) * (sq(v2.x) - sq(v1.x) + sq(v2.y) - sq(v1.y)) + (v1.y - v2.y) * (sq(v3.x) - sq(v1.x) + sq(v3.y) - sq(v1.y))) / c;
    float y = ((v1.x - v3.x) * (sq(v2.x) - sq(v1.x) + sq(v2.y) - sq(v1.y)) + (v2.x - v1.x) * (sq(v3.x) - sq(v1.x) + sq(v3.y) - sq(v1.y))) / c;
    PVector center = new PVector(x, y);
    float radius = v1.dist(center);
    circum_circle = new Circle(center, radius);
  }
  
  ArrayList<Triangle> divide(PVector v) {
    ArrayList<Triangle> tris = new ArrayList();
    tris.add(new Triangle(vec1, vec2, v));
    tris.add(new Triangle(vec2, vec3, v));
    tris.add(new Triangle(vec3, vec1, v));
    return tris;
  }
  
  
  boolean is_contain(PVector v) {
    if (vec1 == v) return true;
    if (vec2 == v) return true;
    if (vec3 == v) return true;
    return false;
  }
  
  void render() {
    /*beginShape();
    vertex(vec1.x, vec1.y);
    vertex(vec2.x, vec2.y);
    vertex(vec3.x, vec3.y);
    print(vec1);
    endShape(CLOSE);*/
    fill(0,0,0,0);
    triangle(vec1.x, vec1.y, vec2.x, vec2.y, vec3.x, vec3.y);
  }
}
