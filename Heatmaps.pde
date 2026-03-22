/**
 Group project: Heatmaps
 */
float[][] testing = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}};



void setup() {
  size(400, 400);
  background(255);
  calc test = new calc(3, 3, testing);
  printArray(testing[0]);
  //println(test.calculateColumnMeans());
  //println(test.calculateColumnStds());
  printArray(test.normalize()[1]);
}

void draw() {
}
