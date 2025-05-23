# DWI data processing pipeline

Here, we describe the processing pipeline for the DWI harmonisation protocol. 

The protocol was a multi-shell DWI protocol acquired across all 4 sites. 

There were two key pipelines tested on this dataset, to reflect potential pipelines that might be used by researchers conducting studies across multiple sites:
- Pipeline 1: Site-specific processing
- Pipeline 2: Global processing

These two pipelines reflect two possible processing scenarios for combining data across sites:
- Scenario 1: data are processed locally, using site-specific response functions, FOD modelling, and population template building, before being pooled with other sites
- Scenario 2: all data are pooled together prior to analysis, using globally averaged RFs. Population template uses data across all sites. 

Preprocessing, tensor, and brain mask estimation were performed in the same way for both the above pipelines, and are described first.

# Part 1: Preprocessing, RF and tensor estimation

## Step 1: Preprocessing

Preprocessing of DWI data was performed following the MRtrix3 recommended pipelines for multi-tissue CSD. 

The steps include:
1. Denoising (Veraart et al., 2016)
2. Gibbs ringing removal (Kellner et al., 2016)
3. Motion & distortion correction (FSL topup & eddy)
4. Bias field correction (ANTs N4)
5. Upsampling DWI data

### Scripts

- [`script_TH_step01_preproc.sh`](/dwi_scripts/script_TH_step01_preproc.sh): performs preprocessing steps 1-3.
- [`slurm_TH_step01_preproc_gpu.script`](/dwi_scripts/slurm_TH_step01_preproc_gpu.script): This script runs the above script on an HPC system (using GPUs for topup/eddy)


## Step 2: Response function estimation

Response function estimation was performed using the dhollander algorithm. In the below scripts, we also included bias field correction & upsampling. 

### Scripts

- [`script_TH_step02_preproc_RF.sh`](/dwi_scripts/script_TH_step02_preproc_RF.sh): performs RF estimation, as well as preprocessing steps 4 & 5. 
- [`slurm_TH_step02_preproc_RF.script`](/dwi_scripts/slurm_TH_step02_preproc_RF.script): performs the above on HPC system


## Step 3: Tensor estimation 

Here, we compute diffusion tensor and extract FA & MD (ADC). We also compute brain masks using FSL BET.

### Scripts

- [`script_TH_masks_tensor.sh`](/dwi_scripts/script_TH_masks_tensor.sh)
- [`slurm_TH_step03_mask_tensor.script`](/dwi_scripts/slurm_TH_step03_mask_tensor.script)

After this point, we describe the FOD modelling & population template separately for pipelines 1 & 2. 

# Part 2: FOD modelling & population template

Here, we describe the steps separately for Pipeline 1 (site-specific) and Pipeline 2 (global).

## Pipeline 1: Site-specific FODs & population template

Here, the FOD estimation is done using site-averaged response functions. Site-specific templates are built, and a cohort (population) template is built using the site-specific templates to enable comparison of fixel-based measures across sites.

### FOD modelling scripts:
- [`msmt_csd_mtnorm_siteRF.sh`](/dwi_scripts/msmt_csd_mtnorm_siteRF.sh): performs multi-shell multi-tissue CSD (Jeurissen et al. 2014) using site-specific (site-averaged) RFs. Also include mtnormalise.
- [`slurm_TH_pipeline1_step04_msmtcsd.script`](/dwi_scripts/slurm_TH_pipeline1_step04_msmtcsd.script): above in slurm script.

### Population template scripts:

- [`slurm_TH_pipeline1_step05_sitetemplates.script`](/dwi_scripts/slurm_TH_pipeline1_step04_msmtcsd.script): Runs site-specific population templates
- [`slurm_TH_pipeline1_step06_warp2sitetemplate.script`]()
- [`slurm_TH_pipeline1_step07_poptemplate_1_sites.script`]()

## Pipeline 2: Global processing

Here, FOD estimation is performed using globallly averaged response functions (across sites). Population template is build using all sites.

### FOD modelling scripts:
- [`msmt_csd_mtnorm_globalRF.sh`](/dwi_scripts/msmt_csd_mtnorm_globalRF.sh): performs MSMT-CSD using globally averaged RFs.
- [`slurm_TH_pipeline2_step04_msmtcsd.script`](/dwi_scripts/slurm_TH_pipeline2_step04_msmtcsd.script): runs in slurm script

### Population template scripts



