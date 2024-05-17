# Lexical-Distance
Create distance matrices for a list of words using phono-orthotactics of sublexical features and semantics.

This code is intended for RSA neuroimaging studies on reading. This code utilizes MATLAB GUIs for ease of use/reproducibility. 

*By Sam Rosenberg, (University of Mayryland, College Park/Rutgers University, Newark), Dr. Jeremy Purcell(University of Maryland, College Park), and Audrey Liu(University of Maryland, College Park)*

This code uses data generated by using the Sublexical Toolkit designed by Dr. Bob Wiley and Dr. Jeremy Purcell. The data was extracted from this repository: <put pg toolkit repository> and the code used to extract the data is available upon request. 

# Files
## LexicalDistanceAnalysis.m
- This file has the code for the initial GUI - it provides options to set up matrices or run analyses on existing matrices
- Calls upon all other functions to perform the calculations for the matrices
- This is the function to be called when using any tools in the code and can be used with the command:  
 >LexicalDistanceAnalysis
## Setup Files
Create distance matrices of individual sublexical/lexical feature of the word. 
### setup_gui.m
- Code for the setup matrixes GUI
- Has user input for a list of words through a .csv file or manual entry
- Has user input for the name of the analysis/output folder
- Loads ortho-phonotactic and semantic data used to create the matrices
- Calls on other functions to perform calculations to create distance matrices for the output

*Called upon by: LexicalDistanceAnalysis.m*

- ***Input:***
    - *wordlist:*  .csv/manually entered list of words ***(User input)***
    - *analysis_name:* output folder/analysis name ***(User input)***
- ***Output:***
    - Folder named *analysis_name* containing:
        - *eDM.mat* (struct of experience distance matrices)
        - *fDM.mat* (struct of feature distance matrices)
        - *cDM.mat* (struct of control distance matrices)
        - *feDM.mat* (struct of feature-experience distance matrix)
        - *allDM.mat* (struct of all aforementioned distance matrices)

### make_fDM_cDM.m
- Creates feature and control distance matrices  

*Called upon by: setgupgui.m*
- ***Input:***
    - *wordlist:* previously generated wordlist alphabetized and formatted as a cell array
    - *analysis_name*
    - *w_dir:* working directory
    - *data*: orthophonotactic/sublexical data from pretabulated corpus
    - *jpglove:*: semantic glove vectors from pretabulated corpus
- ***Output:***
    - *fDM.mat* (struct of feature distance matrices)
        - Grapheme Edit Distance
        - Phoneme Edit Distance
        - Letter Edit Distance
        - Grapheme-Phoneme Pair Edit Distance 
        - Onset/Rime Edit Distance
        - Semantic Distance(1-pearson's r for words' GLOVE vectors)
    - *cDM.mat* (struct of control distance matrices)
        - Number of Letters
        - Number of Syllables

### make_eDM.mat
- Makes experience distance matrices(feature frequency+probability)
- Use tertile thresholds created from input wordlist to create 3 values as the output: 
    - *0(less tuned):* the minimum frequency/probability feature in each word is below the bottom tertile threshold of the wordlist. The idea is that these words will have diffrerent within-stimulus and similarly cross-stimulus neural representation. 
    - *1(highly tuned):* the minimum frequency/probability feature in each word is above the upper tertile threshold of the wordlist. The idea is that these words will have similar within-stimulus and different across-stimulus neural representation. 
    - *0.5(middle):* the minimum frequency feature/probability feature in each word are in different tertiles or the middle tertiles 
- ***Inputs:***
    - *wordlist:* previously generated wordlist alphabetized and formatted as a cell array
    - *analysis_name*
    - *w_dir:* working directory
    - *data*: orthophonotactic/sublexical data from pretabulated corpus
    - *indPG_data:* Word's individual orthophonotactic data
    - *freq:* Whole word frequencies
- ***Outputs:***
    - *eDM.mat* (struct of experience distance matrices)
        - Word Frequency *(SUBTLEXUS)*
         - Grapheme Frequency
        - Phoneme Frequency
        - Letter Frequency
        - Grapheme-Phoneme Pair Frequency
        - Onset/Rime Frequency
        - Grapheme-Phoneme Pair Probability
        - Onset/Rime Probability
        

### make_feDM.m
- Makes feature*experience distance matrices(feDM) and saves additional file (allDM.mat) with all distance matrices. 
- ***Inputs:***
    - *wordlist:* previously generated wordlist alphabetized and formatted as a cell array
    - *analysis_name*
    - *w_dir:* working directory
    - *data*: orthophonotactic/sublexical data from pretabulated corpus
    - *fDM:* struct of feature distance matrices
    - *eDM:* struct of experience distance matrices
    - *cDM:* struct of control distance matrices
- ***Outputs:***
        - *feDM.mat:* struct of feature-experience distance matrix
            - (feature distance matrix)*(experience distance matrix) elementwise product, used as a proxy of neural tuning)
                - Grapheme Frequency*Edit Distance
                - Phoneme Frequency*Edit Distance
                - Letter Frequency*Edit Distance
                - Grapheme-Phoneme Pair Frequency*Edit Distance
                - Onset/Rime Frequency*Edit Distance
                - Grapheme-Phoneme Pair Probability*Edit Distance
                - Onset/Rime Probability
        - *allDM.mat:* struct of all fDM, eDM, cDM, and feDM combined


### Make Matrix Files
#### make_analysisfiles.m
- Performs a linear regression on selected distance matrices and partialing out other selected matrices
- Saves the residuals of the linear regression
- Creates a summary of the correlations(Spearman's Rho or Kendall's Tau) of the previously calculated residuals 
- ***Inputs***
    - From analysis GUI
- ***Outputs***
    - .mat file with 

#### analysis_gui.m
- Code for selecting matrices to save reaiduals of and to partial out. 
- ***Inputs:***
    - Select matrices to partial out *(User Input)*
    - Select matrices to save residuals of *(User Input)*
    - Select type of correlation to calculate on residuals(Spearman's Rho or Kendall's Tau, Default=Spearman) *(User Input)*
    - Select if you want to partial out the matrices whose residuals are being calculated from each other(using the original distance matrices, Default=True) *(User Input)*
    - Name for the analysis/output *(User Input)*
- ***Outputs*** 
    - Created by make_analysisfiles.m

## Installation
1. Download entire repository
2. Launch matlab
3. Add the entire Lexical-Distance Repository to your path using "Add folder with subfolders".
    - For those new to matlab, it is hunder the home tab, in the environment section, and says "Set Path" with a folder icon

## Usage Notes
The program can then be launched by entering the  following in the command line:        
>       LexicalDistanceAnalysis

This will launch the main gui that will offer options to create the set up files or to create analysis files. Both of these options will open a new window with their respective GUIs. 
### Setup Distance Matrices
- Allows you to create *distance matrices* by inputting a word list
- Must be run before the *Make Analysis Files* Option since it provides the input for those functions
### Make Analysis Files
- Allows you to take the output folder from the *Setup* functions and decorrelate them from each other
- The output is residuals of distance matrices that have had other distance matrices partialled out using multiple linear regression

