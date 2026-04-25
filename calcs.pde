//check todo at bottom
class calc {
    int columns;
    int rows;
    int nextClusterId;
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
    float[][] linkageMatrix;

    calc(int columns, int rows, float[][] input, String[] headers) {
        this.columns = columns;
        this.rows = rows;
        this.input = input;
        this.headers = headers;
        this.nextClusterId = rows;

        this.normalized = new float[rows][columns];
        //this.distanceMatrix = new float[rows][rows];
        this.clustered = new float[rows][columns];
        this.columnMeans = new float[columns];
        this.columnStds = new float[columns];
        this.maxOfColumn = new float[columns];
        this.minOfColumn = new float[columns];
        this.maxOfNormColumn = new float[columns];
        this.minOfNormColumn = new float[columns];
        this.categorical = new boolean[columns];
        this.linkageMatrix = new float[rows-1][4]; // in each step we merge 2 clusters, so we have rows-1 steps, and we need to store which clusters we merged and the distance between them, so 3 columns

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
        distanceMatrix = new float[normalized.length][normalized.length];
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
    

    
    float[][] getLinkageMatrix(){ // calculating linkage matrix for single linkage clustering
        calculateDistanceMatrix(normalized);
        int maxClusters = 2 * rows - 1; // in the worst case we merge 2 clusters in each step, so we have at most 2*rows-1 clusters, thanks Codex
        int[] sizes = new int[maxClusters]; // keeps track of the size of each cluster, initially all clusters are of size 1
        for (int i = 0; i < rows; i++){
            sizes[i] = 1; // initially all clusters are of size 1, we have as many clusters as rows
        }  
        int[] active = new int[maxClusters]; // keeps track of which clusters are still active, initially all clusters are active
        for (int i = 0; i < rows; i++){
            active[i] = 1;
        } 
        nextClusterId = rows; // keeps track of the number of values, initially we have as many clusters as rows

        for (int i = 0; i < normalized.length - 1; i++){
            float smallestDist = Float.MAX_VALUE; //Neat trick I learned from Hanin, float.MAX_VALUE is the largest possible float value, so any distance we calculate will be smaller than this, so we can use this as our initial value for smallestDist
            int closestRow = -1; // initialize with -1 so it's obvious if something weird happens, thanks again Hanin!
            int closestCol = -1;
            for (int j = 0; j < distanceMatrix.length; j++){
                for (int k = 0; k < distanceMatrix[0].length; k++){
                    if (j != k && active[j] == 1 && active[k] == 1){ // we only consider distances between active clusters, and we don't consider the distance of a cluster to itself
                        if (distanceMatrix[j][k] < smallestDist){
                            smallestDist = distanceMatrix[j][k]; //update smallestDist and closestRow and closestCol if we found a smaller distance
                            closestRow = j;
                            closestCol = k;
                        }
                    }
                }
            }
            if (closestRow == -1 || closestCol == -1){ // sanity check, remove this later!
                println("wtf");
            }
            linkageMatrix[i][0] = closestRow;
            linkageMatrix[i][1] = closestCol;
            linkageMatrix[i][2] = smallestDist;
            linkageMatrix[i][3] = sizes[closestRow] + sizes[closestCol]; // we merged 2 clusters, so the size of the new cluster is 2
            sizes[nextClusterId] = sizes[closestRow] + sizes[closestCol]; // we merged 2 clusters, so we add the size of the new cluster to the sizes array
            distanceMatrix = updateDistanceMatrix(distanceMatrix, closestRow, closestCol);
            active[closestRow] = 0; // we merged the cluster at closestRow, so it's no longer active
            active[closestCol] = 0; // we merged the cluster at closestCol, so it's no longer active
            active[nextClusterId] = 1; // we merged 2 clusters, so we add the new cluster to the active array
            nextClusterId += 1;
        }



        return linkageMatrix;
    } 

    float [][] updateDistanceMatrix (float[][] distanceMatrix, int cluster1, int cluster2){
        float [][] newDistanceMatrix = new float[distanceMatrix.length + 1][distanceMatrix[0].length + 1];
        int oldSize = distanceMatrix.length;
        int newClusterIndex = oldSize; //codex did a weird thing here... I try using it once and it pulls this crap
        for (int i = 0; i <= oldSize; i++){
            for (int j = 0; j <= oldSize; j++){
                if (i < oldSize && j < oldSize) {
                    newDistanceMatrix[i][j] = distanceMatrix[i][j];
                } else if (i == newClusterIndex && j < oldSize) {
                    newDistanceMatrix[i][j] = min(distanceMatrix[cluster1][j], distanceMatrix[cluster2][j]);
                } else if (j == newClusterIndex && i < oldSize) {
                    newDistanceMatrix[i][j] = min(distanceMatrix[i][cluster1], distanceMatrix[i][cluster2]);
                } else {
                    newDistanceMatrix[i][j] = 0;
                }
            }// thanks codex

        }
        return newDistanceMatrix;
    }

    int[] cluster() {

        int[] clusters = new int[rows];

        // iedereen start in eigen cluster
        for (int i = 0; i < rows; i++) {
            clusters[i] = i;
        }

        // zoek dichtste buur
        for (int i = 0; i < rows; i++) {

            float minDist = Float.MAX_VALUE;
            int closest = -1;

            for (int j = 0; j < rows; j++) {

                if (i != j && distanceMatrix[i][j] < minDist) {
                    minDist = distanceMatrix[i][j];
                    closest = j;
                }
            }

            // zelfde cluster
            if (closest != -1) {
                clusters[i] = clusters[closest];
            }
        }

        return clusters;
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
                    if(columnStds[i] == 0){ // if the standard deviation is 0, we can't do z-normalization, so we just set the normalized value to 0 (or any constant value, since all values are the same). thanks Codex for the spot
                        normalized[j][i] = 0;
                    } else {
                    normalized[j][i] = (input[j][i] - columnMeans[i]) / columnStds[i]; // z normalization
                    }
                }
           }
        }
        return normalized;
    }

}
