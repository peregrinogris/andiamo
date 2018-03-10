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
int currDrawFile;
Stroke currStroke;
Stroke lastStroke;
boolean looping;
boolean fixed;
boolean dissapearing;
boolean grouping;

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

  currLayer = 0;
  layers = new ArrayList[4];
  for (int i = 0; i < 4; i++) {
    layers[i] = new ArrayList<Stroke>();
  }

  currDrawFile = 0;
  loadDrawing();

  lastStroke = null;
  currStroke = new Stroke(0, dissapearing, fixed, currTexture, lastStroke);
  println("Selected stroke layer: " + 1);
}

// force enables a total cleanup of the screen
void cleanup(boolean force) {
  for (int i = 0; i < layers.length; i++) {
    for (int j = layers[i].size() - 1; j >= 0; j--) {
      Stroke stroke = (Stroke)layers[i].get(j);
      if (force || (!stroke.isVisible() && !stroke.isLooping())) {
        layers[i].remove(j);
      }
    }
  }
}

// default version of cleanup is to just remove old strokes
void cleanup() {
  cleanup(false);
}

void loadDrawing() {
  DRAW_FILENAME = DRAW_FILENAMES[currDrawFile];
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
  currDrawFile = (currDrawFile + 1) % DRAW_FILENAMES.length;
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