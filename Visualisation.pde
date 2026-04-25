import processing.event.MouseEvent;

float[][] values;
float[][] normalized;

String[] headers = {"age", "sex", "cp", "trestbps", "chol", "fbs", "restecg", "thalach", "exang", "oldpeak", "slope", "ca", "thal", "target"};

int rows;
int cols;

// grading kleuren
color c1, c2;

// Layout
float marginLeft = 360;
float marginTop = 80;
float marginRight = 70;
float marginBottom = 40;

// Scrollen
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

//cellen
float cellH = 24;
float cellW = 55;
float maxCellH = 50;
float minCellH = 2;

void setup() {
  
  size(1200, 720);

  // kleuren grading
  c1 = color(120, 180, 120);
  c2 = color(180, 80, 80);


  loadCSV("heart.csv");
  calc test = new calc(cols, rows, values);
  calc a = new calc(testing.length, testing[0].length, testing);
  //printArray(test.normalize()[0][11]);
  //println(test.calculateColumnStds());
  normalized = test.normalize();
  printArray(a.calculateDistanceMatrix(testing)[0]);
  printArray(a.calculateDistanceMatrix(testing)[1]);
  printArray(a.calculateDistanceMatrix(testing)[2]);
}

void loadCSV(String heartCSV) { // Deze functie laadt de CSV en zet deze om in een 2D array van floats
  Table table = loadTable(heartCSV, "header"); // Zorgt ervoor dat de eerste rij als header wordt gezien
// Remove all rows that contain a "?"
  for (int r = table.getRowCount() - 1; r >= 0; r--) {
    TableRow row = table.getRow(r);

    boolean hasmissing = false;

    for (int c = 0; c < table.getColumnCount(); c++) {
      String cell = row.getString(c);
      if (cell.equals("?")) {
        hasmissing = true;
        break;
      }
    }

    if (hasmissing) {
      table.removeRow(r);
    }
  }
  rows = table.getRowCount(); // Het aantal rijen in de CSV wordt opgeslagen in de variabele 'rows'
  cols = table.getColumnCount(); // Het aantal kolommen in de CSV wordt opgeslagen in de variabele 'cols'

  values = new float[rows][cols]; // Er wordt een 2D array van floats (getal met decimalen) gemaakt met de afmetingen van het aantal rijen en kolommen

  for (int r = 0; r < rows; r++) { // Loop door alle rijen en kolommen en kopieer elke waarde uit de tabel 
    for (int c = 0; c < cols; c++) {
      values[r][c] = table.getFloat(r, c);
    }
  }
}

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
  text("by Axel Tong, X and Maarten De Feyter", 10, height - 20);

  // legend
   textSize(10);
  fill(0);
  text("age = Age in years", 10, 20 + marginTop);
  text("sex = Sex (1 = male; 0 = female)", 10, 40 + marginTop);
  text("cp = Chest pain type (0-3)", 10, 60 + marginTop);
  text("trestbps = Resting blood pressure", 10, 80 + marginTop);
  text("chol = Serum cholesterol", 10, 100 + marginTop);
  text("fbs = Fasting blood sugar", 10, 120 + marginTop);
  text("restecg = Resting electrocardiographic results", 10, 140 + marginTop);
  text("thalach = Maximum heart rate achieved", 10, 160 + marginTop);
  text("exang = Exercise induced angina", 10, 180 + marginTop);
  text("oldpeak = ST depression induced by exercise relative to rest", 10,
  200 + marginTop);
  text("slope = The slope of the peak exercise ST segment", 10,
  220 + marginTop);
  text("ca = Number of major vessels (0-3) colored by flouroscopy", 10, 240 + marginTop);
  text("thal = Thalassemia", 10, 260 + marginTop);
  text("target = 1 or 0 (disease or no disease)", 10, 280 + marginTop);   



 


  // Heatmap achtergrond + aflijning
  fill(0);
  rect(marginLeft - 2, marginTop - 2, gridWidth + 4, gridHeight + 4);

  // ik heb de 'viewport' aangeduid met de reeds bepaalde integers; deze kunnen vrij simpel worden aangepast indien nodig. De clip-functie maakt dit simpel
  clip((int)marginLeft, (int)marginTop, (int)gridWidth, (int)gridHeight);

  // Heatmap cellen kleuren
  noStroke();
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
  

  
float val = values[r][c];
color cellColor;

if (headers[c].equals("sex") || headers[c].equals("fbs") ||
    headers[c].equals("exang") || headers[c].equals("target")) {

  // categorische  binaire kolommen: vaste kleuren
  if (val == 1) {
    cellColor = color(120, 180, 120);      
  } else {
    cellColor = color(180, 80, 80);     
  }

} else {
  // numerieke kolommen: gebruik je genormaliseerde waarde
  float normVal = normalized[r][c];
  float norm = map(normVal, -2, 2, 0, 1);
  norm = constrain(norm, 0, 1);

  cellColor = lerpColor(c1, c2, norm);
}

fill(cellColor);



      // De 'scrollY' is where the magic happens wat betreft scrollfunctie; deze hangt af van het scrollen
      float x = marginLeft + c * cellW;
      float y = marginTop + r * cellH - scrollY;
      rect(x, y, cellW, cellH);
    }
  }

  noClip();

  // grading + rand
  
  fill(0);
  rect(318,478,24,204);
  setGradient(320, 480, 20, 200, c1, c2); 
  

  // Hover functie

  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {

      float x = marginLeft + c * cellW;
      float y = marginTop + r * cellH - scrollY;

      if (mouseX > x && mouseX < x + cellW &&
          mouseY > y && mouseY < y + cellH) {

        String label = headers[c] + ": " + values[r][c];

     
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
  }



    


  // Boord rond heatmap
  noFill();
  stroke(180);
  rect(marginLeft, marginTop, gridWidth, gridHeight);

  // Scrollbar 'track', heb ze voorlopig grijs gemaakt (230)
  scrollbarX = marginLeft + gridWidth + 20;
  scrollbarY = marginTop;
  scrollbarH = gridHeight;

  noStroke();
  fill(230);
  rect(scrollbarX, scrollbarY, scrollbarWidth, scrollbarH, 8);

  // grootte v thumb berekenenn past zich aan aan het aantal rijen
  float visibleRatio = gridHeight / HeightAllCells;
  thumbH = max(40, scrollbarH * visibleRatio);


  //
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

//  color grading
void setGradient(int x, int y, float w, float h, color c1, color c2) {

    for (int i = y; i <= y+h; i++) {
      float inter = map(i, y, y+h, 0, 1);
      color c = lerpColor(c1, c2, inter);
      stroke(c);
      line(x, i, x+w, i);
    }
}

// Drie manieren om te scrollen; scrollen (mousewheel), slepen (mousepressed) en pijltjes (keypressed)
// deze functie is gevonden op reference van processing
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
    cellH = max(minCellH, cellH - 2);
  }

  if (key == '+') {
    cellH = min(maxCellH, cellH + 2);
  }
}


// Dit was een best lastig deel; maar na wat yt filmpjes relatief simpel

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
  float cellH = 24;
  float totalContentHeight = rows * cellH;
  float maxScrollY = max(0, totalContentHeight - gridHeight);

  float maxThumbTravel = scrollbarH - thumbH;


  // checken of scrollen uberhaupt mogelijk is
  if (maxThumbTravel <= 0 || maxScrollY <= 0) {
    scrollY = 0;
    thumbY = scrollbarY;
    return;
  }
  // zeer belangrijk stuk; het mappen van scroll y maakt
  thumbY = constrain(newThumbY, scrollbarY, scrollbarY + maxThumbTravel);
  scrollY = map(thumbY, scrollbarY, scrollbarY + maxThumbTravel, 0, maxScrollY);
}


