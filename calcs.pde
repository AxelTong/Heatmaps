//check todo at bottom
class calc {
    int columns;
    int rows;
    int nextClusterId;
    float[][] input;
    float[][] normalized;
    float[][] distanceMatrix;
    float[][] clusteredRaw;
    float[][] clusteredNorm;
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
        this.clusteredRaw = new float[rows][columns];
        this.clusteredNorm = new float[rows][columns];
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

/**
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
*/
    boolean[] matchCategoricals(){ // checks if it's a categorical variable based on headers, TODO: get this from an array instead of hardcoding this mess
        for (int i = 0; i < columns; i++){
            if (headers[i].equals("sex") || headers[i].equals("fbs") || headers[i].equals("exang") || headers[i].equals("target") || headers[i].equals("cp") || headers[i].equals("restecg") || headers[i].equals("exang") || headers[i].equals("slope") || headers[i].equals("thal")){ // if the column is a categorical variable
                categorical[i] = true;
            } else {
                categorical[i] = false;
            }
        }
        return categorical;
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

    float[][] calculateDistanceMatrix(float[][] normalized){ // calculates distance matrix following gower's for each person
        getNormColumnMax();
        getNormColumnMin();
        distanceMatrix = new float[normalized.length][normalized.length];
        for(int i = 0; i < normalized.length; i++){ // for each row of the distance matrix
            for(int j = 0; j < normalized.length; j++){ // for each column of the distance matrix
                float sum = 0;
                for (int k = 0; k < normalized[0].length; k++){ // for each column of the normalized matrix
                    if (categorical[k] == true) { // if it's a categorical variable, distance is 0 if they are the same and 1 if they are different. This differs from wikipedia due to it being DISTANCE and not SIMILARITY
                        if (normalized[i][k] == normalized[j][k]){
                            sum = sum + 0;
                        } else {
                            sum = sum + 1;
                        }
                    } else {
                    sum = sum + (abs(normalized[i][k] - normalized[j][k])/(maxOfNormColumn[k]-minOfNormColumn[k])); // Gower's distance: similarity is 1 - (absolute value of the difference between the two values / the maximum of the two values), we want distance -> don't subtract from 1. 
                     }
                    }
                distanceMatrix[i][j] = sum;
            }
        }
        return distanceMatrix;
    }
    
    float[][] getLinkageMatrix(){ // calculating linkage matrix for single linkage clustering
        calculateDistanceMatrix(normalized);
        int maxClusters = 2 * rows - 1; // in the worst case we merge 2 clusters in each step
        int[] sizes = new int[maxClusters]; // keeps track of the size of each cluster, initially all clusters are of size 1
        for (int i = 0; i < rows; i++){
            sizes[i] = 1; // initially all clusters are of size 1, we have as many clusters as rows
        }  
        int[] active = new int[maxClusters]; // keeps track of which clusters are still active, initially all clusters are active
        for (int i = 0; i < rows; i++){
            active[i] = 1;
        } 
        nextClusterId = rows; // keeps track of the next cluster id after the original rows

        for (int i = 0; i < normalized.length - 1; i++){
            float smallestDist = Float.MAX_VALUE; // initial large value
            int closestRow = -1;
            int closestCol = -1;
            for (int j = 0; j < distanceMatrix.length; j++){
                for (int k = 0; k < distanceMatrix[0].length; k++){
                    if (j != k && active[j] == 1 && active[k] == 1){ // only consider distances between active clusters
                        if (distanceMatrix[j][k] < smallestDist){
                            smallestDist = distanceMatrix[j][k];
                            closestRow = j;
                            closestCol = k;
                        }
                    }
                }
            }
            if (closestRow == -1 || closestCol == -1){
                println("wtf");
            }
            linkageMatrix[i][0] = closestRow;
            linkageMatrix[i][1] = closestCol;
            linkageMatrix[i][2] = smallestDist;
            linkageMatrix[i][3] = sizes[closestRow] + sizes[closestCol];
            sizes[nextClusterId] = sizes[closestRow] + sizes[closestCol];
            distanceMatrix = updateDistanceMatrix(distanceMatrix, closestRow, closestCol);
            active[closestRow] = 0;
            active[closestCol] = 0;
            active[nextClusterId] = 1;
            nextClusterId += 1;
        }
        return linkageMatrix;
    } 
       

    int[] getSortedPatientOrderFromLinkage() {
        getLinkageMatrix();

        ArrayList<ArrayList<Integer>> clusters = new ArrayList<ArrayList<Integer>>();

        // elke originele patiënt is eerst zijn eigen cluster
        for (int i = 0; i < rows; i++) {
            ArrayList<Integer> single = new ArrayList<Integer>();
            single.add(i);
            clusters.add(single);
        }

        // linkageMatrix aflopen
        for (int step = 0; step < rows - 1; step++) {
            int a = int(linkageMatrix[step][0]);
            int b = int(linkageMatrix[step][1]);

            ArrayList<Integer> merged = new ArrayList<Integer>();

            merged.addAll(clusters.get(a));
            merged.addAll(clusters.get(b));

            clusters.add(merged);
        }

        // laatste cluster bevat alle patiënten in gesorteerde volgorde
        ArrayList<Integer> finalCluster = clusters.get(clusters.size() - 1);

        int[] order = new int[rows];

        for (int i = 0; i < rows; i++) {
            order[i] = finalCluster.get(i);
        }

        return order;
    }

    float [][] updateDistanceMatrix (float[][] distanceMatrix, int cluster1, int cluster2){ // helper for getLinkagematrix, updating distance matrix. 
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

    float[][] getClusteredRaw(){
        int order[] = new int[rows];
        order = getSortedPatientOrderFromLinkage();
            for (int i = 0; i < input.length; i++){
                for (int j = 0; j < input[0].length; j++){
                    int requestedRow = order[i];
                    clusteredRaw[i][j] = input[requestedRow][j];
                }
            }
        return clusteredRaw;
    }

    float[][] getClusteredNorm(){
        int order[] = new int[rows];
        order = getSortedPatientOrderFromLinkage();
            for (int i = 0; i < input.length; i++){
                for (int j = 0; j < input[0].length; j++){
                    int requestedRow = order[i];
                    clusteredNorm[i][j] = normalized[requestedRow][j];
                }
            }
        return clusteredNorm;
    }


}
