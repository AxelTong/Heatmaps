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

    float[] calculateColumnMeans(){
        for(int i = 0; i < input.length; i++){
            float tempValue = 0;
            for(int j = 0; j < input[i].length; j++){
                tempValue += input[i][j]; 
            }
            columnMeans[i] = tempValue / input[i].length;
        }
        return columnMeans;
    }

    float[] calculateColumnStds(){
        calculateColumnMeans();
        for(int i = 0; i < input.length; i++){
            float sum = 0;
            for(int j = 0; j < input[i].length; j++){
                sum += sq(input[i][j] - columnMeans[i]);
            }
            columnStds[i] = sqrt(sum / input[i].length);
        }
        return columnStds;
    }

    float[][] normalize(){
        calculateColumnStds();
         for(int i = 0; i < input.length; i++){
            for(int j = 0; j < input[i].length; j++){
                normalized[i][j] = (input[i][j] - columnMeans[i]) / columnStds[i];
            }
        }
        return normalized;
    }

}
