// BELLS //
/* CLICK AND DRAG: move the bell in the space. 
   x coordinate --> duration 
   y coordinate --> volume of the bell
   mouse wheel up --> increases bell dimension --> decreases frequency
   mouse wheel down --> decreases bell dimension --> increases frequency
   QWER |
   ASDF |--> these keys allow to play the bells
   ZXCV |
   (other possib: x coord = freq, y coord volume, dimension duration, transparency harmonics)
*/

/* wwwww Notes. At the moment: wwwwww
- bells are drawn in order in the array --> the first will be always BEHIND the last in order of index
- overlapping bells can be dragged together and sometimes it is difficult not to
- the increasing size is done with RELOADING the image in order to not lose quality, but it is slow
- bells can't be selected simoultaneously
*/

import oscP5.*;
import netP5.*;

// Declare an object used to comunicate with SuperCollider
OscP5 oscP5;
NetAddress myRemoteLocation;
OscMessage myMessage;

int num = 12; //number of bells in the application
int pres= 4;  //number of presets
int index; //index to select the background
PFont font;
Bell[] bells = new Bell[num];
Button[] presets = new Button[pres];
Button reset = new Button(1160, 660, 100, "Reset");


void setup(){
   size(1280,720);
   noStroke();
   
   font = createFont("Arial Bold", 18);
   textFont(font);
   textAlign(CENTER, CENTER);
   
   // Select a default background
   index = 0;
   
   //used to place the bells in a line, at the same distance one from the other.
   // **** for very high numbers does not look even though ****
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
   
}

void draw() {
  update();
  //displaying bells and their text
  for (Bell b : bells) {
    b.display();
  }
  
  for (Button p: presets){
    p.display();
  }
  
  reset.display();
  
  fill(0);
  if(index != 0)
    triangle(10, 360, 24, 346, 24, 374);
  if(index != 3)
    triangle(1270, 360, 1256, 346, 1256, 374); 
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
   
  if(mouseX > 10 && mouseX < 24 &&
     mouseY > 346 && mouseY < 374 && index>0){
    index -= 1;
    update();
  }
  
  if(mouseX > 1256 && mouseX < 1270 &&
     mouseY > 346 && mouseY < 374 && index<3){
    index += 1;
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
}

void update(){
  //println("Background "+str(index%4));
  switch(index % 4){
    case 0: background(255); break;
    case 1: background(50); break;
    case 2: background(100); break;
    case 3: background(150); break;
    default: background(255); break;
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
  int widthBell = 100;
  // tint of the bell. Decreasing R to 200 when selecting a bell.
  int R = 230;
  // transparency of the bell
  int transparency = 255;
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
    widthBell = imageBell.width;
    imageBell.resize(80,0);
  }
  
  // -- display method
  void display(){
    // modifies the transparency of the image
    tint(R,255,255,transparency);
    // image takes as input the coordinate of the upper left corner of the image.
    image(imageBell, xBell-(imageBell.width / 2.0), yBell-(imageBell.height / 2.0));
    fill(0);
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
    if(isMouseOver){
       widthBell = imageBell.width;
       // loading was used to avoid the picture to lose quality, but it undermines the quality of the "animation"
       imageBell = loadImage(name);
       widthBell = widthBell - 3*event.getCount(); // 3 is a random number to not have too slow increasing/decreasing
       imageBell.resize(widthBell, 0);
    }
  }
  /* when the right key is pressed we set the bell on */
  void setOn(char key) {
    if (key == keyBell) {
      if(isBellOn){
        isBellOn= false;
        R = 200;
      }
      else{
        isBellOn= true;
        R = 100;
        
        myMessage = new OscMessage("/bellState");
        myMessage.add(xBell);
        myMessage.add(yBell);
        myMessage.add(widthBell);
        println("Sending OSC message", myMessage);
        oscP5.send(myMessage, myRemoteLocation);
      }
    }
  }
  
  void redraw(float x, float y, int newWidth, boolean on){
    xBell = x;
    yBell = y;
    if(on)
      setOn(keyBell);
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
    // modifies the transparency of the image
    fill(R);
    // rect containing the name of the preset
    rect(x, y, dim, dim/2);
    fill(0);
    text(name, x+(dim/2), y+(dim/4));
  }
  
  void mouseMoved(){
    if (mouseX>(x) && mouseX<(x+dim) &&
      mouseY>(y) && mouseY<(y+(dim/2))){
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
      case "Preset 1":
        println("preset 1");
        bells[0].redraw(90,120,20, true);
        bells[1].redraw(200,300,40, true);
        bells[2].redraw(500,600,200, true);
        /*
        continue for all the bells we want to change
        */
        break;
      case "Preset 2": println("preset 2"); break;
      case "Preset 3": println("preset 3"); break;
      case "Preset 4": println("preset 4"); break;
      case "Reset": println("Reset"); setup(); break;
      default: break;
    }
  }
}
