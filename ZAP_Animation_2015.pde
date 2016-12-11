/* IMPORT NECESSARY CODE LIBRARIES */
/* import unfolding to deal with mapping */
import de.fhpotsdam.unfolding.*; 
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.data.*;

 
/* import java.util to deal with data loaded from files */
import java.util.List; 
import java.util.Collections;


/* import joda libraries to deal with time */
import org.joda.time.DateTime;
import org.joda.time.Hours;
import org.joda.time.Minutes;


/* import minim libraries to deal with sound*/
import ddf.minim.*; 
import ddf.minim.signals.*;
import ddf.minim.effects.*;
import ddf.minim.ugens.*;



/* DECLARE GLOBAL VARIABLES */
/* audio related variables */
Minim minim;
AudioOutput au_out;
SquareWave sqw;
LowPassSP lpass;
float[] frequencies;


/* color related variables */
color c_wd = color(51, 160, 44); //green
color c_we = color(255, 20, 147); //pink
color c_wd_map = color(50, 190, 50); //lighter because it looks differnet on map than on black 
color labelcolor = color(0);
color labelstrokecolor = color(0);


/* text element and image related variales */
String title;
String subtitle;
String charttitle;
PImage img;
PImage img_green;
PImage img_pink;
PImage img_surface;


/* mapping related variables */
UnfoldingMap map;
Location tc;
List < Marker > zapScans; //create global list object for our gps points
List < Marker > zapScanAvgs; //create global list object for our daily avgs
Float maxZapScanCount;
Float minZapScanCount;
Float avgZapScanCount;
Float surf_opacity_counter = 0.0;
SimplePointMarker umnmpls = new SimplePointMarker(new Location(44.968288, -93.240317));
SimplePointMarker umnstpl = new SimplePointMarker(new Location(44.978840, -93.188260));
SimplePointMarker downtownmpls = new SimplePointMarker(new Location(44.977343, -93.267721));
SimplePointMarker como = new SimplePointMarker(new Location(44.989302, -93.213246));
SimplePointMarker midtown = new SimplePointMarker(new Location(44.948575, -93.264897));
SimplePointMarker uptown = new SimplePointMarker(new Location(44.957005, -93.294430));
SimplePointMarker loringpark = new SimplePointMarker(new Location(44.970110, -93.283175));
SimplePointMarker nicolletpark = new SimplePointMarker(new Location(44.988587, -93.267568));
SimplePointMarker dinkytown = new SimplePointMarker(new Location(44.982389, -93.239279));
SimplePointMarker seward = new SimplePointMarker(new Location(44.961252, -93.237767));


/* bar chart related variables */
List < Marker > zapScanSums; //create global list object for our daily summaries
Float originX = 730.0;
Float originY = 860.0;


/* time animation related variable */
DateTime startTime;
DateTime endTime;
DateTime currentTime;


/* PROCESSING SETUP FUNCTION */
void setup() {
 /* set size to typical laptop screen size minus some*/
 size(1500, 900, P2D);


 /* define txt elements */
 title = "ZAP Bicycle Counts 2015, Twin Cities, MN";
 subtitle = "ZAP - An automated bike commuting recognition system logs trips by enrolled cyclists at over 50 reader locations.";
 charttitle = "Total ZAP counts per day, all locations combined.";


 /* load images */
 img = loadImage("clef_img.jpg");
 img_green = loadImage("green.png");
 img_pink = loadImage("pink.png");
 img_surface = loadImage("surface.png");


 /* set style for map labels */
 umnmpls.setColor(labelcolor);
 umnmpls.setStrokeColor(labelstrokecolor);
 umnmpls.setStrokeWeight(2);

 umnstpl.setColor(labelcolor);
 umnstpl.setStrokeColor(labelstrokecolor);
 umnstpl.setStrokeWeight(0);

 downtownmpls.setColor(labelcolor);
 downtownmpls.setStrokeColor(labelstrokecolor);
 downtownmpls.setStrokeWeight(0);

 como.setColor(labelcolor);
 como.setStrokeColor(labelstrokecolor);
 como.setStrokeWeight(0);


 /* create sound, set frequency to zero so it is not audible until bar chart and map are playing */
 minim = new Minim(this);
 au_out = minim.getLineOut();
 sqw = new SquareWave(261.63, 1, 44100);
 lpass = new LowPassSP(200, 44100);
 au_out.addSignal(sqw);
 au_out.addEffect(lpass);
 sqw.setFreq(0);


 /* crete the map, use Esri's grey canvas basemap*/
 map = new UnfoldingMap(this, new EsriProvider.WorldGrayCanvas());
 MapUtils.createDefaultEventDispatcher(this, map);
 tc = new Location(44.970805, -93.234856); //center on UMN Mpls. campus
 map.zoomAndPanTo(tc, 14);


 /* load data from geojson files */
  List < Feature > features3 = GeoJSONReader.loadData(this, "XYyearlyTotalsAndAvgs.geo.json"); //create a List of feature3 objects reading from  data file
 zapScanAvgs = MapUtils.createSimpleMarkers(features3); //create markers from each feature3 object and populate our zapScanAvgs list with it
 
 List < Feature > features2 = GeoJSONReader.loadData(this, "XYdailytotals2015.geo.json"); //create a List of feature2 objects reading from  data file
 zapScanSums = MapUtils.createSimpleMarkers(features2); //create markers from each feature2 object and populate the zapScanSums list with them

 List < Feature > features = GeoJSONReader.loadData(this, "XYstationtotals2015.geo.json"); //create a List of feature objects reading from  data file
 zapScans = MapUtils.createSimpleMarkers(features); //create markers from each feature and populate the zapScans list with them

 List < Float > countCollection = new ArrayList < Float > (); //create an empty lists to store all the zapScanCount values
 List < DateTime > dateCollection = new ArrayList < DateTime > (); //create an empty list to store date values


 /* determine the start time and zap count values by looping over the zapScans list and then getting these summary stats. */
 for (Marker i: zapScans) {
  Float count = Float.parseFloat(i.getStringProperty("count_as_string")); // get this marker's daily zap count.
  DateTimeFormatter f = DateTimeFormat.forPattern("MM-dd-yyyy");
  DateTime time = new DateTime(f.parseDateTime((i.getStringProperty("date_as_string")))); //get this marker's timestamp attribute. Due to data format use DateTimeFormatter
  countCollection.add(count); //add count value to countCollection list
  dateCollection.add(time); // add time value to dateCollection list
 }
 startTime = Collections.min(dateCollection);
 currentTime = startTime; //set the current time to the startTime

 maxZapScanCount = Collections.max(countCollection); //used for normalizing map symbol size
 minZapScanCount = Collections.min(countCollection); //used for normalizing map symbol size


 /* createan array of floating point values and populate it with frequencies corresponding to the notes in the musical scale Dm ajor. */
 frequencies = new float[73];
 frequencies[0] = 17.32; //C#
 frequencies[1] = 17.32; //C#
 frequencies[2] = 18.35; //D
 frequencies[3] = 20.60; //E
 frequencies[4] = 20.60; //E
 frequencies[5] = 23.12; //F#
 frequencies[6] = 23.12; //F#
 frequencies[7] = 24.50; //G
 frequencies[8] = 24.50; //G
 frequencies[9] = 27.50; //A
 frequencies[10] = 30.87; //B
 frequencies[11] = 30.87; //B
 frequencies[12] = 34.65; //C#
 frequencies[13] = 34.65; //C#
 frequencies[14] = 36.71; //D
 frequencies[15] = 41.20; //E
 frequencies[16] = 41.20; //E
 frequencies[17] = 46.25; //F#
 frequencies[18] = 46.25; //F#
 frequencies[19] = 49.00; //G
 frequencies[20] = 49.00; //G
 frequencies[21] = 55.00; //A
 frequencies[22] = 61.74; //B
 frequencies[23] = 61.74; //B
 frequencies[24] = 69.30; //C#
 frequencies[25] = 69.30; //C#
 frequencies[26] = 73.42; //D
 frequencies[27] = 82.41; //E
 frequencies[28] = 82.41; //E
 frequencies[29] = 92.50; //F#
 frequencies[30] = 92.50; //F#
 frequencies[31] = 98.00; //G
 frequencies[32] = 98.00; //G
 frequencies[33] = 110.0; //A
 frequencies[34] = 123.5; //B
 frequencies[35] = 123.5; //B
 frequencies[36] = 138.6; //C#
 frequencies[37] = 138.6; //C#
 frequencies[38] = 146.8; //D
 frequencies[39] = 164.8; //E
 frequencies[40] = 164.8; //E
 frequencies[41] = 185.0; //F#
 frequencies[42] = 185.0; //F#
 frequencies[43] = 196.0; //G
 frequencies[44] = 196.0; //G
 frequencies[45] = 220.0; //A
 frequencies[46] = 246.9; //B
 frequencies[47] = 246.9; //B
 frequencies[48] = 277.2; //C#
 frequencies[49] = 277.2; //C#
 frequencies[50] = 293.7; //D
 frequencies[51] = 329.6; //E
 frequencies[52] = 329.6; //E
 frequencies[53] = 370.0; //F#
 frequencies[54] = 370.0; //F#
 frequencies[55] = 392.0; //G
 frequencies[56] = 392.0; //G
 frequencies[57] = 440.0; //A
 frequencies[58] = 493.9; //B
 frequencies[59] = 493.9; //B
 frequencies[60] = 554.4; //C#
 frequencies[61] = 554.4; //C#
 frequencies[62] = 587.3; //D
 frequencies[63] = 659.3; //E
 frequencies[64] = 659.3; //E
 frequencies[65] = 740.0; //F#
 frequencies[66] = 740.0; //F#
 frequencies[67] = 784.0; //G
 frequencies[68] = 784.0; //G
 frequencies[69] = 880.0; //A
 frequencies[70] = 987.8; //B
 frequencies[71] = 987.8; //B
 frequencies[72] = 1109; //C#


 /* set the speed of the animation */
 frameRate(4); // frames to be displayed every second. default is 60

}//end setup

/* PROCESSING DRAW FUNCTION */
void draw() {
 map.draw(); //draw the map fist. nothing is "under" the map.


 /* place area text labels on map */
 textSize(14);
 textLeading(18);
 fill(0, 0, 0);
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


 /* interpolated surface and label display at end of animation. Note hard coded date values. TO-DO: remove dependency on hard coded values. */
 DateTimeFormatter after2015 = DateTimeFormat.forPattern("MM-dd-yyyy");
 DateTime after2015Time = new DateTime(after2015.parseDateTime("01-01-2016")); 
 DateTime after2015TimePlus = new DateTime(after2015.parseDateTime("02-01-2016"));
 if (currentTime.isAfter(after2015Time)) {
  if (currentTime.isAfter(after2015TimePlus)) {

  //after 01-01-2016 display legend that explains weekday | weekend average labels.
  strokeWeight(2);
  stroke(0);
  fill(255);
  rect(1175, 570, 1485, 640);
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

   //then after 02-01-2016 has passed also gradually fade in the image
   surf_opacity_counter = surf_opacity_counter + 0.8; //the rate at which the image will become less transparent
   tint(255, surf_opacity_counter);
   image(img_surface, 130, 165, 1237, 620);
   noTint();
  }
 }


 /* loop over each marker in zapScans and draw the ellipses occuring during 2015 */
 for (Marker i: zapScans) {
  /* get the dayly count, date, and day-type  property values */
  Float zapScanCount = Float.parseFloat(i.getStringProperty("count_as_string"));
  DateTimeFormatter f = DateTimeFormat.forPattern("MM-dd-yyyy");
  DateTime markerTime = new DateTime(f.parseDateTime(i.getStringProperty("date_as_string")));
  String dayType = i.getStringProperty("wd_or_we");

  /* check point's timeStamp and only if it's before currentTime + 1 day and after currentTime - 1 day draw it */
  if ((markerTime.isBefore(currentTime.plusDays(1))) && (markerTime.isAfter(currentTime.minusDays(1)))) {
   ScreenPosition coords = map.getScreenPosition(i.getLocation()); //translates a marker's lat/long values to local screen coordinates
   Float pointStroke = map(zapScanCount, minZapScanCount, maxZapScanCount, 0, 100); //normalizes count value will determine size of ellipse.
   stroke(0);
   strokeWeight(1);

   /* ellipses are color coded based on weekday vs. weekend day-type */
   if (dayType.equals("wd") == true) {
    fill(c_wd_map);
   }
   if (dayType.equals("we") == true) {
    fill(c_we);
   }

   ellipse(coords.x, coords.y, pointStroke, pointStroke); 

  } 
 } //end drawing ellipses loop


 /* loop over each marker  in zapScanAvgs and draw the ellipses occuring after 2015 */
 for (Marker i: zapScanAvgs) {
  /* get the daily count property values */
  Float zapScanCount_we = Float.parseFloat(i.getStringProperty("avg_zaps_per_we_day")); //get the avg. count for this station for weekend days
  Float zapScanCount_wd = Float.parseFloat(i.getStringProperty("avg_zaps_per_wd_day")); //get the avg. count for this station for weekday days
  Float labeloffsetY = Float.parseFloat(i.getStringProperty("extralabeloffsetY")); //get the extralabeloffsetY property. used for improved label placement 
  Float labeloffsetX = Float.parseFloat(i.getStringProperty("extralabeloffsetX")); //get the extralabeloffsetX property. used for improved label placement 
  DateTimeFormatter f1 = DateTimeFormat.forPattern("MM-dd-yyyy");
  DateTime markerTime1 = new DateTime(f1.parseDateTime(i.getStringProperty("date_as_string1"))); //get the date. This is beginning of 2016 for all of these points because we only want to display this data after 2015 days have finished
  
  /* if it's after 2015 draw thes*/
  if (currentTime.isAfter(markerTime1.plusDays(1))) {

   ScreenPosition coords = map.getScreenPosition(i.getLocation()); //Translates a marker's lat/long values to our local screen coordinates
   
   /* draw the ellipls showing avg. weekday day station counts */
   Float pointStroke1 = map(zapScanCount_wd, minZapScanCount, maxZapScanCount, 0, 100); //normalize to determine the size if the ellipse
   stroke(c_wd_map);
   strokeWeight(2);
   fill(0, 0, 0, 1);
   ellipse(coords.x, coords.y, pointStroke1, pointStroke1); //draw an ellipse and set the size based on the point's pointStroke value 

   /* draw the ellipls showing avg. weekend day station counts */
   Float pointStroke2 = map(zapScanCount_we, minZapScanCount, maxZapScanCount, 0, 100); //the map function in Processing normalizes a given values.
   stroke(c_we);
   strokeWeight(2);
   ellipse(coords.x, coords.y, pointStroke2, pointStroke2); //draw an ellipse and set the size based on the point's pointStroke value 

   /* avg. daily zap count label placement is dependent on number of digits in zapScanCount_wd and the marker's labeloffsetY and labeloffsetX values*/
   textSize(16);
   fill(c_wd_map);
   String label_wd = i.getStringProperty("avg_zaps_per_wd_day");
   Float label_wd_x = coords.x + pointStroke1 / 2 + labeloffsetX;
   Float label_wd_y = coords.y + pointStroke1 / 2 + labeloffsetY;
   text(label_wd, label_wd_x, label_wd_y); //place the weekday count label

   if (zapScanCount_wd > 99) {
    textSize(16);
    fill(150);
    String divider = "|";
    Float div_x = coords.x + pointStroke1 / 2 + 29 + labeloffsetX;
    Float div_y = coords.y + pointStroke1 / 2 + labeloffsetY;
    text(divider, div_x, div_y); //place the divider pipe

    textSize(16);
    fill(c_we);
    String label_we = i.getStringProperty("avg_zaps_per_we_day");
    Float label_we_x = coords.x + pointStroke1 / 2 + 35 + labeloffsetX;
    Float label_we_y = coords.y + pointStroke1 / 2 + labeloffsetY;
    text(label_we, label_we_x, label_we_y); //place the weekend count label
   }

   if ((zapScanCount_wd < 99) && (zapScanCount_wd > 10)) {
    textSize(16);
    fill(150);
    String divider = "|";
    Float div_x = coords.x + pointStroke1 / 2 + 19 + labeloffsetX;
    Float div_y = coords.y + pointStroke1 / 2 + labeloffsetY;
    text(divider, div_x, div_y); //place the divider pipe

    textSize(16);
    fill(c_we);
    String label_we = i.getStringProperty("avg_zaps_per_we_day");
    Float label_we_x = coords.x + pointStroke1 / 2 + 25 + labeloffsetX;
    Float label_we_y = coords.y + pointStroke1 / 2 + labeloffsetY;
    text(label_we, label_we_x, label_we_y); //place the weekend count label
   }

   if (zapScanCount_wd < 10) {
    textSize(16);
    fill(150);
    String divider = "|";
    Float div_x = coords.x + pointStroke1 / 2 + 9 + labeloffsetX;
    Float div_y = coords.y + pointStroke1 / 2 + labeloffsetY;
    text(divider, div_x, div_y); //place the divider pipe

    textSize(16);
    fill(c_we);
    String label_we = i.getStringProperty("avg_zaps_per_we_day");
    Float label_we_x = coords.x + pointStroke1 / 2 + 15 + labeloffsetX;
    Float label_we_y = coords.y + pointStroke1 / 2 + labeloffsetY;
    text(label_we, label_we_x, label_we_y); //place the weekend count label
   }
  }
 } //end avg. daily zap count loop


/* the area containing the title, bar chart, etc.  */

 rectMode(CORNERS);
 stroke(255); 
 fill(0);
 rect(500, 645, 1490, 885, 7); //background rectangle


 //ellipse symbols map key. Note this is hard coded. TO-DO: remove dependency on hard coded values.
 ellipse(originX - 160, originY - 38, 97, 97); //97px is for 400 if we are mapping max value of 414 to 100px
 ellipse(originX - 160, originY - 23, 68, 68); //68px is for 200 if we are mapping max value of 414 to 100px
 ellipse(originX - 160, originY - 14, 48, 48); //48px is for 100 if we are mapping max value of 414 to 100px
 ellipse(originX - 160, originY - 6, 34, 34); //48px is for 50 if we are mapping max value of 414 to 100px


 //x-y axis of bar chart
 stroke(255, 255, 255);
 strokeWeight(2); 
 line(originX, originY, originX + 730 + 2, originY); //x-axis
 line(originX, originY, originX, originY - 110); //y-axis
 image(img, originX - 85, originY - 100); //the musical key image


 /* horizontal dashed lines on bar chart*/
 strokeWeight(1);
 stroke(255, 255, 255);
 float x1 = 635;
 float y25 = originY + 2 - 25;
 float y50 = originY + 2 - 50;
 float y75 = originY + 2 - 75;
 float y100 = originY + 2 - 100;
 for (int i = 0; i <= 102; i++) {
  x1 = x1 + 8;
  point(x1, y25);
  point(x1, y50);
  point(x1, y75);
  point(x1, y100);
 }


 /* dividing lines between months */
 stroke(255, 255, 255);
 strokeWeight(1);
 line(originX + 31 * 2, originY, originX + 31 * 2, originY + 6); //jan|feb
 line(originX + 31 * 2 + 28 * 2, originY, originX + 31 * 2 + 28 * 2, originY + 6); //feb|mar
 line(originX + 31 * 2 + 28 * 2 + 31 * 2, originY, originX + 31 * 2 + 28 * 2 + 31 * 2, originY + 6); //mar|apr
 line(originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2, originY, originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2, originY + 6); //apr|may
 line(originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2, originY, originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2, originY + 6); //may|jun
 line(originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2, originY, originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2, originY + 6); //jun|jul
 line(originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2, originY, originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2, originY + 6); //jul|aug
 line(originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2, originY, originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2, originY + 6); //aug|sep
 line(originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2 + 30 * 2, originY, originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2 + 30 * 2, originY + 6); ///sep|oct
 line(originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2 + 30 * 2 + 31 * 2, originY, originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2 + 30 * 2 + 31 * 2, originY + 6); //oct|nov
 line(originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2, originY, originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2, originY + 6); //nov|dec
 

 /* tick marks on y axis */
 strokeWeight(1);
 line(originX - 6, originY + 2 - 25, originX, originY + 2 - 25);
 line(originX - 6, originY + 2 - 50, originX, originY + 2 - 50);
 line(originX - 6, originY + 2 - 75, originX, originY + 2 - 75);
 line(originX - 6, originY + 2 - 100, originX, originY + 2 - 100);


 /* infobox text elements */
 textSize(11);
 fill(0);
 text("Data: University of Minnesota Parking and Transportation Services, Esri, DeLorme, NAVTEQ   Created by: Tobias Fimpel", 850, 895);
 fill(255);
 textSize(24);
 text(title, 720, 675);
 textSize(15);
 text(subtitle, 566, 700);
 textSize(13);
 text(charttitle, 925, 735);
 text("0", originX - 14, originY - 2);
 text("500", originX - 29, originY - 25);
 text("1000", originX - 38, originY - 50);
 text("1500", originX - 38, originY - 75);
 text("2000", originX - 38, originY - 100);
 text("Jan", originX + 20, originY + 14);
 text("Feb", originX + 31 * 2 + 20, originY + 14);
 text("Mar", originX + 31 * 2 + 28 * 2 + 20, originY + 14);
 text("Apr", originX + 31 * 2 + 28 * 2 + 31 * 2 + 20, originY + 14);
 text("May", originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 20, originY + 14);
 text("Jun", originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 20, originY + 14);
 text("Jul", originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 20, originY + 14);
 text("Aug", originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 20, originY + 14);
 text("Sep", originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2 + 20, originY + 14);
 text("Oct", originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2 + 30 * 2 + 20, originY + 14);
 text("Nov", originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 20, originY + 14);
 text("Dec", originX + 31 * 2 + 28 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 31 * 2 + 30 * 2 + 31 * 2 + 30 * 2 + 20, originY + 14);
 text("Weekday", 560, 735);
 text("Weekend", 560, 755);
 text("400", originX - 172, originY - 74);
 textSize(12);
 text("200", 559, originY - 43);
 textSize(11);
 text("100", 560, originY - 27);
 textSize(10);
 text("50", 564, originY - 11);


 /* scribble line to show what pink/green color means */
 image(img_green, 530, 725);
 image(img_pink, 530, 745);



 /* loop over zapScanSums list, draw the bars in the chart and play the sound */
 for (Marker i: zapScanSums) {

  /* get the marker's property values */
  Float zapScanSum = Float.parseFloat(i.getStringProperty("Sum_count_as_string")); //get the count
  Float dayCount = Float.parseFloat(i.getStringProperty("day_of_year")); //get the day-number. This is used instead of currentTime. REquires some addtl. data preprocessing but makes it simpler here.
  String dayType = i.getStringProperty("wd_or_we"); //get the day type
  DateTimeFormatter f = DateTimeFormat.forPattern("MM-dd-yyyy");
  String t = i.getStringProperty("date_as_string");
  DateTime barTime = new DateTime(f.parseDateTime(t)); //get the date as date

  /* check point's timeStamp and only if it's smaller than currentTime plus one day draw a bar into the bar chart. color code based on weekend vs weekday day. */
  if (barTime.isBefore(currentTime.plusDays(1))) {
   if (dayType.equals("wd") == true) {
    stroke(c_wd);
   }
   if (dayType.equals("we") == true) {
    stroke(c_we);
   }
   strokeWeight(2);
   line(originX + 2 + dayCount * 2, originY - 2, originX + 2 + dayCount * 2, originY - 2 - zapScanSum * 0.05); // keep track of horizontal location in dayCount variable 
  }

  /* if the marker's date is before currentTime plus one day and after currentTime minus one day play the sound */
  if ((barTime.isBefore(currentTime.plusDays(1))) && (barTime.isAfter(currentTime.minusDays(1)))) {
   sqw.setFreq(zapScanSum / 3);
   //find the closest note in D major scale to the value zapScanSum/2. TO-DO: since our array is sorted this function could be much more efficient.
   float calculatedNumber = zapScanSum / 2;
   int distance = int(Math.abs(frequencies[0] - calculatedNumber));
   int idx = 0;
   for (int c = 1; c < frequencies.length; c++) {
    int cdistance = int(Math.abs(frequencies[c] - calculatedNumber));
    if (cdistance < distance) {
     idx = c;
     distance = cdistance;
    }
   }
   int approximatedFrequency = int(frequencies[idx]);
   sqw.setFreq(approximatedFrequency);

   /* update the date display to show the date*/
   strokeWeight(2);
   stroke(0);
   fill(255);
   rect(1320, 610, 1485, 640);
   textAlign(RIGHT);
   fill(0);
   textSize(24);
   text(" " + t, 1480, 635);
   textAlign(LEFT);
  }
 } //end loop over zapScanSums list



 /* advance the currentTime by one day before draw function is called again */
 currentTime = currentTime.plusDays(1);

 /* start over once year 2016 is over */
 if (currentTime.isAfter(endTime)) {
  surf_opacity_counter = 0.0; //make the interpolated surface image invisible again
  currentTime = startTime; //set currentTime to startTime
 }

 /* to export frames to images for input in Processing's Movie Maker tool */
 //saveFrame("frames/####.png");

} //end draw function
