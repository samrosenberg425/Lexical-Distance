# Orthogonalize-Words
Create distance matrices for a set of words intended for neuroimaging studies on reading. This code utilizes MATLAB GUIs for ease of use/reproducibility. 
*By Sam Roseberg | University of Mayryland, College Park/Rutgers University, Newark

## Files
#### main_gui.m
This file has the code for the initial GUI - provides options to set up matrices or run analyses on existing matrices. 
#### setup_gui.m
Code for the setup matrixes GUI. Offers input for list of words then creates an output folder with eDM.mat(experience distance mateices), fDM.mat(feature distance matrices), cDM.mat(control distance matrices), and feDM.mat(feature*experience distance matrix elementwise product, proxy of neural tuning)
#### make_fDM_cDM.m
Makes feature and control distance matrices. 
#### make_eDM.mat
Makes experience distance matrices. 
#### make_DM.m
Makes feature*experience distanfe matrices(feDM), adds word frequency to eDM, saves additional file(allDM.mat) with all distance matrices. 
#### make_analysisfiles.m
Takes selected matrices and partials out selected matrices, then measures the residuals with a Spearman corrlation(can be changed to Kendall's), and outputs a struct with the matrix reaiduals and an excel sheet that summarizes the corrlelation of the residuals. 
#### analysis_gui.m
Code for selecting matrices to save reaiduals of and to partial out. 

## Installation
Download entire repository and add it your matlab path(using add folder with subfolders). 

## Usage Notes
Once added to your path, call from the matlab command line
''' tcsh
main_gui()
'''