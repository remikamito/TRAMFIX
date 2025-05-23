#!/bin/bash

# Author: Remika Mito
# Date: 9 May 2025
# Description: This script performs the preprocessing steps for Travelling Heads data. 
# This script should be run within a slurm script to run in batch all the protocols for a given site.
# Note that this script is updated from the previous version to include additional considerations when running preproc

# load modules
module load MRtrix/3.0.4
module load FSL/6.0.7.12
module load CUDA
module load ANTs/2.4.4

# check arguments are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: script_TH_step01_preproc.sh [ID] [SITE] [PROTOCOL]"
  exit 1
fi

# example usage
# sbatch script_TH_step01_preproc.sh P01 MBI freedwi
# Note the protocol options are: harmdwi freedwi mddw aepdwi didwi sandi ukb ukb_cmrr ukb_product (use lowercase and this exact usage)

# specify inputs & outputs
ID=$1
SITE=$2
PROTOCOL=$3
OUTDIR=/data/gpfs/projects/punim2175/T-HEADS/mif/${ID}/${SITE}/DWI_${PROTOCOL}
FSLDIR=/apps/easybuild-2022/easybuild/software/Core/FSL/6.0.7.12/

### Step 1: Run denoising step ###
# Note: denoising should be performed before we concatenate any images & extract relevant b-shells!
# where there is one input ${PROTOCOL}.mif
if [ -f $OUTDIR/${PROTOCOL}.mif ] ; then
	dwidenoise $OUTDIR/${PROTOCOL}.mif $OUTDIR/${PROTOCOL}_denoised.mif
# where there are AP and PA sets - denoise individually then concatenate
elif [ -f $OUTDIR/${PROTOCOL}_AP.mif ] && [ -f $OUTDIR/${PROTOCOL}_PA.mif ] && [ ! -f $OUTDIR/${PROTOCOL}.mif ]; then
	#mrcat $OUTDIR/${PROTOCOL}_AP.mif $OUTDIR/${PROTOCOL}_PA.mif  -axis 3 $OUTDIR/${PROTOCOL}_all.mif
	dwidenoise $OUTDIR/${PROTOCOL}_AP.mif $OUTDIR/${PROTOCOL}_AP_denoised.mif
	dwidenoise $OUTDIR/${PROTOCOL}_PA.mif $OUTDIR/${PROTOCOL}_PA_denoised.mif
	mrcat $OUTDIR/${PROTOCOL}_AP_denoised.mif $OUTDIR/${PROTOCOL}_PA_denoised.mif  -axis 3 $OUTDIR/${PROTOCOL}_denoised.mif
# for HCP data
elif [ "$PROTOCOL" == "hcpdwi" ] ; then
	dwidenoise $OUTDIR/${PROTOCOL}_99dir_AP.mif $OUTDIR/${PROTOCOL}_AP_denoised.mif
	dwidenoise $OUTDIR/${PROTOCOL}_98dir_AP.mif $OUTDIR/${PROTOCOL}_PA_denoised.mif
	mrcat $OUTDIR/${PROTOCOL}_AP_denoised.mif $OUTDIR/${PROTOCOL}_PA_denoised.mif  -axis 3 $OUTDIR/${PROTOCOL}_denoised.mif
fi

### Step 2: Run unringing ###
mrdegibbs $OUTDIR/${PROTOCOL}_denoised.mif $OUTDIR/${PROTOCOL}_denoised_unringed.mif -axes 0,1

### Step 3: Check predwi and make b0_pair ###
# for harmonisation protocol, leading b0s should be extracted - note this should be done on denoised data!
if [ "$PROTOCOL" == "harmdwi" ] || [ "$PROTOCOL" == "aepdwi" ]; then
	# Extract b0s for each image (denoised), then concatenate
	mrconvert $OUTDIR/${PROTOCOL}_AP_denoised.mif -coord 3 0:1:2 $OUTDIR/${PROTOCOL}_AP_b0.mif 
	mrconvert $OUTDIR/${PROTOCOL}_PA_denoised.mif -coord 3 0:1:2 $OUTDIR/${PROTOCOL}_PA_b0.mif
	mrcat ${OUTDIR}/${PROTOCOL}_AP_b0.mif ${OUTDIR}/${PROTOCOL}_PA_b0.mif $OUTDIR/${PROTOCOL}_b0_pair.mif
# where there are 2 b0s (AP and PA blips)
elif [ -f $OUTDIR/${PROTOCOL}_predwi_AP.mif ] && [ -f $OUTDIR/${PROTOCOL}_predwi_PA.mif ] ; then
	# if the blips have more than 1 volume (di and sandi) - note, I don't need to do this!! can use all b0s
	if [ ` mrinfo $OUTDIR/${PROTOCOL}_predwi_AP.mif -ndim `  == 4 ] ; then
		mrconvert $OUTDIR/${PROTOCOL}_predwi_AP.mif -coord 3 0 $OUTDIR/${PROTOCOL}_predwi_AP_b0.mif 
		mrconvert $OUTDIR/${PROTOCOL}_predwi_PA.mif -coord 3 0 -axes 0,1,2 $OUTDIR/${PROTOCOL}_predwi_PA_b0.mif
		mrcat ${OUTDIR}/${PROTOCOL}_predwi_AP_b0.mif ${OUTDIR}/${PROTOCOL}_predwi_PA_b0.mif ${OUTDIR}/${PROTOCOL}_b0_pair.mif -axis 3
	# if the blips are 3D (freedwi, mddw, 
	elif [ ` mrinfo $OUTDIR/${PROTOCOL}_predwi_AP.mif -ndim `  == 3 ] ; then
		mrcat ${OUTDIR}/${PROTOCOL}_predwi_AP.mif ${OUTDIR}/${PROTOCOL}_predwi_PA.mif ${OUTDIR}/${PROTOCOL}_b0_pair.mif -axis 3
	fi
# where there is 1 blip (PA only - ukb)
elif [ -f $OUTDIR/${PROTOCOL}_predwi_PA.mif ] && [ ! -f $OUTDIR/${PROTOCOL}_predwi_AP.mif ] ; then
	if [ "$PROTOCOL" == "ukb" ] || [ "$PROTOCOL" == "ukb_cmrr" ] || [ "$PROTOCOL" == "ukb_product" ]; then
		mrconvert ${OUTDIR}/${PROTOCOL}_predwi_PA.mif -coord 3 0 -axes 0,1,2 $OUTDIR/${PROTOCOL}_PA_b0.mif
		mrconvert ${OUTDIR}/${PROTOCOL}.mif -coord 3 0 -axes 0,1,2 ${OUTDIR}/${PROTOCOL}_AP_b0.mif
		mrcat ${OUTDIR}/${PROTOCOL}_AP_b0.mif ${OUTDIR}/${PROTOCOL}_PA_b0.mif ${OUTDIR}/${PROTOCOL}_b0_pair.mif -axis 3
	else
		echo "Check predwi exists for both AP & PA: $PROTOCOL"
		exit 1
	fi
fi

### Step 4: Run preproc ###
# For data with b0 pairs (freedwi, mddw, DI, SANDI)
if [ "$PROTOCOL" == "freedwi" ] || [ "$PROTOCOL" == "mddw" ] || [ "$PROTOCOL" == "didwi" ] ; then
	echo "Running preprocessing for ${PROTOCOL} with b0 pairs..."
	dwifslpreproc ${OUTDIR}/${PROTOCOL}_denoised_unringed.mif $OUTDIR/dwi_denoised_unringed_preproc.mif -rpe_pair -se_epi $OUTDIR/${PROTOCOL}_b0_pair.mif -pe_dir ap -eddyqc_text $OUTDIR/eddylogs 

elif [ "$PROTOCOL" == "sandi" ]; then
	echo "Running preprocessing for ${PROTOCOL} with b0 pairs..."
  dwifslpreproc ${OUTDIR}/${PROTOCOL}_denoised_unringed.mif $OUTDIR/dwi_denoised_unringed_preproc.mif -rpe_pair -se_epi $OUTDIR/${PROTOCOL}_b0_pair.mif -pe_dir ap -eddyqc_text $OUTDIR/eddylogs -eddy_options " --slm=linear" -eddy_options " --data_is_shelled"

# For data with one b0 blip (ukb)
elif [ "$PROTOCOL" == "ukb" ] || [ "$PROTOCOL" == "ukb_cmrr" ] || [ "$PROTOCOL" == "ukb_product" ]; then
	echo "Running preprocessing for ${PROTOCOL} with one b0 blip..."
	dwifslpreproc ${OUTDIR}/${PROTOCOL}_denoised_unringed.mif $OUTDIR/dwi_denoised_unringed_preproc.mif -rpe_pair -se_epi $OUTDIR/${PROTOCOL}_b0_pair.mif -pe_dir ap -eddyqc_text $OUTDIR/eddylogs

# For data with AP and PA directions (harmonisation & AEP)
elif [ "$PROTOCOL" == "harmdwi" ] || [ "$PROTOCOL" == "aepdwi" ] || [ "$PROTOCOL" == "aepdwi_nii" ]; then
	echo "Running preprocessing for ${PROTOCOL} with AP and PA directions..."
	dwifslpreproc $OUTDIR/${PROTOCOL}_denoised_unringed.mif $OUTDIR/dwi_denoised_unringed_preproc.mif -rpe_header -eddyqc_text $OUTDIR/eddylogs -se_epi $OUTDIR/${PROTOCOL}_b0_pair.mif

# For data with full AP and PA sets (HCP-lifespan)
elif [ "$PROTOCOL" == "hcpdwi" ]; then
	echo "Running preprocessing for ${PROTOCOL} with full AP and PA sets..."
	dwifslpreproc $OUTDIR/${PROTOCOL}_denoised_unringed.mif $OUTDIR/dwi_denoised_unringed_preproc.mif -rpe_all -pe_dir ap -eddyqc_text $OUTDIR/eddylogs -se_epi $OUTDIR/${PROTOCOL}_b0_pair.mif

# Else if protocol not working
else
	echo "Unsupported protocol: $PROTOCOL"
	exit 1
fi

### Step 5: Run bias field correction ###
if [ -f $OUTDIR/dwi_denoised_unringed_preproc.mif ] ; then
	dwibiascorrect ants $OUTDIR/dwi_denoised_unringed_preproc.mif $OUTDIR/dwi_denoised_unringed_preproc_unbiased.mif
elif [ ! -f $OUTDIR/dwi_denoised_unringed_preproc.mif ] ; then
	echo "Preprocessed image not found. Skipping bias field correction."
fi


module unload MRtrix/3.0.4
module unload FSL/6.0.7.12
module unload CUDA