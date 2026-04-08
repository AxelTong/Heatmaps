/**
 Group project: Heatmaps
 */
float[][] testing = {{7, 10, 5}, {7, 7, 10}, {5, 2, 9}};



void setup() {
  size(400, 400);
  background(255);
  calc test = new calc(3, 3, testing);
  printArray(testing[0]);
  println("means");
  println(test.calculateColumnMeans());
  println("stds");
  println(test.calculateColumnStds());
  println("norm");
  printArray(test.normalize()[0]);
  printArray(test.normalize()[1]);
  printArray(test.normalize()[2]);
  println("distance matrix");
  printArray(test.distanceMatrix(test.distanceMatrix(testing))[0]);
  printArray(test.distanceMatrix(test.distanceMatrix(testing))[1]);
  printArray(test.distanceMatrix(test.distanceMatrix(testing))[2]);
}

void draw() {
}
