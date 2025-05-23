#!/bin/bash

# Author: Remika Mito
# Date: 13 May 2025
# Description: This script computes FODs on TH data (MSMT-CSD using site-averaged RFs)

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
dwi2fod msmt_csd ${DWIDIR}/dwi_denoised_unringed_preproc_unbiased_upsampled.mif ${RFDIR}/${SITE}_response_wm.txt ${DWIDIR}/wmfod.mif ${RFDIR}/${SITE}_response_gm.txt ${DWIDIR}/gm.mif ${RFDIR}/${SITE}_response_csf.txt ${DWIDIR}/csf.mif -mask ${DWIDIR}/brain_mask.nii.gz

### Step 2: run mtnormalise ###
mtnormalise ${DWIDIR}/wmfod.mif ${DWIDIR}/wmfod_norm.mif ${DWIDIR}/gm.mif ${DWIDIR}/gm_norm.mif ${DWIDIR}/csf.mif ${DWIDIR}/csf_norm.mif -mask ${DWIDIR}/brain_mask.nii.gz

### Step 3: Delete unnecessary outputs ###
#rm -f ${DWIDIR}/wmfod.mif ${DWIDIR}/gm.mif ${DWIDIR}/csf.mif

# unload modules
module unload MRtrix/3.0.4