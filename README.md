
# MRICloudR

This is an R package which wraps the MRICloud API so that it can be accessed from R.

## Install using devtools

To build and install `MriCloudR` using `devtools` 

  devtools::install_github("bcaffo/MriCloudR/MriCloudR")


## Example code

Please see T1Example.r and DtiExample.r for examples on using the interfaces.  They may be run via Rscript:

	Rscript T1Example.r

and

	Rscript DtiExample.r 

## Release Notes

0.9.0  Initial release supporting T1 segmentation  
0.9.1  Added Dti segmentation and adjusted default mricloud URL
0.9.2  Changed the directory structure so that it can be submitted to Neuroconductor
