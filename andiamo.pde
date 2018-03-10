// Andiamo 14
// Compatible with Processing 3.x
// Uses P2D by default

import java.io.*;

//import codeanticode.tablet.*;
//Tablet tablet;

ArrayList<Stroke>[] layers;
int currLayer;
ArrayList<PImage> textures;
int currTexture;
Stroke currStroke;
Stroke lastStroke;
boolean looping;
boolean fixed;
boolean dissapearing;
boolean grouping;
PImage backImg;

/**
 * Sets the sketch in fullscreen
 * @return true
 */
void settings() {
  if (FULL_SCREEN) fullScreen(P2D, DISPLAY_SCREEN);
  else size(RES_WIDTH, RES_HEIGHT, P2D);
}

void setup() {
  noCursor();
  smooth(8);
  startup();

  // Call it at the end of setup, as startup() is blocking
  // 60 fps is the default framerate
  if (FRAMERATE != 60) frameRate(FRAMERATE);
}

void draw() {
  background(0);
  if (backImg != null) {
    image(backImg, width/2 - backImg.width/2, height/2 - backImg.height/2);
  }
  int t = millis();
  for (int i = 0; i < layers.length; i++) {
    for (Stroke stroke: layers[i]) {
      stroke.update(t);
      stroke.draw(g);
    }
  }
  if (currStroke != null) {
    currStroke.update(t);
    currStroke.draw(g);
  }
  // Call cleanup once every few frames, off the main thread
  if (frameCount % 600 == 0) thread("cleanup");
}

void startup() {
  //tablet = new Tablet(this);
  initRibbons();
  textures = new ArrayList<PImage>();
  for (int i = 0; i < TEXTURE_FILES.length; i++) {
    textures.add(loadImage(TEXTURE_FILES[i]));
  }

  File file = new File(dataPath("background.png"));
  if (file.exists()) {
    backImg = loadImage("background.png");
  }

  looping = LOOPING_AT_INIT;
  println("Looping: " +  looping);

  fixed = FIXED_STROKE_AT_INIT;
  println("Fixed: " +  fixed);

  dissapearing = DISSAPEARING_AT_INIT;
  println("Dissapearing: " +  looping);

  grouping = false;
  println("Gouping: " +  grouping);

  currTexture = 0;
  textureMode(NORMAL);

  layers = new ArrayList[4];
  for (int i = 0; i < 4; i++) {
    layers[i] = new ArrayList<Stroke>();
  }
  loadDrawing();
  currLayer = 0;
  lastStroke = null;
  currStroke = new Stroke(0, dissapearing, fixed, currTexture, lastStroke);
  println("Selected stroke layer: " + 1);
}

void cleanup() {
  for (int i = 0; i < layers.length; i++) {
    for (int j = layers[i].size() - 1; j >= 0; j--) {
      Stroke stroke = (Stroke)layers[i].get(j);
      if (!stroke.isVisible() && !stroke.isLooping()) {
        layers[i].remove(j);
      }
    }
  }
}

void loadDrawing() {
  File file = new File(dataPath(DRAW_FILENAME));
  if (file.exists()) {
    XML xml = loadXML(DRAW_FILENAME);
    if (xml != null) {
      for (int i = 0; i < layers.length; i++) {
        XML layer = xml.getChild("layer" + i);
        XML[] children = layer.getChildren("stroke");
        for (int n = 0; n < children.length; n++) {
          Stroke stroke = new Stroke(children[n]);
          layers[i].add(stroke);
        }
      }
      println("Loaded drawing from " + DRAW_FILENAME);
    }
  }
}

void saveDrawing() {
  String str = "<?xml version=\"1.0\"?>\n";
  str += "<drawing>\n";
  for (int i = 0; i < layers.length; i++) {
    str += "<layer" + i + ">\n";
    for (Stroke stroke: layers[i]) {
      str += stroke.toXML();
    }
    str += "</layer" + i + ">\n";
  }
  str += "</drawing>\n";
  String[] lines = split(str, "\n");
  saveStrings("data/" + DRAW_FILENAME, lines);
  println("Saved current drawing to " + DRAW_FILENAME);
}