/* Circle.pde - Circle abstraction
 * Jai Manacsa
 * Project 2, 12/9/2022
 */
class Circle {
  PVector center;
  float radius;
  Circle(PVector _center, float _radius) {
    center = _center;
    radius = _radius;
  }
  
  boolean is_in_circle(PVector vertex) {
    return center.dist(vertex) < radius;
  }
}
