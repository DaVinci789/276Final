/* Triangulation.pde - Delauney Triangulation
 * Jai Manacsa
 * Project 2, 12/9/2022
 */
// https://openprocessing.org/sketch/404200/
class Triangulation {
  ArrayList<PVector> vertices = new ArrayList();
  ArrayList<Triangle> triangles = new ArrayList();
  
  Triangulation(PVector v1, PVector v2, PVector v3) {
    vertices.add(v1);
    vertices.add(v2);
    vertices.add(v3);
    triangles.add(new Triangle(v1, v2, v3));
  }
  
  void add(PVector vertex) {
    if (vertices.contains(vertex)) return;
    vertices.add(vertex);
    ArrayList<Triangle> next_triangles = new ArrayList();
    ArrayList<Triangle> new_triangles = new ArrayList();
    for (int ti = 0; ti < triangles.size(); ti++) {
      Triangle tri = triangles.get(ti);
      if (tri.circum_circle.is_in_circle(vertex))
        new_triangles.addAll(tri.divide(vertex));
      else
        next_triangles.add(tri);
    }
    
    for (int ti = 0; ti < new_triangles.size(); ti++) {
      Triangle tri = new_triangles.get(ti);
      boolean isIllegal = false;
      for (int vi = 0; vi < vertices.size(); vi++) {
        if (is_illegal_triangle(tri, vertices.get(vi))) {
          isIllegal = true;
          break;
        }
      }
      if (!isIllegal) {
        next_triangles.add(tri);
      }
    }
    
    triangles = next_triangles;
  }
  
  boolean is_illegal_triangle(Triangle t, PVector v) {
    if (t.is_contain(v)) return false;
    return t.circum_circle.is_in_circle(v);
  }
  
  void render() {
    for (Triangle t: triangles) {
      t.render();
    }
  }
  
}
