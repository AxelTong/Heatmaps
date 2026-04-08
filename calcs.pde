//check todo at bottom
class calc {
    int columns;
    int rows;
    float[][] input;
    float[][] normalized;
    float[][] clustered;
    float[] columnMeans;
    float[] columnStds;

    calc(int columns, int rows, float[][] input) {
        this.columns = columns;
        this.rows = rows;
        this.input = input;

        this.normalized = new float[rows][columns];
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
