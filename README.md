# Q2Pipe
Q2Pipe is a powerful and flexible pipeline designed to streamline and automate the microbiome analysis process. It serves as a user-friendly interface for conducting complex microbial community analyses, specifically designed to work seamlessly with Qiime2 (Bolyen, et al., 2019), a popular bioinformatics platform for microbiome research.

## What it does:
•	Q2Pipe provides a comprehensive workflow for microbiome analysis, guiding users through every step, from data import to metrics and tables generation for statistical analyses.

•	It automates routine tasks and ensures that best practices in data processing and analysis are followed. 

•	Users can customize and fine-tune various analysis parameters to meet their specific research needs.

## Who should use it:
•	Researchers and scientists working on microbiome projects who want to simplify and expedite their data analysis.

•	Those with varying levels of expertise, from beginners to experienced bioinformaticians, as Q2Pipe offers both automation and customization options.

•	Anyone looking to conduct microbiome analyses using Qiime2 and benefit from a streamlined and user-friendly workflow.

# Setup

Q2Pipe was designed to work with a Apptainer image container (which is based on the Qiime2's Docker release) and therefore is the recommended method for this pipeline. You can however use it with the Qiime2's anaconda environment, but you'll have to manually include the Q2Pipe dependencies into it.

## Qiime2 environment setup with apptainer

### Building the Apptainer image yourself
**Make sure Apptainer is installed and ready on your system before building the image**
You can build the Apptainer using the provided recipe in this repo (Apptainer_Qiime2_NRCan.recipe) with this command (in sudo or with --fakeroot if supported on your system):
```
apptainer build qiime2_2023_5_q2p0954.sif $Q2P/Apptainer_Qiime2_NRCan.recipe
```

Once the build is done, you must edit the default option file

### Pulling the image from the Singularity repo
You can pull the apptainer image from ghcr.io by using this command:
```
apptainer pull qiime2_2023_5_q2p0954.sif oras://ghcr.io/patg13/q2pipe/qiime2_q2pipe:2023_5_v0954
```

## Prepare Q2Pipe pipeline

### Clone the repo and create Q2P environment variable
```
git clone https://github.com/NRCan/Q2Pipe.git
export Q2P="$PWD/Q2Pipe"

# Optional
echo "export Q2P="$PWD/Q2Pipe"" >> $HOME/.bashrc
```
### Modify the default option file
You have to link your apptainer image to the option file so Q2Pipe can correctly make command calls during execution.

```
# Modify the APPTAINER_COMMAND= line in optionfile_q2pipe_default.txt
# You can specify a different temprary folder by adding -B /path/to/your/temp/folder:/tmp before the image path

APPTAINER_COMMAND="apptainer exec --cleanenv --env MPLCONFIGDIR=/tmp,TMPDIR=/tmp /path/to/your/apptainer_image.sif"
```

You are now set to run Q2Pipe

# USAGE

To correctly execute Q2Pipe, you can refer to the user guide provided in the repo **[User Guide](https://github.com/NRCan/Q2Pipe/blob/main/Q2Pipe_User_Guide_V0.95.4_Public.pdf) 

# License

Q2Pipe is open-source software released under the **[MIT License](LICENSE)**.

This pipeline was developped at Natural Ressources Canada's Dr. Christine Martineau laboratory

