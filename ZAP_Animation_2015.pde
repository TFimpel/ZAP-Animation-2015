


/* import necessary code libraries */
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.data.*;

import java.util.List;
import java.util.Collections;

import org.joda.time.DateTime; //import joda libraries to deal with time
import org.joda.time.Hours;
import org.joda.time.Minutes;

import ddf.minim.* ;
import ddf.minim.signals.* ;
import ddf.minim.effects.* ;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput au_out ;
SquareWave sqw ;
LowPassSP lpass ;


/* global variables */

//green and pink
color c_wd = color(51,160,44);
color c_we = color(255,20,147);
color c_wd_map = color(50,190,50); //lighter because it looks differnet on map than on black background


String title;
String subtitle;
String charttitle;


UnfoldingMap map; 
Location tc;
List<Marker> zapScans; //create global list object for our gps points
List<Marker> zapScanSums; //create global list object for our daily summaries
List<Marker> zapScanAvgs; //create global list object for our daily avgs


Float maxZapScanCount; //create variables for countRange
Float minZapScanCount;
Float avgZapScanCount;

DateTime startTime; //new date variables
DateTime endTime;
DateTime currentTime;

float[] numbers ;

//Float originX = 530.0;
Float originX = 730.0;
Float originY = 860.0;

Float surf_opacity_counter = 0.0;

PImage img;
PImage img_green;
PImage img_pink;
PImage img_surface;

SimplePointMarker umnmpls = new SimplePointMarker(new Location(44.968288, -93.240317));
SimplePointMarker umnstpl = new SimplePointMarker(new Location(44.978840, -93.188260));
SimplePointMarker downtownmpls = new SimplePointMarker(new Location(44.977343, -93.267721));
SimplePointMarker mctc = new SimplePointMarker(new Location( 44.954411, -93.268461));
SimplePointMarker como = new SimplePointMarker(new Location(44.989302, -93.213246));
SimplePointMarker midtown = new SimplePointMarker(new Location(44.948575, -93.264897));
SimplePointMarker uptown = new SimplePointMarker(new Location(44.957005, -93.294430));
SimplePointMarker loringpark = new SimplePointMarker(new Location(44.970110, -93.283175));
SimplePointMarker nicolletpark = new SimplePointMarker(new Location(44.988587, -93.267568));
SimplePointMarker dinkytown = new SimplePointMarker(new Location(44.982389, -93.239279));
SimplePointMarker seward = new SimplePointMarker(new Location(44.961252, -93.237767));

color labelcolor = color(0);
color labelstrokecolor = color(0);

/* processing setup function */
void setup() {

        size(1500, 900, P2D); 

    title = "ZAP Bicycle Counts 2015, Twin Cities, MN";
    subtitle = "ZAP - An automated bike commuting recognition system logs trips by enrolled cyclists at over 50 reader locations.";
    charttitle = "Total ZAP counts per day, all locations combined.";

img = loadImage("clef_img.jpg");
img_green = loadImage("green.png");
img_pink = loadImage("pink.png");
img_surface = loadImage("surface.png");

umnmpls.setColor(labelcolor);
umnmpls.setStrokeColor(labelstrokecolor);
umnmpls.setStrokeWeight(2);

umnstpl.setColor(labelcolor);
umnstpl.setStrokeColor(labelstrokecolor);
umnstpl.setStrokeWeight(0);

downtownmpls.setColor(labelcolor);
downtownmpls.setStrokeColor(labelstrokecolor);
downtownmpls.setStrokeWeight(0);

mctc.setColor(labelcolor);
mctc.setStrokeColor(labelstrokecolor);
mctc.setStrokeWeight(0);

como.setColor(labelcolor);
como.setStrokeColor(labelstrokecolor);
como.setStrokeWeight(0);

    
     minim = new Minim(this) ;
     au_out = minim.getLineOut() ;
     sqw = new SquareWave(261.63, 1, 44100);
     lpass = new LowPassSP(200, 44100);
     au_out.addSignal(sqw);
     au_out.addEffect(lpass);
     sqw.setFreq(0);

    
    map = new UnfoldingMap(this, new EsriProvider.WorldGrayCanvas());
     
     
    MapUtils.createDefaultEventDispatcher(this, map);    
    tc = new Location(44.970805, -93.234856); //center on UMN Mpls. campus
    map.zoomAndPanTo(tc,14);
    
    /* Create a List of bar objects using the geojson reader included in unfolding */    
List<Feature> features2 = GeoJSONReader.loadData(this, "XYdailytotals2015.geo.json");
    zapScanSums = MapUtils.createSimpleMarkers(features2); //create markers from each feature and populate our albatross134 list with it

    /* Create a List of bar objects using the geojson reader included in unfolding */    
List<Feature> features3 = GeoJSONReader.loadData(this, "XYyearlyTotalsAndAvgs.geo.json");
    zapScanAvgs = MapUtils.createSimpleMarkers(features3); //create markers from each feature and populate our zapScanAvg list with it
    
    
    /* Create a List of feature objects using the geojson reader included in unfolding */
    List<Feature> features = GeoJSONReader.loadData(this, "XYstationtotals2015.geo.json");
    /* create a set of simple markers from our list of features */
    zapScans = MapUtils.createSimpleMarkers(features); //create markers from each feature and populate our albatross134 list with it
    List<Float> countCollection = new ArrayList<Float>(); //create an empty lists to store all the zapScanCount values
    List<DateTime> dateCollection = new ArrayList<DateTime>(); //create an empty list to store date values
    /* loop over each marker */
    for (Marker i: zapScans){
      Float count = Float.parseFloat(i.getStringProperty("count_as_string")); // get the scans_int property value
      DateTimeFormatter f = DateTimeFormat.forPattern("MM-dd-yyyy");
      DateTime time = new DateTime(f.parseDateTime((i.getStringProperty("date_as_string")))); //get the timestamp attribute for this marker
      countCollection.add(count); //add the moveSpeed value to the list moveSpeedCollection
      dateCollection.add(time); // add the time value to the list dateCollection
    }
    
    /* now that the windSpeedCollection and moveSpeedCollection lists are
    populated get the summary statistics and print them in the console */
    maxZapScanCount = Collections.max(countCollection);
    minZapScanCount = Collections.min(countCollection);
    startTime = Collections.min(dateCollection);
    //endTime = Collections.max(dateCollection);
    
    DateTimeFormatter f3 = DateTimeFormat.forPattern("MM-dd-yyyy");
    DateTime markerTime3 = new DateTime(f3.parseDateTime("1-31-2016"));
       
//    println("zapScan Count per Day Range: " + minZapScanCount + " to " + maxZapScanCount);
   // println("Date range: " + startTime + " to " + endTime);
    currentTime = startTime;//set the current time to the startTime
frameRate(4) ; // frames to be displayed every second. default is 60
//   frameRate(16) ; // for testing speed it up


//https://www.seventhstring.com/resources/notefrequencies.html
// and https://en.wikipedia.org/wiki/D_major D major (or the key of D) is a major scale based on D, consisting of the pitches D, E, F♯, G, A, B, and C♯
numbers = new float[73] ;
//numbers[0] = 1R30.8 ;  //C
numbers[0] = 138.6  ; //C#
numbers[1] = 138.6  ; //C#
numbers[2] = 146.8  ; //D
//numbers[3] = 155.6  ; //Eb
numbers[3] = 164.8  ;//E
numbers[4] = 164.8  ;//E
//numbers[5] = 174.6  ; //F
numbers[5] = 185.0  ; //F#
numbers[6] = 185.0  ; //F#
numbers[7] = 196.0  ; //G
numbers[8] = 196.0  ; //G
//numbers[8] = 207.7  ; //G#
numbers[9] = 220.0  ; //A
//numbers[10] = 233.1  ; //Bb
numbers[10] = 246.9; //B
numbers[11] = 246.9; //B

//numbers[12] = 261.6 ;  //C
numbers[12] = 277.2  ; //C#
numbers[13] = 277.2  ; //C#
numbers[14] = 293.7  ; //D
//numbers[15] = 311.1  ; //Eb
numbers[15] = 329.6  ;//E
numbers[16] = 329.6  ;//E
//numbers[17] = 349.2  ; //F
numbers[17] = 370.0  ; //F#
numbers[18] = 370.0  ; //F#
numbers[19] = 392.0  ; //G
numbers[20] = 392.0  ; //G
//numbers[20] = 415.3  ; //G#
numbers[21] = 440.0  ; //A
//numbers[22] = 466.2  ; //Bb
numbers[22] = 493.9; //B
numbers[23] = 493.9; //B

//numbers[24] = 523.3 ;  //C
numbers[24] = 554.4  ; //C#
numbers[25] = 554.4  ; //C#
numbers[26] = 587.3  ; //D
//numbers[27] = 622.3  ; //Eb
numbers[27] = 659.3  ;//E
numbers[28] = 659.3  ;//E
//numbers[29] = 698.5  ; //F
numbers[29] = 740.0  ; //F#
numbers[30] = 740.0  ; //F#
numbers[31] = 784.0  ; //G
numbers[32] = 784.0  ; //G
//numbers[32] = 830.6  ; //G#
numbers[33] = 880.0  ; //A
//numbers[34] = 932.3 ; //Bb
numbers[34] = 987.8; //B
numbers[35] = 987.8; //B

//numbers[36] =1047;  //C
numbers[36] =1109; //C#


//numbers[37] = 65.41  ; //C
numbers[37] = 69.30  ; //C#
numbers[38] = 69.30  ; //C#
numbers[39] = 73.42  ; //D
//numbers[40] = 77.78  ; //Eb
numbers[40] = 82.41  ;//E
numbers[41] = 82.41  ;//E
//numbers[42] = 87.31  ; //F
numbers[42] = 92.50  ; //F#
numbers[43] = 92.50  ; //F#
numbers[44] = 98.00  ; //G
numbers[45] = 98.00  ; //G
//numbers[45] = 103.8  ; //G#
numbers[46] = 110.0  ; //A
//numbers[47] = 116.5  ; //Bb
numbers[47] = 123.5; //B
numbers[48] = 123.5; //B

//numbers[49] = 32.70  ; //C
numbers[49] = 34.65; //C#
numbers[50] = 34.65; //C#
numbers[51] = 36.71 ;  //D
//numbers[52] = 38.89  ; //Eb
numbers[52] = 41.20  ;//E
numbers[53] = 41.20  ;//E
//numbers[54] = 43.65  ; //F
numbers[54] = 46.25  ; //F#
numbers[55] = 46.25  ; //F#
numbers[56] = 49.00  ; //G
numbers[57] = 49.00  ; //G
//numbers[57] = 51.91  ; //G#
numbers[58] = 55.00  ; //A
//numbers[59] = 58.27  ; //Bb
numbers[59] = 61.74; //B
numbers[60] = 61.74; //B

//numbers[61] = 16.35 ; //C
numbers[61] = 17.32  ; //C#
numbers[62] = 17.32  ; //C#
numbers[63] = 18.35  ; //D
//numbers[64] = 19.45  ; //Eb
numbers[64] = 20.60  ; //E
numbers[65] = 20.60  ; //E
//numbers[66] = 21.83 ; //F
numbers[66] = 23.12 ; //F#
numbers[67] = 23.12 ; //F#
numbers[68] = 24.50  ;  //G
numbers[69] = 24.50  ;  //G
//numbers[69] = 25.96 ; //G#
numbers[70] = 27.50 ; //A
//numbers[71] = 29.14 ; //Bb
numbers[71] = 30.87; //B
numbers[72] = 30.87; //B

}

/* processing draw function */
void draw() {  
    map.draw(); 
    textSize(14);
    textLeading(18);
    fill(0,0,0);
    //text("Minneapolis\nCommunity\n& Technical\n  College", mctc.getScreenPosition(map).x, mctc.getScreenPosition(map).y);
    text(" Downtown\nMinneapolis", downtownmpls.getScreenPosition(map).x, downtownmpls.getScreenPosition(map).y);
    text("University of Minnesota\n     St. Paul Campus", umnstpl.getScreenPosition(map).x, umnstpl.getScreenPosition(map).y);
    text("University of Minnesota\n  Minneapolis Campus", umnmpls.getScreenPosition(map).x, umnmpls.getScreenPosition(map).y);
    text("Como", como.getScreenPosition(map).x, como.getScreenPosition(map).y);
    text("Midtown", midtown.getScreenPosition(map).x, midtown.getScreenPosition(map).y);
    text("Uptown", uptown.getScreenPosition(map).x, uptown.getScreenPosition(map).y);
    text("Loring Park", loringpark.getScreenPosition(map).x, loringpark.getScreenPosition(map).y);
    text("Nicollet Island", nicolletpark.getScreenPosition(map).x, nicolletpark.getScreenPosition(map).y);
    text("Dinkytown", dinkytown.getScreenPosition(map).x, dinkytown.getScreenPosition(map).y);
    text("Seward", seward.getScreenPosition(map).x, seward.getScreenPosition(map).y);


    /* when end of trajectory is reached start over  */
  
           DateTimeFormatter after2015 = DateTimeFormat.forPattern("MM-dd-yyyy");
       DateTime after2015Time = new DateTime(after2015.parseDateTime("01-01-2016"));
       DateTime after2015TimePlus = new DateTime(after2015.parseDateTime("02-01-2016"));
    if (currentTime.isAfter(after2015Time)){
      if(currentTime.isAfter(after2015TimePlus)){
      surf_opacity_counter = surf_opacity_counter + 0.8;
                          //test display surface 
tint(255, surf_opacity_counter);  // Display at half opacity
  image(img_surface, 130, 165, 1237, 620);
  noTint();
      }
                        strokeWeight(2);
                  stroke(0);
                  fill(255);
                  rect(1175,570, 1485,640);
                  textAlign(RIGHT);
                  fill(0);
                  textSize(24);
                  text("Average daily ZAP counts", 1480, 600);
                  text("|", 1335, 630);
                  fill(c_wd_map);
                   text("Weekday", 1320, 630);
                  fill(c_we);
                  text("Weekend", 1450, 630);
                  textAlign(LEFT);
                  sqw.setFreq(0);
    }                 
                     

    
    textSize(11);
    fill(0);
    text("Data: University of Minnesota Parking and Transportation Services, Esri, DeLorme, NAVTEQ   Created by: Tobias Fimpel", 850, 895);

    
    println();
    println(currentTime);
    /* loop over each marker again and draw our own graphics */     
    for (Marker i: zapScans){  
      /* get the dayly count property values */
       Float zapScanCount = Float.parseFloat(i.getStringProperty("count_as_string"));  //get the count
       DateTimeFormatter f = DateTimeFormat.forPattern("MM-dd-yyyy");
       DateTime markerTime = new DateTime(f.parseDateTime(i.getStringProperty("date_as_string")));
       String dayType = i.getStringProperty("wd_or_we");
       /* check point's timeStamp and only if it's smaller than currentTime draw it*/
       //if(markerTime.isBefore(currentTime)){
       if ((markerTime.isBefore(currentTime.plusDays(1))) && (markerTime.isAfter(currentTime.minusDays(1)))){
         ScreenPosition coords = map.getScreenPosition(i.getLocation()); //Translates a marker's lat/long values to our local screen coordinates
         Float pointStroke = map(zapScanCount, minZapScanCount, maxZapScanCount, 0, 100); //the map function in Processing normalizes a given values.
                    stroke(0);
           strokeWeight(1);
         if (dayType.equals("wd") == true){
           fill(c_wd_map);
         } 
         if (dayType.equals("we") == true){
           fill(c_we);
         } 
                    ellipse(coords.x,coords.y,pointStroke,pointStroke);//draw an ellipse and set the size based on the point's pointStroke value 

       } //end if statement
    } //end the loop
     
    /* year avgs */
    for (Marker i: zapScanAvgs){  
      /* get the dayly count property values */
       Float zapScanCount = Float.parseFloat(i.getStringProperty("avg_zaps_per_day_string"));  //get the count
       Float zapScanCount_we = Float.parseFloat(i.getStringProperty("avg_zaps_per_we_day"));  //get the count
       Float zapScanCount_wd = Float.parseFloat(i.getStringProperty("avg_zaps_per_wd_day"));  //get the count
       Float labeloffsetY = Float.parseFloat(i.getStringProperty("extralabeloffsetY"));  //get the count
       Float labeloffsetX = Float.parseFloat(i.getStringProperty("extralabeloffsetX"));  //get the count
       DateTimeFormatter f1 = DateTimeFormat.forPattern("MM-dd-yyyy");
       DateTime markerTime1 = new DateTime(f1.parseDateTime(i.getStringProperty("date_as_string1")));
       DateTimeFormatter f2 = DateTimeFormat.forPattern("MM-dd-yyyy");
       DateTime markerTime2 = new DateTime(f2.parseDateTime(i.getStringProperty("date_as_string2")));
       /* check point's timeStamp and only if it's smaller than currentTime draw it*/
       if (currentTime.isAfter(markerTime1.plusDays(1))){

         ScreenPosition coords = map.getScreenPosition(i.getLocation()); //Translates a marker's lat/long values to our local screen coordinates
         Float pointStroke1 = map(zapScanCount_wd, minZapScanCount, maxZapScanCount, 0, 100); //the map function in Processing normalizes a given values.
         stroke(c_wd_map);
         strokeWeight(2);
         fill(0,0,0,1);
         ellipse(coords.x,coords.y,pointStroke1,pointStroke1);//draw an ellipse and set the size based on the point's pointStroke value 

         Float pointStroke2 = map(zapScanCount_we, minZapScanCount, maxZapScanCount, 0, 100); //the map function in Processing normalizes a given values.
         stroke(c_we);
         strokeWeight(2);
         ellipse(coords.x,coords.y,pointStroke2,pointStroke2);//draw an ellipse and set the size based on the point's pointStroke value 
         
         /* labels. we label placement is dependent on number of digits in zapScanCount_wd */
         textSize(16);
         fill(c_wd_map);
         String label_wd = i.getStringProperty("avg_zaps_per_wd_day"); 
         Float label_wd_x = coords.x + pointStroke1/2 + labeloffsetX;
         Float label_wd_y = coords.y + pointStroke1/2 + labeloffsetY;
         text(label_wd, label_wd_x, label_wd_y );
         if (zapScanCount_wd > 99){
           textSize(16);
           fill(150);
           String divider = "|"; 
           Float div_x = coords.x + pointStroke1/2 + 29 + labeloffsetX;
           Float div_y = coords.y + pointStroke1/2 + labeloffsetY;
           text(divider, div_x, div_y );
           
           textSize(16);
           fill(c_we);
           String label_we = i.getStringProperty("avg_zaps_per_we_day"); 
           Float label_we_x = coords.x + pointStroke1/2 + 35 + labeloffsetX;
           Float label_we_y = coords.y + pointStroke1/2 + labeloffsetY;
           text(label_we, label_we_x, label_we_y );
         }
         if ((zapScanCount_wd < 99) && (zapScanCount_wd > 10)){
           textSize(16);
           fill(150);
           String divider = "|"; 
           Float div_x = coords.x + pointStroke1/2 + 19 + labeloffsetX;
           Float div_y = coords.y + pointStroke1/2 + labeloffsetY;
           text(divider, div_x, div_y );
           
           textSize(16);
           fill(c_we);
           String label_we = i.getStringProperty("avg_zaps_per_we_day"); 
           Float label_we_x = coords.x + pointStroke1/2 + 25 + labeloffsetX;
           Float label_we_y = coords.y + pointStroke1/2 + labeloffsetY;
           text(label_we, label_we_x, label_we_y );
         }
         if (zapScanCount_wd < 10){
           textSize(16);
           fill(150);
           String divider = "|"; 
           Float div_x = coords.x + pointStroke1/2 + 9 + labeloffsetX;
           Float div_y = coords.y + pointStroke1/2 + labeloffsetY;
           text(divider, div_x, div_y );
           
           textSize(16);
           fill(c_we);
           String label_we = i.getStringProperty("avg_zaps_per_we_day"); 
           Float label_we_x = coords.x + pointStroke1/2 + 15 + labeloffsetX;
           Float label_we_y = coords.y + pointStroke1/2 + labeloffsetY;
           text(label_we, label_we_x, label_we_y );
         }
       } //end if statement
    } //end the loop
      
      //size(1300, 900, P2D); 
         //background
         rectMode(CORNERS);
         stroke(255);//color
         fill(0);  // Set fill to gray
         rect(500, 645, 1490, 885, 7);  // height of box is 215
        

         //ellipse symbols map key
         ellipse(originX - 160,originY-38, 97,97); //97px is for 400 if we are mapping max value of 414 to 100px
         ellipse(originX - 160,originY-23, 68,68); //68px is for 200 if we are mapping max value of 414 to 100px
         ellipse(originX - 160,originY-14, 48,48); //48px is for 100 if we are mapping max value of 414 to 100px
         ellipse(originX - 160,originY-6, 34,34); //48px is for 50 if we are mapping max value of 414 to 100px


         //x-y axis
         stroke(255, 255, 255);//color...this should depend on weekend vs weekday
         strokeWeight(2);//width in pixel ... this needs to be somehow dependent on with of screen
         line(originX, originY, originX + 730 + 2, originY);//x-axis
         line(originX, originY, originX, originY - 110);//y-axis
         image(img, originX - 85, originY - 100); //FYI image width is 46px, heigh is 100px
         /* horizontal dashed lines */
         strokeWeight(1);
         stroke(255,255,255);
        float x1 = 635;
        float y25 = originY+2 - 25;
        float y50 = originY+2 - 50;
        float y75 = originY+2 - 75;
        float y100 = originY+2 - 100;
         for (int i = 0; i <= 102; i++) {
            x1 = x1 + 8;
            point(x1, y25);
            point(x1, y50);
            point(x1, y75);
            point(x1, y100);
          }
         
         /* dividing lines between months */
          stroke(255,255,255);
         strokeWeight(1);//width in pixel ... this needs to be somehow dependent on with of screen
         line(originX+31*2, originY, originX+31*2, originY +6);//jan|feb
         line(originX+31*2+28*2, originY, originX+31*2+28*2, originY +6);//feb|mar
         line(originX+31*2+28*2+31*2, originY, originX+31*2+28*2+31*2, originY +6);//mar|apr
         line(originX+31*2+28*2+31*2+30*2, originY, originX+31*2+28*2+31*2+30*2, originY +6);//apr|may
         line(originX+31*2+28*2+31*2+30*2+31*2, originY, originX+31*2+28*2+31*2+30*2+31*2, originY +6);//may|jun
         line(originX+31*2+28*2+31*2+30*2+31*2+30*2, originY, originX+31*2+28*2+31*2+30*2+31*2+30*2, originY +6);//jun|jul
         line(originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2, originY, originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2, originY +6);//jul|aug
         line(originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2, originY, originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2, originY +6);//aug|sep
         line(originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2+30*2, originY, originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2+30*2, originY +6);///sep|oct
         line(originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2+30*2+31*2, originY, originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2+30*2+31*2, originY +6);//oct|nov
         line(originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2+30*2+31*2+30*2, originY, originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2+30*2+31*2+30*2, originY +6);//nov|dec
         /* tick marks on y axis */
         strokeWeight(1);//width in pixel ... this needs to be somehow dependent on with of screen
         line(originX - 6, originY+2 - 25,originX,originY+2 - 25);
         line(originX - 6, originY+2 - 50,originX,originY+2 - 50);
         line(originX - 6, originY+2 - 75,originX,originY+2 - 75);
         line(originX - 6, originY+2 - 100,originX,originY+2 - 100);

         /* infobox text elements */
         fill(255);
         textSize(24);
         text(title, 720, 675);
         textSize(15);
         text(subtitle, 566, 700);
         textSize(13);
         text(charttitle, 925, 735);
         text("0", originX-14, originY - 2);
         text("500", originX-29, originY - 25);
         text("1000", originX-38, originY - 50);
         text("1500", originX-38, originY - 75);
         text("2000", originX-38, originY - 100);
         text("Jan",originX+20, originY + 14);
         text("Feb",originX+31*2+20, originY + 14);
         text("Mar",originX+31*2+28*2+20, originY + 14);
         text("Apr", originX+31*2+28*2+31*2+20, originY + 14);
         text("May",originX+31*2+28*2+31*2+30*2+20, originY + 14);
         text("Jun",originX+31*2+28*2+31*2+30*2+31*2+20, originY + 14);
         text("Jul", originX+31*2+28*2+31*2+30*2+31*2+30*2+20, originY + 14);
         text("Aug",originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+20, originY + 14);
         text("Sep",originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2+20, originY + 14);
         text("Oct",originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2+30*2+20, originY + 14);
         text("Nov",originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2+30*2+31*2+20, originY + 14);
         text("Dec",originX+31*2+28*2+31*2+30*2+31*2+30*2+31*2+31*2+30*2+31*2+30*2+20, originY + 14);
         text("Weekday",560,735);
         text("Weekend",560,755);
         text("400",originX - 172,originY-74);
         textSize(12);
         text("200",559,originY-43);
         textSize(11);
         text("100",560,originY-27);
         textSize(10);
         text("50",564,originY-11);

        /* l=scribble line to show what hue means */
        image(img_green, 530, 725); 
        image(img_pink, 530, 745); 


         for (Marker i: zapScanSums){
                 /* get the dayly summary count property values */
               Float zapScanSum = Float.parseFloat(i.getStringProperty("Sum_count_as_string"));  //get the count
               Float dayCount = Float.parseFloat(i.getStringProperty("day_of_year"));  //get the day-number
               String dayType = i.getStringProperty("wd_or_we");
               String t = i.getStringProperty("date_as_string");

               DateTimeFormatter f = DateTimeFormat.forPattern("MM-dd-yyyy");
               DateTime barTime = new DateTime(f.parseDateTime(t));
               
               /* check point's timeStamp and only if it's smaller than currentTime draw it*/
               if(barTime.isBefore(currentTime.plusDays(1))){
               //bars
               //if (dayType == "wd")
               if (dayType.equals("wd") == true){
               stroke(c_wd);//color...this should depend on weekend vs weekday
               }
               if (dayType.equals("we") == true){
               stroke(c_we);//color...this should depend on weekend vs weekday
               }
               strokeWeight(2);//width in pixel ... this needs to be somehow dependent on with of screen
               line(originX + 2 + dayCount * 2, originY - 2, originX + 2 + dayCount * 2, originY - 2 - zapScanSum * 0.05);// (x1, y1, x2, y2) keep track of horizontal location in global variable 
             }
               
               if ((barTime.isBefore(currentTime.plusDays(1))) && (barTime.isAfter(currentTime.minusDays(1)))){
                   sqw.setFreq(zapScanSum/3);
                   //sqw.setFreq(261.63);
                   //au_out.setGain(zapScanSum/30); //takes value in decibles
                   //find the closest nice note to the zapScanSum/3
                   float myNumber = zapScanSum/2;
                   int distance = int(Math.abs(numbers[0] - myNumber));
                   int idx = 0;
                   for(int c = 1; c < numbers.length; c++){
                      int cdistance = int(Math.abs(numbers[c] - myNumber));
                      if(cdistance < distance){
                      idx = c;
                      distance = cdistance;
                      }
                    }
                  int theNumber = int(numbers[idx]);
                  sqw.setFreq(theNumber);
                  
                  //the date display
                  strokeWeight(2);
                  stroke(0);
                  fill(255);
                  rect(1320,610, 1485,640);
                  textAlign(RIGHT);
                  fill(0);
                  textSize(24);
                  text(" " + t, 1480, 635);
                  textAlign(LEFT);
               }

         }
    currentTime = currentTime.plusDays(1);//advance the currentTime before draw function is called again
    

                  
    if (currentTime.isAfter(endTime)){
      surf_opacity_counter = 0.0;
      currentTime = startTime; //set currentTime to startTime
    }
    
    /* to export frames to images for input in Processing's Movie Maker tool */
    //saveFrame("frames/####.png");

}
