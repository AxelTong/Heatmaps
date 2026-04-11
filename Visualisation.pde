String[] rowLabels;
String[] colLabels;
float[][] values;

int rows;
int cols;

void setup() {
  size(1200, 720);
  generateMockData(50, 14);
  noLoop();
}

void draw() {
  background(245);

  // deze afstanden vallen uiteraard nog aan te passen naar gelang onze effectieve lay-out
  // k heb zoveel mogelijk afstanden benoemd, is mogelijks wa onnodig maar ik vond dit overzichtelijker, nogmaals hier valt mee te spelen

  float marginLeft = 120;
  float marginTop = 80;
  float marginRight = 40;
  float marginBottom = 40;

  float gridWidth = width - marginLeft - marginRight;
  float gridHeight = height - marginTop - marginBottom;

  float cellW = gridWidth / cols;
  float cellH = gridHeight / rows;

  // Heatmap cellen, klassieke for loups gebruik
  noStroke();
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      float val = values[r][c];
      // Axel had de normalisering reeds op een andere manier gedaan, deze zullen we voor de defenitieve versie gebruiken maar ik had map ff gebruikt om te zien of mijn cellen deftig kleuren
      float norm = map(val, 0, 100, 0, 1);
      color cellColor = lerpColor(
        color(0, 100, 255),
        color(255, 60, 60),
        norm);

      fill(cellColor);

      float x = marginLeft + c * cellW;
      float y = marginTop + r * cellH;

      rect(x, y, cellW, cellH);
    }
  }


  // Boord rond cell
  noFill();
  stroke(180);
  rect(marginLeft, marginTop, gridWidth, gridHeight);
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