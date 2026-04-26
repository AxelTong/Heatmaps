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

        int[] sizes = new int[rows]; // keeps track of the size of each cluster, initially all clusters are of size 1
        int[] active = new int[rows]; // keeps track of which clusters are still active, initially all clusters are active
        
        for (int i = 0; i < rows; i++){
            sizes[i] = 1; // initially all clusters are of size 1, we have as many clusters as rows
            active[i] = 1; // initially all clusters are active
        }

        for (int step = 0; step < rows - 1; step++){
            float smallestDist = Float.MAX_VALUE; // initial large value
            int c1 = -1;
            int c2 = -1;
            //find closest active pair of clusters
            for (int i=0; i<rows; i++){
               if (active[i] == 0) continue; // skip inactive clusters
               
                for (int j=0; j<rows; j++){
                    if (active[j]==0) continue; // skip inactive clusters
                    if (i!=j && distanceMatrix[i][j] <smallestDist) {
                        smallestDist = distanceMatrix[i][j];
                        c1 = i;
                        c2 = j;
                    }
                }
            }
            //safety check
            if (c1 == -1 || c2 == -1){
                println("Error: no active clusters found");
                break;
            }
            //merge clusters c1 and c2
            linkageMatrix[step][0] = c1;
            linkageMatrix[step][1] = c2;
            linkageMatrix[step][2] = smallestDist;
            linkageMatrix[step][3] = sizes[c1] + sizes[c2];
            //update cluster sizes
            sizes[c1] += sizes[c2];
            //update distance matrix (c1 becomes merged entity, c2 becomes inactive)
            updateDistanceMatrix(distanceMatrix,c1,c2);
            //mark c2 as inactive
            active[c2] = 0;
        }
        return linkageMatrix;
    }
       

    int[] getSortedPatientOrderFromLinkage() {
        getLinkageMatrix();
        //start with each patient in their own cluster 
        ArrayList<ArrayList<Integer>> clusters = new ArrayList<ArrayList<Integer>>();
        for (int i = 0; i < rows; i++) {
            ArrayList<Integer> single = new ArrayList<Integer>();
            single.add(i);
            clusters.add(single);
        }
        // apply the merges from linkage matrix in order, merging the clusters as we go
        for (int step = 0; step < rows - 1; step++) {
            int c1 = int(linkageMatrix[step][0]);
            int c2 = int(linkageMatrix[step][1]);
            //c1 absorbs c2 (we could do the opposite, it doesn't matter for single linkage, but we have to be consistent with how we update the distance matrix in getLinkageMatrix)
            clusters.get(c1).addAll(clusters.get(c2));
            //c1 becomes inactive, we can just ignore it in the future since we won't be merging it anymore, and we will take the final cluster order from the last cluster in the list after all merges are done.
            clusters.get(c2).clear(); 
        }
        //find the cluster that contains all patients (the last cluster in the list that is not empty) and return the order of patients in that cluster as an array
        ArrayList<Integer> finalCluster = null;
        for (ArrayList<Integer> cl:clusters) {
            if (cl.size()==rows){
                finalCluster = cl;
                break;
            }
        }
        //convert final cluster order from arraylist to array
        int[] order = new int[rows];
        for (int i = 0; i < rows; i++) {
            order[i] = finalCluster.get(i);
        }
        return order;
    }   

    float [][] updateDistanceMatrix (float[][] distanceMatrix, int cluster1, int cluster2){ // helper for getLinkagematrix, updating distance matrix. 
        int n = distanceMatrix.length;
        //single linkage: distance from new cluster to other cluster is the minimum of the distances from the merged clusters to that other cluster.
        for(int i=0; i< n ; i++){
            if(i == cluster1 || i == cluster2) continue; // skip the merged clusters themselves
            float d = min(distanceMatrix[cluster1][i], distanceMatrix[cluster2][i]);
                distanceMatrix[cluster1][i] = d; 
                distanceMatrix[i][cluster1] = d; //symmetry
            }

            //"remove" cluster2 by setting its distances very large
            for (int i = 0; i < n; i++) {
                distanceMatrix[cluster2][i] = Float.MAX_VALUE;
                distanceMatrix[i][cluster2] = Float.MAX_VALUE;
            }  

            return distanceMatrix;
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
