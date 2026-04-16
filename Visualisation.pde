import processing.event.MouseEvent;

float[][] values;

int rows;
int cols;

// Layout
float marginLeft = 120;
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

void setup() {
  size(1200, 720);
  generateMockData(300, 14);
}

void draw() {
  background(245);

  float gridWidth = width - marginLeft - marginRight;
  float gridHeight = height - marginTop - marginBottom;

  // Zorgt ervoor dat ongeacht de aantal rijen de kolommen passen
  float cellW = gridWidth / cols;

  // We kiezen een vaste celhoogte, in tegenstelling tot de kolommen, zodat scrollen nodig wordt
  float cellH = 24;
  float HeightAllCells = rows * cellH;
  // onderstaande regels zorgen ervoor dat je niet verder kan scrollen dan nodig en dat je thumb wordt aangepast aan het aantal cellen
  float maxScrollY = max(0, HeightAllCells - gridHeight);
  scrollY = constrain(scrollY, 0, maxScrollY);

  // Heatmap achtergrond
  noStroke();
  fill(255);
  rect(marginLeft, marginTop, gridWidth, gridHeight);

  // ik heb de 'viewport' aangeduid met de reeds bepaalde integers; deze kunnen vrij simpel worden aangepast indien nodig. De clip-functie maakt dit simpel
  clip((int)marginLeft, (int)marginTop, (int)gridWidth, (int)gridHeight);

  // Heatmap cellen
  noStroke();
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      float val = values[r][c];

      // Voorlopige normalisatie voor demo
      float norm = map(val, 0, 100, 0, 1);
      color cellColor = lerpColor(
        color(0, 100, 255),
        color(255, 60, 60),
        norm
        );

      fill(cellColor);


      // De 'scrollY' is where the magic happens wat betreft scrollfunctie; deze hangt af van het scrollen
      float x = marginLeft + c * cellW;
      float y = marginTop + r * cellH - scrollY;
      rect(x, y, cellW, cellH);
    }
  }

  noClip();

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

void generateMockData(int rCount, int cCount) {
  rows = rCount;
  cols = cCount;
  values = new float[rows][cols];


  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      values[r][c] = random(0, 100);
    }
  }
}