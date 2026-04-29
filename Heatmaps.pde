/**
 Group project: Heatmaps
 */
import processing.event.MouseEvent;
// =========================
//  DATA
// =========================

float[][] values;
float[][] normalized;
float[][] clusteredRaw;
float[][] clusteredNorm;
float[][] linkage;
int[] rowOrder;
String[] headers;
boolean[] categorical;
float[] normMin;
float[] normMax;
int lowerBound;
int upperBound;

int rows;
int cols;
// =========================
//  COLORS
// =========================
color lowColor;
color highColor;

// =========================
// LAYOUT
// =========================

// Margins heatmap
float marginLeft = 360;
float marginTop = 80;
float marginRight = 70;
float marginBottom = 40;
//Celafmetingen
float cellH = 24;
float cellW = 55;
// Minimale en maximale celhoogte voor het scrollen
float maxCellH = 50;
float minCellH = 2;

// =========================
// SCROLLEN
// =========================
float scrollY = 0;
float scrollSpeed = 30;
// Scrollbar (lichtgrijze)
float scrollbarWidth = 16;
float scrollbarX;
float scrollbarY;
float scrollbarH;

float thumbY;
float thumbH;
boolean draggingThumb = false;
float dragOffsetY = 0;
// =========================
// SETUP
// =========================

void setup() {
  size(1200, 720);

  // kleuren grading
  lowColor = color(120, 180, 120);
  highColor = color(180, 80, 80);
  lowerBound = -3; // grenzen voor kleuring
  upperBound = 3;

  loadCSV("heart.csv");

  calc calculate = new calc(cols, rows, values, headers);
  categorical = calculate.matchCategoricals();
  normalized = calculate.normalize();
  clusteredRaw = calculate.getClusteredRaw();
  clusteredNorm = calculate.getClusteredNorm();
  normMax = calculate.getNormColumnMax();
  normMin = calculate.getNormColumnMin(); 
  float[][] linkage = new float[rows][cols];
  linkage = calculate.getLinkageMatrix();
  for (int i = 0; i < linkage.length; i++) { // debug print linkage matrix, ff afblijven pls
    for (int j = 0; j < linkage[i].length; j++) {
      print(linkage[i][j]);
      print(" ");
    }
    println();
  }
  println(clusteredNorm[0]);

  //println(calculate.getSortedPatientOrderFromLinkage());
}
// =========================
// CSV LADEN
// =========================

void loadCSV(String filename) {
  Table table = loadTable(filename, "header");

  headers = table.getColumnTitles();

  // Verwijder rijen met ontbrekende waarden
  for (int r = table.getRowCount() - 1; r >= 0; r--) {
    TableRow row = table.getRow(r);
    boolean hasMissingValue = false;

    for (int c = 0; c < table.getColumnCount(); c++) {
      if (row.getString(c).equals("?")) {
        hasMissingValue = true;
        break;
      }
    }

    if (hasMissingValue) {
      table.removeRow(r);
    }
  }

  rows = table.getRowCount();
  cols = table.getColumnCount();

  values = new float[rows][cols];

  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      values[r][c] = table.getFloat(r, c);
    }
  }
}

float[][] reorderRows(float[][] data, int[] order) {
  float[][] result = new float[order.length][data[0].length];

  for (int newR = 0; newR < order.length; newR++) {
    int oldR = order[newR];

    for (int col = 0; col < data[0].length; col++) {
      result[newR][col] = data[oldR][col];
    }
  }

  return result;
}

// =========================
// DRAW
// =========================
void draw() {
  background(245);
  float gridWidth = width - marginLeft - marginRight;
  float gridHeight = height - marginTop - marginBottom;

 // We kiezen een vaste celhoogte, in tegenstelling tot de kolommen, zodat scrollen nodig wordt
  float HeightAllCells = rows * cellH;
  // onderstaande regels zorgen ervoor dat je niet verder kan scrollen dan nodig en dat je thumb wordt aangepast aan het aantal cellen
  float maxScrollY = max(0, HeightAllCells - gridHeight);
  scrollY = constrain(scrollY, 0, maxScrollY);

  // titels
  textSize(14);
  for (int i = 0; i < headers.length; i++) {
    text(headers[i], marginLeft + i * cellW, marginTop - 10);
  }

  // aftiteling
  textSize(10);
  fill(0);
  text("by Axel Tong, Hanin El Tabaa and Maarten De Feyter", 10, height - 20);

// =========================
// LEGEND BOX
// =========================
  float lx = 20;
  float ly = marginTop;
  float lw = 300;
  float lh = 260;

  noStroke();
  fill(255, 240);
  rect(lx, ly, lw, lh, 12);

  stroke(180);
  noFill();
  rect(lx, ly, lw, lh, 12);

  fill(0);
  textSize(13);
  text("Legend", lx + 12, ly + 20);

  textSize(10);
  float lyy = ly + 40;

  String[] legendLines = {
    "age = Age in years",
    "sex = 1 male, 0 female",
    "cp = Chest pain type (0–3)",
    "trestbps = Resting blood pressure",
    "chol = Serum cholesterol",
    "fbs = Fasting blood sugar",
    "restecg = Resting ECG results",
    "thalach = Max heart rate",
    "exang = Exercise-induced angina",
    "oldpeak = ST depression",
    "slope = ST segment slope",
    "ca = Major vessels (0–3)",
    "thal = Thalassemia",
    "target = 1 disease, 0 no disease"
  };

  for (String line : legendLines) {
    text(line, lx + 12, lyy);
    lyy += 14;
  }
    

// =========================
// HEATMAP CELLS + SCROLLBAR + HOVER
// =========================
  
// BOARDER HEATMAP
fill(0);
rect(marginLeft - 2, marginTop - 2, gridWidth + 4, gridHeight + 4);

// CELLEN AANKLEUREN 
 clip((int)marginLeft, (int)marginTop, (int)gridWidth, (int)gridHeight);

 noStroke();
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {

color cellColor;

float normVal = clusteredNorm[r][c];
float norm;

if (categorical[c]) {
  norm = map(normVal, normMin[c], normMax[c], 0, 1);
} else { // Numerieke kolommen: kleur wordt vastgezet tussen lowerBound en upperBound, zoals Lorenzo voorstelde zodat extreme outliers niet de hele kleurenschaal bepalen.
  normVal = constrain(normVal, lowerBound, upperBound);
  norm = map(normVal, lowerBound, upperBound, 0, 1);
}

norm = constrain(norm, 0, 1);

cellColor = lerpColor(lowColor, highColor, norm);

fill(cellColor);

// CELLEN TEKENEN

      float x = marginLeft + c * cellW;
      float y = marginTop + r * cellH - scrollY;
      rect(x, y, cellW, cellH);
      stroke(200, 80);   // light grey
      strokeWeight(1);
      line(marginLeft, marginTop + r * cellH - scrollY, marginLeft + gridWidth, marginTop + r * cellH - scrollY);

    }
  }

  noClip();

  
  fill(0);
  rect(318,478,24,204);
  setGradient(320, 480, 20, 200, lowColor, highColor); 
  
int hoveredRow = -1;

// HOVER + PT OVERVIEW

  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {

      float x = marginLeft + c * cellW;
      float y = marginTop + r * cellH - scrollY;

      if (mouseX > x && mouseX < x + cellW &&
          mouseY > y && mouseY < y + cellH) {
          hoveredRow = r;
        String label = headers[c] + ": " + clusteredRaw[r][c];

     
        float tw = 105;
        float th = 20;

        float tx = mouseX + 12;
        float ty = mouseY - 25;

       

        fill(0, 180);
        noStroke();
        rect(tx, ty, tw, th, 5);

        fill(255);
        text(label, tx + 5 , ty + 13);

        noFill();
      
      }
    }
    if (hoveredRow != -1) {
  drawPatientOverview(hoveredRow);
}
  }

// =========================
// SCROLL
// =========================
  scrollbarX = marginLeft + gridWidth + 20;
  scrollbarY = marginTop;
  scrollbarH = gridHeight;

  noStroke();
  fill(230);
  rect(scrollbarX, scrollbarY, scrollbarWidth, scrollbarH, 8);

  float visibleRatio = gridHeight / HeightAllCells;  
  thumbH = min(scrollbarH, max(40, scrollbarH * visibleRatio)); // maar kan niet groter worden dan de scrollbar zelf, dus we nemen de min van deze ratio en 1
  float maxThumb = scrollbarH - thumbH;

  if (maxScrollY == 0) {
    thumbY = scrollbarY;
  } else if (!draggingThumb) {
    thumbY = scrollbarY + map(scrollY, 0, maxScrollY, 0, maxThumb);
  }

  // Thumb tekenen
  fill(draggingThumb ? 120 : 150);
  rect(scrollbarX, thumbY, scrollbarWidth, thumbH, 8);
}

// =========================
// END DRAW
// =========================


// =========================
// GRADIENT LEGEND
// =========================
void setGradient(int x, int y, float w, float h, color c1, color c2) {

    for (int i = y; i <= y+h; i++) {
      float inter = map(i, y, y+h, 0, 1);
      color c = lerpColor(c1, c2, inter);
      stroke(c);
      line(x, i, x+w, i);
    }
    text("-2", x - 20, y + h );
    text("0", x - 20, y + h / 2);
    text("2", x - 20, y + 5);
  
}

// =========================
// SCROLLEN
// =========================
void mouseWheel (MouseEvent event) {
  float e = event.getCount();
  scrollY += e * scrollSpeed;
}

void keyPressed() {
  if (keyCode == DOWN) {
    scrollY += scrollSpeed;
  } else if (keyCode == UP) {
    scrollY -= scrollSpeed;
  }

  if (key == '-') {
    cellH = max(minCellH, cellH - 2); // door max function te gebruiken voorkomen we dat cellH kleiner wordt dan minCellH, wat zou resulteren in een negatieve of nul celhoogte, wat niet zinvol is voor visualisatie.
  }

  if (key == '+') {
    cellH = min(maxCellH, cellH + 2); // door min function te gebruiken voorkomen we dat cellH groter wordt dan maxCellH, wat zou resulteren in een onpraktische grote celhoogte, waardoor de heatmap moeilijk te navigeren zou zijn.
  }
}

void mousePressed() {
  if (mouseX >= scrollbarX && mouseX <= scrollbarX + scrollbarWidth &&
    mouseY >= thumbY && mouseY <= thumbY + thumbH) {
    draggingThumb = true;
    dragOffsetY = mouseY - thumbY;
  } else if (mouseX >= scrollbarX && mouseX <= scrollbarX + scrollbarWidth &&
    mouseY >= scrollbarY && mouseY <= scrollbarY + scrollbarH) {
    // vervolgens is er een verschil tussen het klikken en het draggen
    // Klik op de track verplaatst de thumb; / 2 opdat de thumb int midden van u lijntje sta
    float newThumbY = mouseY - thumbH ;
    updateScrollFromThumb(newThumbY);
  }
}



void mouseDragged() {
  if (draggingThumb) {
    float newThumbY = mouseY - dragOffsetY;
    updateScrollFromThumb(newThumbY);
  }
}

void mouseReleased() {
  draggingThumb = false;
}


  void updateScrollFromThumb(float newThumbY) {
  float gridHeight = height - marginTop - marginBottom;
  float totalContentHeight = rows * cellH;
  float maxScrollY = max(0, totalContentHeight - gridHeight);

  float maxThumbTravel = scrollbarH - thumbH;

  // checken of scrollen uberhaupt mogelijk is
  if (maxThumbTravel <= 0 || maxScrollY <= 0) {
    scrollY = 0;
    thumbY = scrollbarY;
    return;
  }

  thumbY = constrain(newThumbY, scrollbarY, scrollbarY + maxThumbTravel);
  scrollY = map(thumbY, scrollbarY, scrollbarY + maxThumbTravel, 0, maxScrollY);
}


// =========================
//  PATIENT OVERVIEW
// =========================
void drawPatientOverview(int r) {
  float x = 20;
  float y = 400;
  float w = 200;
  float h = 250;
// card background 
  noStroke();
  fill(255, 240);    // slightly transparent white
  rect(x, y, w, h, 12);
// card border
  stroke(180);
  strokeWeight(1);
  noFill();
  rect(x, y, w, h, 12);
//title 
  fill(0);
  textSize(13);
  text("Patiënt " + r, x + 10, y + 20);

  textSize(11);
  float lineY = y + 40;

  for (int c = 0; c < cols; c++) {
    String txt = headers[c] + ": " + clusteredRaw[r][c];
    text(txt, x + 10, lineY);
    lineY += 14;
  }
}