# Q2Pipe V 0.93.1
Q2Pipe is a Qiime2 based pipeline designed to facilitate and standardise ecological studies by metabarcoding using Illumina Miseq data. It basically shell scripts calling different Qiime2 commands and Q2Pipe dependencies (https://github.com/Patg13/Q2Pipe_Deps) to produce the results. Q2Pipe was also designed to minimized the installation work and maximise the compatiblity between different systems.

# Setup

Q2Pipe can be used with the Qiime2's anaconda environment but was designed to work with a Apptainer image container (which is based on the Qiime2's Docker release) and therefore is the recommended method for this pipeline.

## Building the Apptainer image yourself
**Make sure Apptainer is installed and ready on your system before building the image**
You can build the Apptainer using the provided recipe in this repo (Apptainer_Qiime2_NRCan.recipe)

Once the build is done, you must edit the default option file (

## Pulling the image from the Singularity repo
NOT AVAILABLE FOR NOW, IMAGE STILL NOT ON REPO

# USAGE
Q2Pipe was seperated into 11 different steps to make it easier to control, customise, update, etc.
You can check the provided user guide for more information on using Q2Pipe
##1 Importation
This step will grab your manifest(s) file(s) and compress them in a Qiime2 artifact file (QZA) and generate a Qiime2 Visualization file (QZV) containing the run's quality graphs to help you identify the best trimming parameter. If you have more than one sequencing run for a single gene, you must create a manifest per run and speicify them both in the option file, they will be automatically treated independently and merged later on.
##2 Dada2 Denoising
This step will proceed to trim, denoise and build ASV from your imported data
##2. Run Merging
Because Dada2 guideline specify to NEVER denoise multiple sequencing run together, this step will merge runs together to carry on with the analysis
##3 Frequency Filtering
You can use this step to remove rare or low occuring ASVs
##4 Vsearch Clustering
This optional step is to cluster some ASV together depending on their similarity, it is recommended to skip this step instead of using a 1.0 clustering level, which will still regroup identical ASV with variable length. NOTICE, using this step will transform your ASVs into OTUs.
##5 Classifier Training
Optional step if you don't have a pre-trained Qiime2 Classifier for the taxonomical classification. THIS STEP IS DEPRECIATED AND WILL BE REMOVE IN FUTURE VERSION
##6 Taxonomy Classification
Using a pre-trained classifier, this step will classify your ASVs into their correcponding taxonomical group
##7 Metadata + Taxa Filtering
In certain situation you can use a taxonomical filter to remove certain species/organism/groups from you data, this step will do just that. You can also use it to exclude samples depending on their Metadata infomation (Ex. Exclude every sample from a specific site)
##8 Rarefaction curve
Because rarefaction is pretty much a must when doing statistical analysis on metabarcoding data, this step will generate a rarefaction curve to help you identify a proper rarefaction level (one that does not exclude too much sequences, but samplig enough so don't change the sample composition). you can also skiprarefaction altogether.
##9 Rarefaction
Use the level identified in the previous step to rarefy your data
##10 Metrics Generation
Will generate Qiime2 default metrics (according to core-metrics command, but will no use the command per se)
##11 Exportation
Will proceed with different secondary analysis (FUNguild, ANCOM, etc.) and produce the ASV Tables.


# License

This pipeline was developped at Natural Ressources Canada's Dr. Christine Martineau laboratory

