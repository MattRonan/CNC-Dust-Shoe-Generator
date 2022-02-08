/* Program to generate an nc file for a dust shoe that fits a Genmitsu 3018.  
* 
*  Copyright (c) 2022 Matt Ronan
*
*  Permission is hereby granted, free of charge, to any person obtaining a copy
*  of this software and associated documentation files (the "Software"), to deal
*  in the Software without restriction, including without limitation the rights
*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*  copies of the Software, and to permit persons to whom the Software is
*  furnished to do so, subject to the following conditions:
*
*  The above copyright notice and this permission notice shall be included in all
*  copies or substantial portions of the Software.
*
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*  SOFTWARE.
*/

/* Notes
 - .nc file is included in this repository but it's recommended to run the Processing sketch to verify all the settings are good, then export your own.
 - Most important thing is that the big circle opening fits tightly around the motor, so I would do a test run to make sure that it's the right dimension.
 - Drill a 1/8" hole between the two front tabs and use a 4-40 rod with a nut on each end to squeeze the motor even tighter. 
 - Maple or some other kinda hard wood should be used.  4-40 nuts on threaded rod need to be TIGHT to make sure vibration can't shake the shoe off.
 - Bristles can be clipped off a paintbrush, and then any kind of epoxy can be used to stick them into the bristle holes.
 - Set stockThickness to wood thickness, I wouldnt use thinner than 6.5mm.
 - Set 'inc' to the distance you want between bristle holes. It will then be used as a guideline for 
   choosing how many bristle holes to put so that they start on the first bristle outline point and end exactly ontop of the second.
 - No bristles on the front for easier bit changing but that lets some dust out so add some there if you want.
*/

float stockThickness = 6.5; //thickness of the board
float toolR = 1.0; //2mm bit.  too big means you'll need alot of bristles per hole and it'll be annoying.  any bit from 1.5 - 2.5mm is probably good.
float inc = 3; //change bristle hole spacing

float[][] silhouettePoints = { //displays as the yellow outline (excluding center opening)
                                {10,-5}, {68,-5}, {78,-12}, {78,-42}, {65,-60}, 
                                {65,-70}, {44,-70}, {44,-40}, {34,-40}, {34,-70}, 
                                {13,-70},{13,-60}, {0,-42}, {0,-12},{10,-5}
                              };
                    
//bristles follow the silhouette of the shoe but certain points (the ones in the front) dont have bristles associated with them
//but its convenient to have this array mirror the silhouette points array.  So 999 and -999 let you say wether or not to use that point
float[][] bristleOutline = { //displays as the red squares.  The start/end points of the lines of bristles.
                             {12,-8.5,999}, {66,-8.5,999}, {74,-15,999}, {74,-41,999}, {62,-58,-999}, 
                             {65,-70,-999}, {44,-70,-999}, {44,-40,-999}, {34,-40,-999}, {34,-70,-999}, 
                             {14,-70,-999},{16,-58,999}, {4,-42,999}, {4,-15,999},{12,-8.5,999}
                           };
                           
float[][] bristleHoles = new float[100][2]; //where the actual bristle hole coordinates get stored after calculation
int totalB = 0; //number of bristle holes tracker

float[][] labelOffsets = { //length labels get put at edge center points, these just offset them a bit so its clearer to read
                             {0,-6}, {5,-2}, {5,0}, {4,8},{6,20},
                             {0,14}, {2,-10}, {0,-14}, {-45,-10}, {0,14},
                             {-45,20}, {-45,15}, {-45,0}, {-35,-15}, {0,-2},
                           };
                           
int outerTabLocations[] = { 1,0,1,0,0, //1 means a tab will get put halfway between that point and the following point in the array.  Tabs are 2mm tall
                          0,0,0,0,0,
                          0,0,1,0,0
                        };

float[] openingCenter = {39,-37};//xy of part that slips over the motor
float openingR = 21; //r of part that slips over the motor
float xOff = 50; //x/y offset in view window
float yOff = 50;
float stretch = 5; //scale shoe up or down ONLY FOR VISUALIZATION.  points are in mm, but a 100mm wide shoe would only take up 100 pixels which is too small to work with so we multiply em
float xCoord,yCoord;
int numBristleHoles;
float hyp;
float theta;
float a,b;

boolean refreshWindow = true;

void setup(){
  size(500, 500);
  ellipseMode(CENTER);
}

OutputFile F = new OutputFile(10000);

void draw(){
  
  if(refreshWindow){
    
    background(100);
    strokeWeight(2);
  
    //--------draw 4-40 rod just for reference
    fill(70);
    stroke(60);
    rectMode(CORNER);
    rect((7*stretch)+xOff,(63*stretch)+yOff,65*stretch,3.2*stretch);
  
    //-------------------------draw outline of shoe
    rectMode(CENTER);
   
    for(int i = 0; i < silhouettePoints.length-1; i++){
        stroke(255,255,0);
       //draw yellow line from this point to next point
       float x1,x2,y1,y2;
       x1=silhouettePoints[i][0]*stretch+xOff;
       y1= (silhouettePoints[i][1]*stretch*-1)+yOff;
       x2=silhouettePoints[i+1][0]*stretch+xOff;
       y2=(silhouettePoints[i+1][1]*stretch*-1)+yOff;
       line(x1,y1,x2,y2);
       
       //and then alot of work just to place the length label of the current line segment at the middle point of that line
       a = (silhouettePoints[i+1][0]-silhouettePoints[i][0]);
       b = (silhouettePoints[i+1][1]-silhouettePoints[i][1]);
       hyp = sqrt(pow(a,2) + pow(b,2));
       theta = atan(b/a);
       
       if(silhouettePoints[i+1][0] < silhouettePoints[i][0]){ 
          theta += PI;
       }
       
       textSize(14);
       fill(200,200,155);
       text(nf(hyp,0,2), ((silhouettePoints[i][0] + (cos(theta)*hyp/2)) * stretch) + xOff + labelOffsets[i][0] , ((silhouettePoints[i][1] + (sin(theta)*hyp/2)) * stretch*-1) + yOff + labelOffsets[i][1] );
       fill(0);
       text(i,x1,y1);
       
       //if this edge gets a tab just mark it with a blue circle
       if(outerTabLocations[i] == 1){
         fill(0,200,255);
         noStroke();
         ellipse(((silhouettePoints[i][0] + (cos(theta)*hyp/2)) * stretch) + xOff , ((silhouettePoints[i][1] + (sin(theta)*hyp/2)) * stretch*-1) + yOff, 6,6 );  
       }
    }
      
    noStroke();
    
    for(int i = 0; i < bristleOutline.length-1; i++){
    
      if(bristleOutline[i][2] == 999){ //if point is marked 999, do it
       
        float bah = 0; 
        float tempInc1,tempInc2;
        float modInc;
        
        //mark the start point and end point of this line of bristles
        fill(255,0,0); 
        rect((bristleOutline[i][0]*stretch)+xOff,(bristleOutline[i][1]*stretch*-1)+yOff,6,6);
        rect((bristleOutline[i+1][0]*stretch)+xOff,(bristleOutline[i+1][1]*stretch*-1)+yOff,6,6);
        
        a = (bristleOutline[i+1][0]-bristleOutline[i][0]);
        b = (bristleOutline[i+1][1]-bristleOutline[i][1]);
        hyp = sqrt(pow(a,2) + pow(b,2) );
        theta = atan(b/a);
        //flip direction if we're going from right to left on xaxis instead of left to right
        if(bristleOutline[i+1][0] < bristleOutline[i][0]){ 
          theta += PI;
        }
       
        fill(200,200,200);
        
        //this part looks kind of confusing but its not that bad.  We set an increment value up above setup.  Say it's 3.
        //we'd like to have all our bristle holes spaced out in increments of 3, but we also want each line of bristles to start 
        //and end directly on the points in the bristleOutline array (the red squares in the viz window).  those points can
        //be whatever we want and the distances between them are unlikely to be exactly divisible by the inc.. 
        //so like if with our inc of 3 we have a pair of bristleOutline points that are 10 apart (hyp = 10),
        //we have the option of 4 bristle holes spaced 3.3mm apart (0,3.3,6.6,9.9) or we can have 5 bristle holes spaced 
        //2mm apart (0,2,4,6,8,10).  3.3 is way closer to our desired inc of 3, so that's the option we go with.  
      
        bah = int(hyp/inc)+1; //how many inc value to REACH second bristle point, usually exceeding it unless we have an exact divisor
        
        tempInc1 = hyp/(bah-1); //less bristles and a bigger gap between each
        tempInc2 = hyp/bah; //more bristles with a smaller gap between each.
  
        //which approach gives an increment that's closest to the one we want? set modInc to be that value and set number of bristles accordingly
        if(tempInc1-inc < inc-tempInc2){ 
          modInc = tempInc1; 
          numBristleHoles = int(bah);
        }
        else{ 
          modInc = tempInc2; 
          numBristleHoles = int(bah+1); 
        }
         
        //now draw the bristle holes from here to the next point
        for(int p = 0; p < numBristleHoles; p++){
          
          xCoord = (cos(theta)*(modInc*p)) + bristleOutline[i][0];
          yCoord = (sin(theta)*(modInc*p)) + bristleOutline[i][1] ;
            
          ellipse((xCoord*stretch)+xOff,(yCoord*stretch* -1)+yOff,toolR*2*stretch,toolR*2*stretch);
             
          bristleHoles[totalB][0] = xCoord;
          bristleHoles[totalB][1] = yCoord;
        
          totalB++;
        }
      }//end of skip or include point -999 or 999 in third array slot
    }//end of one edge

    //-----------------------------------------------------------------------------draw circular opening
    stroke(255,255,0);
    noFill();
    ellipseMode(CENTER);
    ellipse((openingCenter[0]*stretch) + xOff, (openingCenter[1]*stretch*-1) + yOff, openingR*2*stretch, openingR*2*stretch);
   
    //---------------------------------------------------------------help text
    fill(40);
    textSize(14);
    text("Press ENTER to export .nc file  (click inside this window first)",10,15);
    
    refreshWindow = false;
  }

  if(keyPressed && key == ENTER){
     exportNC();
     exit();
  }

}


//-----------------------------------------------------------------------------------------------------------------------------------------------methods
void exportNC(){
  F.plus("G17 G21 G90 G94 G40");
   F.plus("M05");
   F.plus("F300 S1000");
   F.plus("M03");
   F.plus("G00 Z3");
   F.plus("G00 X0 Y0");

   F.plus("F100");
   
   //-------------------------------------------------------------make bristle holes
   for(int i = 0; i < totalB; i++){
     F.plus("G00 Z2");
     F.plus("G00 X"+ bristleHoles[i][0] + "Y" + bristleHoles[i][1]);
     F.plus("G01 Z-5"); 
   }
   
   //----------------------------------cut circular opening for mounting to machine
   F.plus("F200");  
   F.plus("G00 Z5");
   
   for(float z = -.5; z >= (stockThickness*-1)-.5; z-=.5){ //drill all the way in some
   
     if(abs((stockThickness*-1)-z) < 2){
       cutCircleWithTabs(openingCenter[0], openingCenter[1], z, openingR, toolR,10); //last few mm add tabs
     }
     else{
       cutCircleWithTabs(openingCenter[0], openingCenter[1], z, openingR, toolR,0);//otherwise just a circle
     }
   }
   
   F.plus("G00 Z5");
   
   //---------------------------------------------cutout shoe's silhouette 
   F.plus("300");
   F.plus("G00 X"+ silhouettePoints[0][0] + "Y" + silhouettePoints[0][1]); //make sure we're at the first point before cutting in
    
   for(float z = -.5; z >= (stockThickness*-1)-.5; z-=.5){ 
       for(int i = 0; i < silhouettePoints.length; i++){
         
         F.plus("G01 Z"+z);
         F.plus("G01 X"+ silhouettePoints[i][0] + "Y" + silhouettePoints[i][1]);
         
         if(abs((stockThickness*-1)-z) < 2 && outerTabLocations[i] == 1){//if theres a tab indicated here go over,up,over,down, and then over to the next point.  then manually increment i cause the next loop cycle would be redundant
           
           int next;                                                                                                                                  
           
           if(i == silhouettePoints.length){
              next = 0;
           }
           else{
             next = i+1; 
           }
           
           a = (silhouettePoints[next][0]-silhouettePoints[i][0]);
           b = (silhouettePoints[next][1]-silhouettePoints[i][1]);
           hyp = sqrt(pow(a,2) + pow(b,2));
           theta = atan(b/a);
           
           if(silhouettePoints[i+1][0] < silhouettePoints[i][0]){ 
              theta += PI;
           }
           
           //this is overkill if your lines are all all horizontal or vertical, but it works for any sloped line. ze() is because things sometimes read 5.682E-7 etc, which is just 0 but Gcode cant interpret that
           F.plus("G01 X"+ ze((silhouettePoints[i][0] + (((hyp/2)-3)*cos(theta)))) + "Y" + ze((silhouettePoints[i][1] + (((hyp/2)-3)*sin(theta)))));//over
           F.plus("G01 Z" + (z+2));//up
           F.plus("G01 X"+ ze((silhouettePoints[i][0] + (((hyp/2)+3)*cos(theta)))) + "Y" + ze((silhouettePoints[i][1] + (((hyp/2)+3)*sin(theta)))));//over
           F.plus("G01 Z"+z);//down
           F.plus("G01 X"+ silhouettePoints[next][0] + "Y" + silhouettePoints[next][1]);//next point
           
           i++;
         }  
       }
   }
   
   F.plus("G01 X"+ silhouettePoints[0][0] + "Y" + silhouettePoints[0][1]);//return to start to finish shape
        
   F.plus("G00 Z3");
   F.plus("M05");
   F.plus("M02");
        
   F.export("dustShoe.nc");
   
   println("exported dustshoe.nc to sketch folder"); 
}

void cutCircleWithTabs(float xCent, float yCent, float z, float r,float toolR,int tabAmount){
  //(tab amount is in degrees)
  r -= toolR;
   
    F.plus("G00 X"+((cos(radians(180-tabAmount))*r) + xCent) + " Y"+ ((sin(radians(180-tabAmount))*r) + yCent));
    F.plus("G01 Z"+z);
    
    F.plus("G02 " + "X"+((cos(radians(90+tabAmount))*r) + xCent) + " Y"+ ((sin(radians(90+tabAmount))*r) + yCent) + " R" + r);
    if(tabAmount == 0){F.plus("G01 Z"+z); } 
    else{F.plus("G01 Z"+(z+2));}
    F.plus("G02 " + "X"+((cos(radians(90-tabAmount))*r) + xCent) + " Y"+ ((sin(radians(90-tabAmount))*r) + yCent) + " R" + r);
    F.plus("G01 Z"+z);
    
    F.plus("G02 " + "X"+((cos(radians(0+tabAmount))*r) + xCent) + " Y"+ ((sin(radians(0+tabAmount))*r) + yCent) + " R" + r);
    if(tabAmount == 0){F.plus("G01 Z"+z);} 
    else{F.plus("G01 Z"+(z+2));}
    F.plus("G02 " + "X"+((cos(radians(360-tabAmount))*r) + xCent) + " Y"+ ((sin(radians(360-tabAmount))*r) + yCent) + " R" + r);
    F.plus("G01 Z"+z);
    
    F.plus("G02 " + "X"+((cos(radians(270+tabAmount))*r) + xCent) + " Y"+ ((sin(radians(270+tabAmount))*r) + yCent) + " R" + r);
    if(tabAmount == 0){F.plus("G01 Z"+z);} 
    else{F.plus("G01 Z"+(z+2));}
    F.plus("G02 " + "X"+((cos(radians(270-tabAmount))*r) + xCent) + " Y"+ ((sin(radians(270-tabAmount))*r) + yCent) + " R" + r);
    F.plus("G01 Z"+z);
    
    F.plus("G02 " + "X"+((cos(radians(180+tabAmount))*r) + xCent) + " Y"+ ((sin(radians(180+tabAmount))*r) + yCent) + " R" + r);
    if(tabAmount == 0){F.plus("G01 Z"+z);} 
    else{F.plus("G01 Z"+(z+2));}
   
}

float ze(float in){

  if(in >= 0 && in < .01){
    return 0; 
  }
  else if(in < 0 && in > -.01) {
    return 0;
  }
  else{
    return in; 
  }
}

class OutputFile{
  
  String[] data;
  int index;
  
  public OutputFile(int s){
    data = new String[s]; 
    index = 0;
  }
  public void plus(String s){
    data[index] = s;
    index++;
  }
  public void export(String name){
    String[] output = new String[index];
    
    //otherwise the unfilled spaces in the original data array will print 'null' to the txt file.
    for(int i = 0; i < index; i++){
      output[i] = data[i];
    }
    
    saveStrings(name, output);
  }
  public void reset(){
    index = 0; 
  }
}
