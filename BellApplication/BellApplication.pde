// BELLS //
/* CLICK AND DRAG: move the bell in the space. 
   x coordinate --> duration 
   y coordinate --> volume of the bell
   mouse wheel up --> increases bell dimension --> decreases frequency
   mouse wheel down --> decreases bell dimension --> increases frequency
   QWER |
   ASDF |--> these keys allow to play the bells
   ZXCV |
*/

/* wwwww Notes. At the moment: wwwwww
- bells are drawn in order in the array --> the first will be always BEHIND the last in order of index
- the increasing size is done with RELOADING the image in order to not lose quality, but it is slow
- bells can't be selected simoultaneously
*/

import oscP5.*;
import netP5.*;

// Declare an object used to comunicate with SuperCollider
OscP5 oscP5;
NetAddress myRemoteLocation;
OscMessage myMessage;

int num = 12;  //number of bells in the application
int pres = 4;   //number of presets
int index;     //index to select the background
int preset;    //number of preset selected
PFont font;
Bell[] bells = new Bell[num];
Button[] presets = new Button[pres];
Button reset = new Button(1160, 660, 100, "Reset");
Button play = new Button(20, 660, 100, "Play");


void setup(){
   size(1280,720);
   noStroke();
   
   //font used for the bells labels
   font = createFont("Arial Bold", 18);
   textFont(font);
   textAlign(CENTER, CENTER);
   
   preset = 0; //reset the preset to default value
   
   //used to place the bells in a line, at the same distance one from the other.
   float xInitDistance = width / (num+1.0); 
   float yInit = height / 2.0;
   // creating the bells
   for (int i =0; i<num; i++){
     String l;
     char k;
     switch (i){
       case 0: l="Q"; k='q'; break;
       case 1: l="W"; k='w'; break;
       case 2: l="E"; k='e'; break;
       case 3: l="R"; k='r'; break;
       case 4: l="A"; k='a'; break;
       case 5: l="S"; k='s'; break;
       case 6: l="D"; k='d'; break;
       case 7: l="F"; k='f'; break;
       case 8: l="Z"; k='z'; break;
       case 9: l="X"; k='x'; break;
       case 10: l="C"; k='c'; break;
       case 11: l="V"; k='v'; break;
       default: l="p"; k='p'; break;
     }
     bells[i] = new  Bell(xInitDistance*(i+1.0), yInit, "bell-icons-16638.png", l, k);
   }
   // create preset buttons 
   for (int i=0; i<pres; i++){
     presets[i] = new Button(20+(i*110), 20, 90, "Preset "+str(i+1));
   }
   // start oscP5, listening for incoming messages at port 12000
   oscP5 = new OscP5(this, 12000);
   // Initializing the Remote location
   myRemoteLocation = new NetAddress("127.0.0.1",57120);
   
   OscMessage indexChange = new OscMessage("/indexChange");
   indexChange.add(index);
   oscP5.send(indexChange, myRemoteLocation);
}

void draw() {
  update();
  //displaying buttons to change backgrounds
  if(index != 0)
    triangle(10, 360, 24, 346, 24, 374);
  if(index != 3)
    triangle(1270, 360, 1256, 346, 1256, 374);
  //displaying bells and their text
  for (Bell b : bells) {
    b.display();
  }
  //displaying preset buttons
  for (Button p: presets){
    p.display();
  }
  //displaying reset button
  reset.display();
  //displaying play button
  play.display();

  OscMessage bellState = new OscMessage("/bellState");
  for (Bell b : bells) {
    bellState.add((b.xBell / width) * 10);
    bellState.add(-(b.yBell - height) / height);
    bellState.add(2328 - (b.widthBell * 6.98)); // We rescale the width to correspond to a frequency varying from C4 262Hz, to C7 2093Hz
  }
  bellState.add(index);
  oscP5.send(bellState, myRemoteLocation);
}

// ----- methods ----- //
void mouseMoved() {
  for (Bell b:bells){
    b.mouseMoved();
  }
  for (Button b:presets){
    b.mouseMoved();
  }
  reset.mouseMoved();
  play.mouseMoved();
}
void mousePressed() {
  for (Bell b:bells){
    b.mousePressed();
  }
  for (Button b:presets){
    if(b.isMouseOver)
      b.mousePressed();
  }
  if(reset.isMouseOver)
    reset.mousePressed();
  if(play.isMouseOver)
    play();
  
  OscMessage indexChange = new OscMessage("/indexChange");
  
  if(mouseX > 10 && mouseX < 24 &&
     mouseY > 346 && mouseY < 374 && index>0){
    index -= 1;
    indexChange.add(index);
    oscP5.send(indexChange, myRemoteLocation);
    update();
  }
  
  if(mouseX > 1256 && mouseX < 1270 &&
     mouseY > 346 && mouseY < 374 && index<3){
    index += 1;
    indexChange.add(index);
    oscP5.send(indexChange, myRemoteLocation);
    update();
  }
     
}
void mouseDragged(){
  for (Bell b:bells){
    b.mouseDragged();
  }
}
void mouseReleased(){
  for (Bell b:bells){
    b.mouseReleased();
  }
}

void mouseWheel(MouseEvent event){
  for (Bell b:bells){
    b.mouseWheel(event);
  }
}

void keyPressed(){
  for (Bell b:bells){
    b.setOn(key);
  }
  if(key == '1'){
    presets[0].isMouseOver = true;
    presets[0].mousePressed();
  }
  if(key == '2'){
    presets[1].isMouseOver = true;
    presets[1].mousePressed();
  }
  if(key == '3'){
    presets[2].isMouseOver = true;
    presets[2].mousePressed();
  }
  if(key == '4'){
    presets[3].isMouseOver = true;
    presets[3].mousePressed();
  }
  if(key == DELETE){
    println("Reset");
    setup();
  }
}
void keyReleased(){
  for (Bell b:bells){
    b.setOff(key);
  }
}

void play(){
  OscMessage playBellsMessage = new OscMessage("/playBells");
  println("Preset: "+str(preset));
  playBellsMessage.add(preset);
  oscP5.send(playBellsMessage, myRemoteLocation);
}

void update(){
  switch(index){
    case 0:
      PImage image0 = loadImage("interno_campanile.jpg");
      background(image0);
      fill(0);
      break;
    case 1: 
      PImage image1 = loadImage("church.jpg");
      background(image1);
      fill(200);
      break;
    case 2: 
      PImage image2 = loadImage("auditorium.jpg");
      background(image2);
      fill(255);
      break;
    case 3: 
      PImage image3 = loadImage("mountain.jpg");
      background(image3);
      fill(0);
      break;
    default: fill(0); break;
  }
}

// -------------------

class Bell {
  // coordinates of the center of the bell
  float xBell;
  float yBell;
  PImage imageBell;
  String name;
  // corresponding key to play the bell
  char keyBell;
  String letterBell;
  // initial dimension of the bell,used in resize. height is final to mantain proportions.
  // only widthBell will change.
  /*final*/ int heightBell = 0;
  int widthBell = 80;
  // tint of the bell. Decreasing R to 200 when selecting a bell.
  int R = 230;
  // controls whether we are over the bell, and dragging (holding the mouse)
  boolean isMouseOver;
  boolean isBellHeld;
  boolean isBellOn;
  // offsets used during dragging;
  float offsetx;
  float offsety;
  
  // -- constructor. Inputs: x coordinate (middle), y coordinate (middle), name of the file of the image.
  Bell(float x, float y, String imageNameAsString, String l, char k){
    xBell = x;
    yBell = y;
    name = imageNameAsString;
    keyBell = k;
    letterBell = l;
    imageBell = loadImage(name);
    heightBell = imageBell.height;
    imageBell.resize(80,0);
  }
  
  // -- display method
  void display(){
    // modifies the filter colour of the image
    tint(R,255,255);
    // image takes as input the coordinate of the upper left corner of the image.
    image(imageBell, xBell-(imageBell.width / 2.0), yBell-(imageBell.height / 2.0));
    text(letterBell, xBell, yBell-imageBell.height/2.0-10);
  }
  
  // -- methods for dragging the picture 
  /* check if the mouse is over the picture, and changes its colour */
  void mouseMoved(){
    if (mouseX>(xBell-imageBell.width/2.0) && mouseX<(xBell+imageBell.width/2.0) &&
      mouseY>(yBell-imageBell.height/2.0) && mouseY<(yBell+imageBell.height/2.0)){
      isMouseOver=true;
      if(isBellOn) R = 100;
      else R = 255;
    }
    else {
      isMouseOver=false;
      if(isBellOn) R = 0;
      else R=200;
    }
  }
  /* when the mouse is pressed, changes the boolean and changes the colour to green */ 
  void mousePressed() {
    if (isMouseOver) {
      for(Bell b: bells)
        b.isBellHeld = false;
      isBellHeld=true;
      //set the difference between where wouse was clicked and the center of the bell
      offsetx = mouseX-xBell;
      offsety = mouseY-yBell;
    }
  }
  /* when the mouse is dragged, make the bell move with the mouse*/
  void mouseDragged(){
    if(isBellHeld){
      xBell = mouseX - offsetx;
      yBell = mouseY - offsety;
    }
  }
  
  /* when the mouse is release, changes the boolean and changes the colour back */
  void mouseReleased(){
    if (isBellHeld) {
      isBellHeld = false;
      if (isMouseOver) R = 255; /* mouse still over the bell */ 
      else R = 200; /* mouse not over the bell */ 
    }
  }
  
  /* when the mouse weel is turned, if over a bell, the bell gets bigger/smaller. the WIDTH is SUMMED to the value obtained from the wheel itself */
  void mouseWheel(MouseEvent event){
    if(isMouseOver && widthBell - 6*event.getCount() >= 34 && widthBell - 6*event.getCount() <= 300){   // minimum width is 34 and max width is 300 (chosen to respect the frequency range)
       redraw(xBell, yBell, widthBell - 6*event.getCount(), false);
    }
  }
  /* when the right key is pressed we set the bell on */
  void setOn(char key) {
    if (key == keyBell) {
      if(!isBellOn){
        isBellOn= true;
        R = 100;
        
        myMessage = new OscMessage("/myBellState");
        myMessage.add((xBell / width) * 10);
        myMessage.add( -(yBell - height) / height);  // amplitude goes from 0 on the bottom of the window to 1 at the top of the window6
        myMessage.add(2328 - (widthBell * 6.98));    // We rescale the width to correspond to a frequency varying from C4 262Hz, to C7 2093Hz
        println("Sending OSC message", myMessage);
        oscP5.send(myMessage, myRemoteLocation);
      }
    }
  }
  
  void setOff(char key){
    if (key == keyBell) {
      if(isBellOn){
        isBellOn= false;
        R = 200;
      }
    }
  }
  
  void redraw(float x, float y, int newWidth, boolean on){
    xBell = x;
    yBell = y;
    /*if(on){
      // set on to send osc messages
      setOn(keyBell);
      // set off to reset the color
      setOff(keyBell);
    }*/
    widthBell = newWidth;
    // loading was used to avoid the picture to lose quality, but it undermines the quality of the "animation"
    imageBell = loadImage(name);
    imageBell.resize(widthBell, 0);
  }
}

class Button {
  float x;
  float y;
  String name;
  int dim;
  int R = 200;
  boolean isMouseOver;
  
  Button(float xButton, float yButton, int dimension, String nameButton){
    x = xButton;
    y = yButton;
    dim = dimension;
    name = nameButton;
  }
  
  // -- display method
  void display(){
    // modifies the colour of the image
    fill(R);
    // rect containing the name of the preset
    rect(x, y, dim, dim/2, dim/8);
    fill(0);
    text(name, x+(dim/2), y+(dim/4));
  }
  
  void mouseMoved(){
    if (mouseX > x && mouseX < (x+dim) &&
      mouseY > y && mouseY < (y+(dim/2))){
      isMouseOver=true;
      R = 230;
    }
    else {
      isMouseOver=false;
      R = 200;
    }
  }
  
  void mousePressed(){
    switch(name){
      case "Preset 1": println("Major Scale");
        preset = 1;
        bells[0].redraw(100,360,233, true);  // F5 <-
        bells[1].redraw(250,360,221, true);  // G5 <-
        bells[2].redraw(400,360,208, true);  // A5 <-
        bells[3].redraw(550,360,191, true);  // B5 <-
        bells[4].redraw(680,360,184, true);  // C6
        bells[5].redraw(800,360,165, true);  // D6
        bells[6].redraw(910,360,145, true);  // E6
        bells[7].redraw(1010,360,133, true); // F6
        bells[8].redraw(1090,360,109, true); // G6 
        bells[9].redraw(1160,360,81, true);  // A6
        bells[10].redraw(1210,360,50, true); // B6
        bells[11].redraw(1250,360,35, true); // C7 
        break;
        

      case "Preset 2":println("Chromatic scale");
        preset = 2;
        bells[0].redraw(100,360,184, true);  // C6
        bells[1].redraw(250,360,175, true);  // C6#
        bells[2].redraw(400,360,165, true);  // D6
        bells[3].redraw(550,360,155, true);  // D6#
        bells[4].redraw(680,360,145, true);  // E6
        bells[5].redraw(800,360,133, true);  // F6
        bells[6].redraw(910,360,121, true);  // F6#
        bells[7].redraw(1010,360,109, true); // G6
        bells[8].redraw(1090,360,96, true);  // G6#
        bells[9].redraw(1160,360,81, true);  // A6
        bells[10].redraw(1210,360,66, true); // A6#
        bells[11].redraw(1250,360,50, true); // B6
        break;
        
        
      case "Preset 3": println("preset 3"); println("Frere Jacques"); // to play: Q W E Q - Q W E Q - E R V - E R V - D F D S A Q - C Z X - C Z X 
        preset = 3;
        bells[0].redraw(680,340,184, true);  // C6  q medium
        bells[1].redraw(675,350,165, true);  // D6  w medium
        bells[2].redraw(550,360,145, true);  // E6  e medium
        bells[3].redraw(900,360,133, true);  // F6  r long
        bells[4].redraw(550,360,145, true);  // E6  a medium
        bells[5].redraw(400,360,133, true);  // F6  s short
        bells[6].redraw(400,360,109, true);  // G6  d short
        bells[7].redraw(400,360,81, true);   // A6  f short
        bells[8].redraw(600,360,221, true);  // G5  z medium        
        bells[9].redraw(800,360,184, true);  // C6  x long
        bells[10].redraw(650,360,165, true); // D6  c medium 
        bells[11].redraw(700,360,109, true); // G6   v long 
        break;
      
      case "Preset 4": 
        println("Twinkle twinkle"); // to play: QQWWEER - AASSDDF - WWAASSZ - WWAASSZ - QQWWEER - AASSDDF
        preset = 4;
        bells[0].redraw(400,240,184, true);  // C6  q medium
        bells[1].redraw(500,260,109, true);  // G6  w medium
        bells[2].redraw(450,250,81, true);   // A6  e medium
        bells[3].redraw(900,320,109, true);  // G6  r long
        bells[4].redraw(420,340,133, true);  // F6  a medium
        bells[5].redraw(560,360,145, true);  // E6  s medium
        bells[6].redraw(600,350,165, true);  // D6  d medium
        bells[7].redraw(900,200,184, true);  // C6  f long
        bells[8].redraw(1000,100,165, true); // D6  z long
        bells[9].redraw(750,700,40, true);   // unused
        bells[10].redraw(150,600,165, true); // unused
        bells[11].redraw(1100,700,80, true); // unused
        break;
      
      case "Reset": 
        println("Reset");
        // Select a default background
        index = 0;
        setup();
        break;
      
      default: break;
    }
  }
}

void oscEvent(OscMessage scMessage) {
  if (scMessage.addrPattern().equals("/activeBell")) {
    println("active bell is: ", scMessage.get(1).intValue());
    // the the right bell on
    int bellNumber = scMessage.get(1).intValue();
    bells[bellNumber].setOn(bells[bellNumber].keyBell);
  }
  if (scMessage.addrPattern().equals("/turnOffBell")) {
    int bellNumber = scMessage.get(1).intValue();
    bells[bellNumber].setOff(bells[bellNumber].keyBell);
  }
}
