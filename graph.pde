/* graph.pde - Logic of Save the Trees!
 * Jai Manacsa
 * Project 2, 12/9/2022
 */
import java.util.List;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.Iterator;
import oscP5.*;
import netP5.*;

OscP5 oscp5;
NetAddress addr;

PImage bg;
PImage lg;
PFont font;

// 50px margin that the points cannot leave.
float margin = 50;
PVector[] points;

// connections from each point to another. (i, j) = connections[i][_] = j
int[][] connections;

// Num of connections conserved
int current_conserved = 0;
int[][] conserved;

// end points of connection player is hovering over
PVector c1;
PVector c2;

// data sent to puredata
int c2note = -1;

// Delauney Triangulation helper
Triangulation tri;
boolean timer_start = false;
int timer = 0;
boolean found = false; // overlapping hover
boolean yourgo = false;
boolean con_win = false;
String message_type = "/note";

enum Scene {
  TITLE,
  PLAY,
  END,
  IP,
};

class Player {
  color hover;
  int play; // 0 continue -1 lose 1 win

  Player(color _hover) {
    hover = _hover;
    play = 0;
  }
};

Player logger = new Player(color(255, 0, 0));
Player conserve = new Player(color(252, 186, 0));
Player current_player = null;

void init_points(PVector[] the_points) {
  for (int i = 0; i < the_points.length; i++) {
    PVector to_place = new PVector(random(margin, width-2*margin), random(margin-20, height - 2*margin));
    boolean ok = true;
    for (int j = 0; j < points.length; j++) {
      if (points[j] != null && points[j].dist(to_place) < 200) ok = false;
    }
    if (!ok) {
      i -= 1;
      continue;
    }
    points[i] = to_place;
  }
}

void init_game() {
  points = new PVector[8];
  connections = new int[points.length][2];
  current_conserved = 0;
  conserved = new int[points.length * 2][2];
  con_win = false;
  logger.play = 0;
  conserve.play = 0;

  for (int[] arr: connections) {
    for (int i = 0; i < arr.length; i++)
      arr[i] = -1;
  }

  for (int[] arr: conserved) {
    for (int i = 0; i < arr.length; i++)
      arr[i] = -1;
  }

  init_points(points);
  tri = new Triangulation(
    points[0], points[1], points[2]
  );
  for (int i = 3; i < points.length; i++) {
    tri.add(points[i]);
  }
  for (Triangle t: tri.triangles) {
    connections[vertex_to_index(t.vec1)][0] = vertex_to_index(t.vec2);
    connections[vertex_to_index(t.vec1)][1] = vertex_to_index(t.vec3);
  }
  
  ArrayList<PVector> seen = new ArrayList<PVector>();
  
  for (int i = 0; i < connections.length; i++) {
    for (int j = 0; j < connections[i].length; j++) {
      if (seen.contains(new PVector(connections[i][j], i))) {
        connections[i][j] = -1;
        continue;
      }
      seen.add(new PVector(i, connections[i][j]));
    }
  }
}

boolean bfs() {
  // construct adjacency list
  LinkedList<Integer> adj[] = new LinkedList[points.length];
  for (int i = 0; i < points.length; i++) adj[i] = new LinkedList();
  for (int i = 0; i < points.length; i++) {
    adj[i].add(connections[i][0]);
    adj[i].add(connections[i][1]);
    if (connections[i][0] != -1) adj[connections[i][0]].add(i);
    if (connections[i][1] != -1) adj[connections[i][1]].add(i);
  }

  boolean visited[] = new boolean[points.length];
  LinkedList<Integer> queue = new LinkedList<Integer>();
  visited[0] = true;
  queue.add(0);

  int node = 0;
  while (queue.size() != 0) {
    node = queue.poll();
    // Get all adjacent vertices of the dequeued vertex s
    // If a adjacent has not been visited, then mark it
    // visited and enqueue it
    Iterator<Integer> i = adj[node].listIterator();
    while (i.hasNext()) {
      int n = i.next();
      if (n == -1) continue;

      if (!visited[n]) {
        visited[n] = true;
        queue.add(n); //<>// //<>// //<>//
      }
    }
  }
  for (boolean b: visited) if (!b) return false;
  return true;
}

int vertex_to_index(PVector vertex) {
  for (int i = 0; i < points.length; i++) {
    if (points[i] == vertex) return i;
  }
  return -1;
}

// http://www.jeffreythompson.org/collision-detection/poly-point.php
boolean polyPoint(PVector[] vertices, float px, float py) {
  boolean collision = false;

  // go through each of the vertices, plus
  // the next vertex in the list
  int next = 0;
  for (int current=0; current<vertices.length; current++) {

    // get next vertex in list
    // if we've hit the end, wrap around to 0
    next = current+1;
    if (next == vertices.length) next = 0;

    // get the PVectors at our current position
    // this makes our if statement a little cleaner
    PVector vc = vertices[current].copy();    // c for "current"
    PVector vn = vertices[next].copy();       // n for "next"
    vc.x += margin;
    vc.y += margin;
    vn.x += margin;
    vn.y += margin;

    // compare position, flip 'collision' variable
    // back and forth
    if (((vc.y >= py && vn.y < py) || (vc.y < py && vn.y >= py)) &&
         (px < (vn.x-vc.x)*(py-vc.y) / (vn.y-vc.y)+vc.x)) {
            collision = !collision;
    }
  }
  return collision;
}

// Draw a rotated rectangle between two points
void connection(PVector start, PVector end) {

  float m = ((end.y - start.y) / (end.x - start.x));

  PVector[] vertices = new PVector[4];

  float w = 10;
  m = -1 / m;

  float y0 = m * (-m * (((-2 * start.y) / pow(m, 2)) - 2 * start.y) + 2 * w * (sqrt(1 + pow(m, 2)))) / (2 * (pow(m, 2) + 1));
  float y1 = m * (-m * (((-2 * start.y) / pow(m, 2)) - 2 * start.y) - 2 * w * (sqrt(1 + pow(m, 2)))) / (2 * (pow(m, 2) + 1));
  float y2 = m * (-m * (((-2 * end.y) / pow(m, 2)) - 2 * end.y) + 2 * w * (sqrt(1 + pow(m, 2)))) / (2 * (pow(m, 2) + 1));
  float y3 = m * (-m * (((-2 * end.y) / pow(m, 2)) - 2 * end.y) - 2 * w * (sqrt(1 + pow(m, 2)))) / (2 * (pow(m, 2) + 1));

  vertices[0] = new PVector(start.x + w / (sqrt(1 + pow(m, 2))), y0);
  vertices[1] = new PVector(start.x - w / (sqrt(1 + pow(m, 2))), y1);
  vertices[2] = new PVector(end.x - w / (sqrt(1 + pow(m, 2))), y3);
  vertices[3] = new PVector(end.x + w / (sqrt(1 + pow(m, 2))), y2);

  boolean collision = polyPoint(vertices, mouseX, mouseY);

  int first = vertex_to_index(start);
  int second = vertex_to_index(end);

  if (second < first) {
    int temp = first;
    first = second;
    second = temp;
  }

  boolean found = false;
  for (int[] arr: conserved) {
    if (arr[0] == first && arr[1] == second) {
      fill(conserve.hover);
      collision = false;
      found = true;
      break;
    }
  }
  if (!found) con_win = false;

  if (collision && !found) {
    fill(current_player.hover);
    found = true;
    c1 = start;
    c2 = end;
  }

  beginShape();
  stroke(0, 0, 0, 0);
  vertex(vertices[0].x, vertices[0].y);
  vertex(vertices[1].x, vertices[1].y);
  vertex(vertices[2].x, vertices[2].y);
  vertex(vertices[3].x, vertices[3].y);
  endShape();
  stroke(0);
  fill(255,255,255,255);
}

void mouseClicked(MouseEvent e) {
  if (c1 == null) return;
  int first = vertex_to_index(c1);
  int second = vertex_to_index(c2);
  if (second < first) {
    int temp = first;
    first = second;
    second = temp;
  }
  if (current_player == logger) {
    for (int i = 0; i < 2; i++) {
      if (connections[vertex_to_index(c1)][i] == vertex_to_index(c2)) {
        connections[vertex_to_index(c1)][i] = -1;
      }
    }

    for (int i = 0; i < 2; i++) {
      if (connections[vertex_to_index(c2)][i] == vertex_to_index(c1)) {
        connections[vertex_to_index(c2)][i] = -1;
      }
    }
    current_player = conserve;
    message_type = "/sote";
  } else if (current_player == conserve) {
    conserved[current_conserved][0] = first;
    conserved[current_conserved][1] = second;
    current_conserved += 1;
    current_player = logger;
    message_type = "/note";
  }

  if (!bfs()) {
    logger.play = 1;
    conserve.play = -1;
  } else if (con_win) {
    conserve.play = 1;
    logger.play = -1;
  }

  OscMessage m = new OscMessage(message_type);
  m.add((int) c1.y % 6);
  oscp5.send(m, addr);
  timer_start = true;
  timer = 20;
  c2note = (int) c2.y;
}

void keyPressed(KeyEvent e) {
  if (e.getKey() == 'r') {
    do {
      init_game();
    } while (tri.triangles.size() < 5 || !bfs());
    for (int[] arr: connections) {
      print("[");
      for (int i: arr) {
        print(i, " ");
      }
      print("] ");
    }
    println();

    bfs();
  }
  if (e.getKey() == 'm') {
    OscMessage m = new OscMessage("/mute");
    m.add(0);
    oscp5.send(m, addr);
  }
}

void setup() {
  surface.setTitle("Save the Trees!");
  oscp5 = new OscP5(this, 9001);
  addr  = new NetAddress("127.0.0.1", 9001);

  current_player = conserve;
  rectMode(CORNERS);
  size(1366, 768);

  font = loadFont("GoudyOldStyleT-Bold-48.vlw");
  bg = loadImage("trees.png");
  lg = loadImage("letsgo.jpg");

  do {
    init_game();
  } while (tri.triangles.size() < 5 || !bfs());
  bfs();
  for (int[] arr: connections) {
    print("[");
    for (int i: arr) {
      print(i, " ");
    }
    print("] ");
  }
  println();
}

void timer_check() {
  if (timer != 0 || !timer_start) return;
  OscMessage m = new OscMessage(message_type);
  m.add((int) c2note % 6);
  oscp5.send(m, addr);
  timer_start = false;
}

void draw() {
  con_win = true;
  if (timer > 0) {
    timer -= 1;
  }
  timer_check();

  textFont(font, 48);
  found = false;
  c1 = null;
  c2 = null;

  background(0);
  
  colorMode(HSB, 360);
  for (int i = 0; i < 6; i++) {
    fill(color(160 - i * 8, 200 + i * 10, 190 + i * 20));
    stroke(0,0,0,0);
    rect(0, (height / 6) * i, width, (height / 6) * (i + 1));
  }

  colorMode(RGB, 255);
  tint(255, 90);
  image(bg, 0, 0, width, height);
  fill(255);
  stroke(0);
  pushMatrix();
  translate(margin, margin);

  for (int i = 0; i < connections.length; i++) {
    for (int j = 0; j < connections[i].length; j++) {
      if (connections[i][j] == -1) continue;
      connection(points[i], points[connections[i][j]]);
    }
  }
  for (int i = 0; i < points.length; i++) {
    PVector p = points[i];
    circle(p.x, p.y, 30);
    //text(String.format("%d", i), p.x, p.y);
  }
  
  popMatrix();
  stroke(0);
  String display = "NA";
  if (current_player == logger)
    display = "Logger";
  else
    display = "Conservationist";

  if (logger.play == 1) {
    display = "Logger wins! :(";
  } else if (con_win) {
    display = "Conservationist wins! :D";
    image(lg, 30, 30, 300, 300);
  }
  text(display, 50, 60);
}
