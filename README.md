
[![Travis build
status](https://travis-ci.com/muschellij2/MriCloudR.svg?branch=master)](https://travis-ci.com/muschellij2/MriCloudR)
[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/muschellij2/MriCloudR?branch=master&svg=true)](https://ci.appveyor.com/project/muschellij2/MriCloudR)

<!-- README.md is generated from README.Rmd. Please edit that file -->

# MriCloudR

The goal of MriCloudR is to wraps the MRICloud API so that it can be
accessed from R.

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("muschellij2/MriCloudR")
```

## Example

Because `MriCloudR` currently only works with email/password
combinations, we have to store our passwords. The `keyringr` package has
a [great
vignette](https://cran.r-project.org/web/packages/keyringr/vignettes/Avoiding_plain_text_passwords_in_R_with_keyringr.html)
to show how to store your password by the password manaager for your
operating system. In our example, we have named the keychain (OS X)
entry as `mricloudr`.

``` r
library(MriCloudR)
library(keyringr)

# MriCloud object.  Submit requests and retrieve results.
mypwd <- decrypt_kc_pw("mricloudr")

mriCloudR <- MriCloudR(verbose = TRUE)

# Login using MriCloud credentials.  Currently, standard credentials are
# supported, not OpenId
login(mriCloudR, "youremail@email.com", mypwd)
```

### List Jobs

If you have previous jobs in your queue, you can see your job
identifiers with `listJobs`

``` r
listJobs(mriCloudR)
```

### T1 Segmentation Example

Here we download a `nifti` image from the Human Connectome Project using
the `neurohcp` package:

``` r
library(neurohcp)
img = "HCP_1200/102614/T1w/T1w_acpc_dc.nii.gz"
img = download_hcp_file(img)
```

Now that we have the downloaded image, we have to convert it to ANALYZE
format because this is required for MRICloud

``` r
library(ANTsR)
img = antsImageRead(img)

tfile = tempfile(fileext = ".hdr")
antsImageWrite(r, filename = tfile)

hdr = tfile
dat = sub("[.]hdr$", ".img", hdr)
```

Here we create a `T1SegData` object which contains payload information:

``` r
# Create T1SegData object which contains payload information
t1SegData <- T1SegData()
t1SegData$sliceType <- "Axial"
t1SegData$hdr <- hdr
t1SegData$img <- dat
t1SegData$age <- 40
t1SegData$description <- "Testing"
t1SegData$atlas <- "Adult_286labels_10atlases_V5L"

# submit to perform t1Seg.  Get back jobId.
jobId <- t1Seg(mriCloudR, t1SegData)
```

Now we have the `jobId`, `isJobFinished` checks status of job. We can
also see this new job ID in `listJobs`:

``` r
if (isJobFinished(mriCloudR, jobId = jobId)) {
  print("Finished");
} else {
  print(paste(c("Job ", jobId, " not completed yet!"), collapse = ''))
}
```

After the job is finished, you can download the result using
`downloadResult`:

``` r
# downloadResult will download the result if the jobId is finished.  If the
# argument waitForJobToFinish is TRUE, then downloadResult will wait until the
# job is completed (checking every minute), and then download the result.

x = downloadResult(mriCloudR, jobId = jobId, waitForJobToFinish = TRUE)
```

Now that the result was downloaded, it is a zip file, and we can unzip
it using `unzip`:

``` r
tdir = tempfile()
dir.create(tdir, showWarnings = FALSE)
unz = unzip(x, exdir = tdir)
```

Here we can read in the 286 labels from the segmentation:

``` r
seg_hdr = unz[grepl("_286Labels.hdr$", unz)]
res = antsImageRead(seg_hdr)
```

## Example code

Please see T1Example.r and DtiExample.r for examples on using the
interfaces. They may be run via Rscript:

    Rscript T1Example.r

and

    Rscript DtiExample.r 

## Release Notes

0.9.0 Initial release supporting T1 segmentation  
0.9.1 Added Dti segmentation and adjusted default mricloud URL 0.9.2
Changed the directory structure so that it can be submitted to
Neuroconductor
