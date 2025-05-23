#!/bin/bash

# Author: Remika Mito
# Date: 23 May 2025
# Description: This script computes FODs on TH data (MSMT-CSD using globally averaged RFs)

# check arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: msmt_csd.sh [ID] [SITE]"
  exit 1
fi

# load modules
module load MRtrix/3.0.4

# specify inputs
ID=$1
SITE=$2
DWIDIR=/data/gpfs/projects/punim2175/T-HEADS/mif/${ID}/${SITE}/DWI_harmdwi
RFDIR=/data/gpfs/projects/punim2175/T-HEADS/group_rfs

### Step 1: run FOD estimation ###
dwi2fod msmt_csd ${DWIDIR}/dwi_denoised_unringed_preproc_unbiased_upsampled.mif ${RFDIR}/global_average_response_wm.txt ${DWIDIR}/wmfod_globalRF.mif ${RFDIR}/global_average_response_gm.txt ${DWIDIR}/gm_globalRF.mif ${RFDIR}/global_average_response_csf.txt ${DWIDIR}/csf_globalRF.mif -mask ${DWIDIR}/brain_mask.nii.gz

### Step 2: run mtnormalise ###
mtnormalise ${DWIDIR}/wmfod_globalRF.mif ${DWIDIR}/wmfod_norm_globalRF.mif ${DWIDIR}/gm_globalRF.mif ${DWIDIR}/gm_norm_globalRF.mif ${DWIDIR}/csf_globalRF.mif ${DWIDIR}/csf_norm_globalRF.mif -mask ${DWIDIR}/brain_mask.nii.gz

### Step 3: Delete unnecessary outputs ###
rm -f ${DWIDIR}/wmfod_globalRF.mif ${DWIDIR}/gm_globalRF.mif ${DWIDIR}/csf_globalRF.mif
	

# unload modules
module unload MRtrix/3.0.4