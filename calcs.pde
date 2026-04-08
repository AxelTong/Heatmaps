//check todo at bottom
class calc {
    int columns;
    int rows;
    float[][] input;
    float[][] normalized;
    float[][] distanceMatrix;
    float[][] inputMatrix;
    float[][] clustered;
    float[] columnMeans;
    float[] columnStds;

    calc(int columns, int rows, float[][] input) {
        this.columns = columns;
        this.rows = rows;
        this.input = input;

        this.normalized = new float[rows][columns];
        this.distanceMatrix = new float[rows][rows];
        this.clustered = new float[rows][columns];
        this.columnMeans = new float[columns];
        this.columnStds = new float[columns];
    }

// it's [column][row] not [row][column] dumb me
// outputs mean of column, row stays the same

    float[] calculateColumnMeans(){
        for (int i = 0; i < input[0].length; i++){
            float sum = 0;
            for(int j = 0; j < input.length; j++){
                sum = sum + input[j][i];
            }
            columnMeans[i] = sum / input.length;
        }
        return columnMeans;
    }

    float[] calculateColumnStds(){
        calculateColumnMeans();
        for (int i = 0; i< input[0].length; i++){
            float sum = 0;
            for (int j = 0; j < input.length; j++){
                sum = sum + sq(input[j][i] - columnMeans[i]);
            }
            columnStds[i] = sqrt(sum / input.length);
        }
        return columnStds;
    }

    float[][] distanceMatrix(float[][] inputMatrix){
        for(int i = 0; i < inputMatrix.length; i++){ // for each row
            for(int j = 0; j < inputMatrix.length; j++){
                float tempValue = 0;
                for (int k = 0; k < inputMatrix[0].length; k++){
                    tempValue = tempValue + abs(inputMatrix[i][k] - inputMatrix[j][k]);
                }
                distanceMatrix[i][j] = tempValue;
            }
        }
        return distanceMatrix;
    }

    float[][] cluster(){



        return clustered;
    }

    float[][] normalize(){
        calculateColumnStds();
        for (int i = 0; i < input[0].length; i++){
            for (int j = 0; j < input.length; j++){
                normalized[j][i] = (input[j][i] - columnMeans[i]) / columnStds[i];
            }
        }
        return normalized;
    }

}
