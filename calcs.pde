//check todo at bottom
class calc {
    int columns;
    int rows;
    float[][] input;
    float[][] normalized;
    float[][] distanceMatrix;
    float[][] clustered;
    float[] columnMeans;
    float[] columnStds;
    float[] maxOfColumn;
    float[] minOfColumn;
    float[] maxOfNormColumn;
    float[] minOfNormColumn;
    boolean[] categorical;
    String[] headers;

    calc(int columns, int rows, float[][] input, String[] headers) {
        this.columns = columns;
        this.rows = rows;
        this.input = input;
        this.headers = headers;

        this.normalized = new float[rows][columns];
        this.distanceMatrix = new float[rows][rows];
        this.clustered = new float[rows][columns];
        this.columnMeans = new float[columns];
        this.columnStds = new float[columns];
        this.maxOfColumn = new float[columns];
        this.minOfColumn = new float[columns];
        this.maxOfNormColumn = new float[columns];
        this.minOfNormColumn = new float[columns];
        this.categorical = new boolean[columns];

    }

                    // it's [column][row] not [row][column] dumb me
                    // outputs mean of column, row stays the same

    float[] calculateColumnMeans(){ // mathematical average
        for (int i = 0; i < input[0].length; i++){
            float sum = 0;
            for(int j = 0; j < input.length; j++){
                sum = sum + input[j][i];
            }
            columnMeans[i] = sum / input.length;
        }
        return columnMeans;
    }

    float[] getNormColumnMax(){ // gets maximum of each column of normalized data
        normalize();
        for (int i = 0; i < normalized[0].length; i++){
            float max = normalized[0][i];
            for(int j = 0; j < normalized.length; j++){
                if (normalized[j][i] > max){
                    max = normalized[j][i];
                }
            }
            maxOfNormColumn[i] = max;
        }
        return maxOfNormColumn;
    }

    float[] getNormColumnMin(){ // gets minimum of each column of normalized data
        normalize();
        for (int i = 0; i < normalized[0].length; i++){
            float min = normalized[0][i];
            for(int j = 0; j < normalized.length; j++){
                if (normalized[j][i] < min){
                    min = normalized[j][i];
                }
            }
            minOfNormColumn[i] = min;
        }
        return minOfNormColumn;
    }

    float[] getColumnMax(){ // gets maximum of each column of input data
        for (int i = 0; i < input[0].length; i++){
            float max = input[0][i];   
            for(int j = 0; j < input.length; j++){
                if (input[j][i] > max){
                    max = input[j][i];
                }
            }
            maxOfColumn[i] = max;
        }
        return maxOfColumn;
    }

    float[] getColumnMin(){ // gets minimum of each column of input data
        for (int i = 0; i < input[0].length; i++){
            float min = input[0][i];
            for(int j = 0; j < input.length; j++){
                if (input[j][i] < min){
                    min = input[j][i];
                }
            }
            minOfColumn[i] = min;
        }
        return minOfColumn;
    }

    boolean[] matchCategoricals(){
        for (int i = 0; i < columns; i++){
            if (headers[i].equals("sex") || headers[i].equals("fbs") || headers[i].equals("exang") || headers[i].equals("target") || headers[i].equals("cp") || headers[i].equals("restecg") || headers[i].equals("exang") || headers[i].equals("slope") || headers[i].equals("thal")){ // if the column is a categorical variable
                categorical[i] = true;
            } else {
                categorical[i] = false;
            }
        }
        return categorical;
    }

    float[] calculateColumnStds(){ // standard deviation
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

    float[][] calculateDistanceMatrix(float[][] normalized){ // calculates distance matrix following gower's for each person
        getNormColumnMax();
        getNormColumnMin();
        for(int i = 0; i < normalized.length; i++){ // for each row of the distance matrix
            for(int j = 0; j < normalized.length; j++){ // for each column of the distance matrix
                float sum = 0;
                for (int k = 0; k < normalized[0].length; k++){ // for each column of the normalized matrix
                    sum = sum + (abs(normalized[i][k] - normalized[j][k])/(maxOfNormColumn[k]-minOfNormColumn[k])); // Gower's distance: similarity is 1 - (absolute value of the difference between the two values / the maximum of the two values), we want distance -> don't subtract from 1. 
                }
                distanceMatrix[i][j] = sum;
            }
        }
        return distanceMatrix;
    }

    //float[] smallestDistance(){} //TODO
    

    float[][] cluster(){ //TODO



        return clustered;
    }

    float[][] normalize(){
        calculateColumnStds();
        for (int i = 0; i < input[0].length; i++){
            if (matchCategoricals()[i]) {
                // Handle categorical variables differently
                for (int j = 0; j < input.length; j++){
                normalized[j][i] = input[j][i];
                }
            }
            else {
                // Handle numerical variables with z-normalization
                for (int j = 0; j < input.length; j++){
                    normalized[j][i] = (input[j][i] - columnMeans[i]) / columnStds[i]; // z normalization
                }
           }
        }
        return normalized;
    }

}
