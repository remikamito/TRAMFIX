#!/bin/bash

# Author: Remika Mito
# Date: 12 May 2025
# Description: This script performs the next preprocessing steps for Travelling Heads data (unbias, upsample). 
# It also estimates the response functions for each participant
# This script should be run within a slurm script to run in batch all the protocols for a given site.

# load modules
module load MRtrix/3.0.4
module load ANTs/2.4.4

# check arguments are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: script_TH_step02_preproc_RFs.sh [ID] [SITE] [PROTOCOL]"
  exit 1
fi

# example usage
# sbatch script_TH_step02_preproc_RFs.sh P01 MBI freedwi
# Note the protocol options are: harmdwi freedwi mddw aepdwi didwi sandi ukb ukb_cmrr ukb_product (use lowercase and this exact usage)

# specify inputs & outputs
ID=$1
SITE=$2
PROTOCOL=$3
OUTDIR=/data/gpfs/projects/punim2175/T-HEADS/mif/${ID}/${SITE}/DWI_${PROTOCOL}


### Step 3: Run bias field correction ###
dwibiascorrect ants $OUTDIR/dwi_denoised_unringed_preproc.mif $OUTDIR/dwi_denoised_unringed_preproc_unbiased.mif

### Step 4: Compute response functions ###
# Note that average responses will be computed in the next script
dwi2response dhollander $OUTDIR/dwi_denoised_unringed_preproc_unbiased.mif $OUTDIR/response_wm.txt $OUTDIR/response_gm.txt $OUTDIR/response_csf.txt

### Step 5: Upsample DWI images ###
mrgrid $OUTDIR/dwi_denoised_unringed_preproc_unbiased.mif regrid -vox 1.25 $OUTDIR/dwi_denoised_unringed_preproc_unbiased_upsampled.mif

### Step 6: Compute upsampled brain masks ###
dwi2mask $OUTDIR/dwi_denoised_unringed_preproc_unbiased_upsampled.mif $OUTDIR/dwi_mask_upsampled.mif

### Remove unnecessary DWI if this completes successfully ###
if [ -f $OUTDIR/dwi_denoised_unringed_preproc_unbiased_upsampled.mif ] && [ -f $OUTDIR/response_wm.txt ]; then
	echo "Removing intemediary DWIs."
	rm -f $OUTDIR/${PROTOCOL}_denoised.mif $OUTDIR/${PROTOCOL}_denoised_unringed.mif $OUTDIR/dwi_denoised_unringed_preproc.mif
else
	echo "Upsampled image and/or response functions not generated. Keeping intemediary outputs."
fi

module unload MRtrix/3.0.4
module unload ANTs/2.4.4