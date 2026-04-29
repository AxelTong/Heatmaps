//============================================
// Class: calc
// Description of this class: this class performs normalization, Gower distance, hierarchical clustering, linkage matrix, and patient order for heatmap visualization. It takes in the raw data and headers as input and outputs the clustered raw and normalized data, as well as the distance matrix and linkage matrix for clustering.
//============================================
class calc {
    // --------------------------------
    // FIELDS
    //--------------------------------
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
    String[] categoricals = {"sex", "fbs", "exang", "cp", "restecg", "slope", "thal", "target"}; // hardcoded list of categorical variables, we can get this from the headers in the future if we want to make this more generalizable, but for now this is fine for our dataset.

    float[][] linkageMatrix;

    //================================
    // CONSTRUCTOR
    //================================
    calc(int columns, int rows, float[][] input, String[] headers) {
        this.columns = columns;
        this.rows = rows;
        this.input = input;
        this.headers = headers;

        this.nextClusterId = rows;

        this.normalized = new float[rows][columns];
        this.clusteredRaw = new float[rows][columns];
        this.clusteredNorm = new float[rows][columns];

        this.columnMeans = new float[columns];
        this.columnStds = new float[columns];

        this.maxOfColumn = new float[columns];
        this.minOfColumn = new float[columns];
        this.maxOfNormColumn = new float[columns];
        this.minOfNormColumn = new float[columns];

        this.categorical = new boolean[columns];
        
        this.linkageMatrix = new float[rows-1][5]; // in each step we merge 2 clusters, so we have rows-1 steps, and we need to store which clusters we merged and the distance between them, so 3 columns

    }

                    // it's [column][row] not [row][column] dumb me
                    // outputs mean of column, row stays the same
    //======================================================
    // COLUMN CALCULATIONS: MEAN, STD, MAX, MIN, NORMALIZATION
    //======================================================

    //Compute mean of each colomn 
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
    // Compute standard deviation of each column
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
    //====================================================
    // CATEGORICAL CHECK, NORMALIZATION, MAX, MIN

    boolean[] matchCategoricals(){ // checks if it's a categorical variable based on headers, TODO: get this from an array instead of hardcoding this mess
        for (int i = 0; i < columns; i++){
            for (int j = 0; j < categoricals.length; j++){
                 if (headers[i].equals(categoricals[j])){ // if the column is a categorical variable
                    categorical[i] = true;
                    break; // if we found a match, we can stop checking the rest of the categoricals for this column
                } else {
                 categorical[i] = false;
                }
            }
           
        }
        return categorical;
    }
    //====================================================
    // NORMALIZATION: for numerical variables we do z-normalization, for categorical variables we keep them the same (since Gower's distance can handle categorical variables without needing to convert them to dummy variables or anything)
    //====================================================
    float[][] normalize(){
        calculateColumnStds();
        for (int i = 0; i < input[0].length; i++){
            if (matchCategoricals()[i]) {
                // Categorical so we can copy raw values 
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
    //====================================================
    // MAX AND MIN OF NORMALIZED COLUMNS: needed for Gower's distance, we need to know the range of the normalized values for each column to calculate the distance correctly. 
    //====================================================
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
                if (normalized[j][i] < min) min = normalized[j][i];
            }
            minOfNormColumn[i] = min;
        }
        return minOfNormColumn;
    }
    //====================================================
    // GOWER'S DISTANCE AND DISTANCE MATRIX: for each pair of patients, we calculate the Gower distance based on their normalized values and whether the variable is categorical or numerical. For numerical variables, the distance is the absolute difference divided by the range (max - min) of that variable. For categorical variables, the distance is 0 if they are the same and 1 if they are different. We then sum the distances for all variables to get the total distance between the two patients. We do this for all pairs of patients to get the distance matrix.
    //====================================================
    float[][] calculateDistanceMatrix(float[][] normalized){ // calculates distance matrix following gower's for each person
        getNormColumnMax();
        getNormColumnMin();
        distanceMatrix = new float[normalized.length][normalized.length];
        for(int i = 0; i < normalized.length; i++){ // for each row of the distance matrix
            for(int j = 0; j < normalized.length; j++){ // for each column of the distance matrix
                float sum = 0;
                for (int k = 0; k < normalized[0].length; k++){ // for each column of the normalized matrix
                if (categorical[k]) {
                        // Categorical distance: 0 if same, 1 if different
                        sum += (normalized[i][k] == normalized[j][k]) ? 0 : 1;
                    } else {
                        // Numerical Gower distance
                        sum += abs(normalized[i][k] - normalized[j][k]) /
                               (maxOfNormColumn[k] - minOfNormColumn[k]);
                    }
                }
                distanceMatrix[i][j] = sum;
            }
        }
        return distanceMatrix;
    }
    //====================================================
    // HIERARCHICAL CLUSTERING: we use single linkage clustering, which means that the distance between two clusters is the minimum distance between any two patients in the two clusters. We start
    // with each patient as their own cluster, and then we merge the two closest clusters until we have only one cluster left. We keep track of the clusters we merge and the distance between them in the linkage matrix, which we can then use to get the order of the patients for the heatmap visualization.
    //====================================================
    float[][] getLinkageMatrix(){ // calculating linkage matrix for single linkage clustering
        calculateDistanceMatrix(normalized);
        int maxClusters = 2 * rows - 1; // in the worst case we merge 2 clusters in each step
        int[] sizes = new int[maxClusters]; // keeps track of the size of each cluster
        int[] active = new int[maxClusters]; // keeps track of which clusters are still active
        for (int i = 0; i < rows; i++){
            active[i] = 1; // initialize all existing clusters as active
            sizes[i] = 1; // initially all clusters are of size 1, we have as many clusters as rows
        } 
        nextClusterId = rows; // keeps track of the next cluster id after the original rows

        for (int i = 0; i < normalized.length - 1; i++){
            float smallestDist = Float.MAX_VALUE; // initial large value, thanks hanin for the tip!
            int closestRow = -1;
            int closestCol = -1;
            for (int j = 0; j < distanceMatrix.length; j++){
                for (int k = 0; k < distanceMatrix[0].length; k++){
                    if (j != k && active[j] == 1 && active[k] == 1){ // only consider distances between active clusters, and ignore diagonal (distance between cluster and itself)
                        if (distanceMatrix[j][k] < smallestDist){
                            smallestDist = distanceMatrix[j][k];
                            closestRow = j;
                            closestCol = k;
                        }
                    }
                }
            }
            
            linkageMatrix[i][0] = closestRow; // set first link as row of distance matrix = cluster ID of one
            linkageMatrix[i][1] = closestCol; // set second link as column of distance matrix = cluster ID of the other
            linkageMatrix[i][2] = smallestDist; // distance = distance...

            int newSize = sizes[closestRow] + sizes[closestCol]; //size of new cluster is the sum of the sizes of the merged clusters
            linkageMatrix[i][3] = newSize; // set size in linkage matrix
            linkageMatrix[i][4] = nextClusterId; // new cluster ID is the next available ID after the original rows and previously merged clusters

            sizes[nextClusterId] = newSize; // set size of new cluster in sizes array
            //Update distance matrix and active clusters after merging
            distanceMatrix = updateDistanceMatrix(distanceMatrix, closestRow, closestCol); // update distance matrix after merging clusters
            //Update active clusters
            active[closestRow] = 0; // set merged clusters as inactive
            active[closestCol] = 0; // set merged clusters as inactive
            active[nextClusterId] = 1; // set new cluster as active

            nextClusterId++; // the new cluster ID for the next merge, we increment it after each merge so that we have unique IDs for each cluster.
        }
        return linkageMatrix;
    } 
   //====================================================
   // UPDATE DISTANCE MATRIX: after merging two clusters, we need to update the distance matrix    
   //=====================================================
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
    //====================================================
    // GET SORTED PATIENT ORDER FROM LINKAGE: after we have the linkage matrix,
    //=====================================================
int[] getSortedPatientOrderFromLinkage() {

        getLinkageMatrix();
        HashMap<Integer, ArrayList<Integer>> clusterMap = new HashMap<Integer, ArrayList<Integer>>();
        // we will keep track of the clusters in a list, where each cluster is a list of patient indices. We start with each patient as their own cluster, and then we merge clusters according to the linkage matrix.
        for (int i = 0; i < rows; i++) {
            ArrayList<Integer> single = new ArrayList<Integer>();
            single.add(i);
            clusterMap.put(i, single);
        }
        int currentClusterId = rows;

        // Process merges in the linkage matrix
        for (int step = 0; step < rows - 1; step++) {

            int a = int(linkageMatrix[step][0]);
            int b = int(linkageMatrix[step][1]);

            ArrayList<Integer> merged = new ArrayList<Integer>();

            merged.addAll(clusterMap.get(a));
            merged.addAll(clusterMap.get(b));

            clusterMap.put(currentClusterId, merged);
            clusterMap.put(currentClusterId, merged);
            currentClusterId++;
        }

        // final cluster bevat alle patiënten in gesorteerde volgorde

       int finalClusterId = currentClusterId - 1;
        ArrayList<Integer> finalCluster = clusterMap.get(finalClusterId);

        int[] order = new int[rows];
        for (int i = 0; i < rows; i++) {
            order[i] = finalCluster.get(i);
        }

        return order;
    }
    //====================================================
    // GET CLUSTERED RAW AND NORM DATA: using the order of patients from the
    //=====================================================
    float[][] getClusteredRaw(){
        int[] order = getSortedPatientOrderFromLinkage();
            for (int i = 0; i < input.length; i++){
                for (int j = 0; j < input[0].length; j++){
                    clusteredRaw[i][j] = input[order[i]][j];
                }
            }
        return clusteredRaw;
    }

    float[][] getClusteredNorm(){
        int[] order = getSortedPatientOrderFromLinkage();
            for (int i = 0; i < input.length; i++){
                for (int j = 0; j < input[0].length; j++){
                    clusteredNorm[i][j] = normalized[order[i]][j];
                }
            }
        return clusteredNorm;
    }


}
