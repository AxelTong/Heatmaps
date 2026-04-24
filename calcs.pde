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

    calc(int columns, int rows, float[][] input) {
        this.columns = columns;
        this.rows = rows;
        this.input = input;

        this.normalized = new float[rows][columns];
        this.distanceMatrix = new float[rows][rows];
        this.clustered = new float[rows][columns];
        this.columnMeans = new float[columns];
        this.columnStds = new float[columns];
        this.maxOfColumn = new float[columns];
        this.minOfColumn = new float[columns];
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

    float[] getColumnMax(){ // gets maximum of each column of normalized data
        normalize();
        for (int i = 0; i < normalized[0].length; i++){
            float max = normalized[0][i];
            for(int j = 0; j < normalized.length; j++){
                if (normalized[j][i] > max){
                    max = normalized[j][i];
                }
            }
            maxOfColumn[i] = max;
        }
        return maxOfColumn;
    }

    float[] getColumnMin(){ // gets minimum of each column of normalized data
        normalize();
        for (int i = 0; i < normalized[0].length; i++){
            float min = normalized[0][i];
            for(int j = 0; j < normalized.length; j++){
                if (normalized[j][i] < min){
                    min = normalized[j][i];
                }
            }
            minOfColumn[i] = min;
        }
        return minOfColumn;
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
        getColumnMax();
        getColumnMin();
        for(int i = 0; i < normalized.length; i++){ // for each row of the distance matrix
            for(int j = 0; j < normalized.length; j++){ // for each column of the distance matrix
                float sum = 0;
                for (int k = 0; k < normalized[0].length; k++){ // for each column of the normalized matrix
                    sum = sum + (abs(normalized[i][k] - normalized[j][k])/(maxOfColumn[k]-minOfColumn[k])); // Gower's distance: similarity is 1 - (absolute value of the difference between the two values / the maximum of the two values), we want distance -> don't subtract from 1. 
                }
                distanceMatrix[i][j] = sum;
            }
        }
        return distanceMatrix;
    }

    float[][] cluster(){ //TODO



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
