# A processing program that generates a heatmap from a csv file. 
## Capabilities
- Loading external .csv file format (heart.csv)
- Automatically remove rows with missing values
- z-normalization performed on input data per column (excludes rows marked as categorical in calcs.pde)
- Perform single-linkage clustering on rows based on Gower's distance
- No external dependancies

## Data source
Data was sourced from the UC Irvine Machine Learning Repository: https://archive.ics.uci.edu/dataset/45/heart+disease, heart.csv comes from processed.cleveland.data in the zip download. Categorical marking has been taken from this webpage. 

## AI use
The use of AI tools such as Codex was limited in scope, usage is disclosed partially in code comments and partially in a separate file. 