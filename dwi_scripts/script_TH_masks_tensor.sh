#!/bin/bash

# Author: Remika Mito
# Date: 13 Nov 2024
# Description: This script computes diffusion tensor on TH data (MRtrix version)
# For this script, we are using all diffusion data. 
# This script should be run within a slurm script

# check arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: tensor_mrtrix.sh [ID] [SITE]"
  exit 1
fi

# load modules
module load MRtrix/3.0.4
module load FSL/6.0.7.12

# specify inputs
ID=$1
SITE=$2
DWIDIR=/data/gpfs/projects/punim2175/T-HEADS/mif/${ID}/${SITE}/DWI_harmdwi
FSLDIR=/apps/easybuild-2022/easybuild/software/Core/FSL/6.0.7.12/

### Step 0: Run mrconvert on input dwi ###
mrconvert $DWIDIR/dwi_denoised_unringed_preproc_unbiased_upsampled.mif $DWIDIR/dwi_preproc_upsampled.nii.gz -export_grad_fsl $DWIDIR/Diffusion.bvecs $DWIDIR/Diffusion.bvals

### Step 1: Compute brain mask ###
bet $DWIDIR/dwi_preproc_upsampled.nii.gz $DWIDIR/dwi_mask_bet.nii.gz
# dwi2mask $DWIDIR/dwi_denoised_unringed_preproc_unbiased_upsampled.mif $DWIDIR/dwi_mask_mrtrix.mif
mrcalc $DWIDIR/dwi_mask_upsampled.mif $DWIDIR/dwi_mask_bet.nii.gz -add - | mrthreshold - -abs 0.5 $DWIDIR/brain_mask.mif

### Step 2: Compute diffusion tensor ###
# note that we have 3 bvalues (300, 1000 & 3000). We use the b0 & 1000 shell only for tensor fit
dwiextract $DWIDIR/dwi_denoised_unringed_preproc_unbiased_upsampled.mif -shell 0,1000 - | dwi2tensor - -mask $DWIDIR/brain_mask.mif $DWIDIR/tensor_mrtrix.mif

### Step 3: Compute FA ###
tensor2metric $DWIDIR/tensor_mrtrix.mif -fa $DWIDIR/fa_mrtrix.nii.gz

### Step 4: Compute ADC ###
tensor2metric $DWIDIR/tensor_mrtrix.mif -adc $DWIDIR/adc_mrtrix.nii.gz

### Remove unnecessary outputs ###
rm $DWIDIR/dwi_preproc_upsampled.nii.gz

# unload modules
module unload MRtrix/3.0.4
module unload FSL/6.0.7.12