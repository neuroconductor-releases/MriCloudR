#library(httr)
#library(methods)
#source("R/T1SegData.r")

#' A wrapper around the AnatomyWorks MriCloud Web API
#'
#' This class makes the MriCloud API functionality available in R,
#' encapsulating the http communications so that it behaves like a standard R
#' interface.
#'
#' @slot baseUrl The root URL of the MRICloud API.
#' Default is \url{https://braingps.mricloud.org}.
#' @slot verbose Verbose output
#' @import httr methods
#' @export
#' @export MriCloudR
MriCloudR <- setClass(
  "MriCloudR",
  representation(baseUrl = "character",
                 verbose = "logical"),
  prototype(baseUrl = "https://braingps.mricloud.org",
            verbose = FALSE))


#' @export
#' @rdname login
setGeneric(name = "login", def = function(object, username, password)
{
  standardGeneric("login")
}
)

#' Login to MriCloud
#'
#' \code{login} logs into the MriCloud Api, which must be done before calling
#' any subsequent methods. If you do not have an MriCloud account, go to
#' \url{https://braingps.mricloud.org} to register or retrieve forgotton
#' credentials.
#'
#' @param object Object of class \code{\link{MriCloudR-class}}.
#' @param username MriCloud username
#' @param password MriCloud password
#' @export
#' @rdname login
setMethod(f = "login",
          signature(object = "MriCloudR",
                    username = "character",
                    password = "character"),
          definition = function(object, username, password)
          {

            # Login request.  For now, just do direct login.  Note the config
            # option (followlocation = 0L) so that redirection is not followed.
            # We need that because checking the redirect is the only way to
            # know if login was successful.

            # The returned cookie is used as the credential for subsequent
            # requests and are automatically propagated by httr

            httr::set_config( config( ssl_verifypeer = 0L ) )
            r <- POST(paste(object@baseUrl, "/login", sep = ''), body = list(login_email=username, login_password=password), encode = "form", config(followlocation = 0L));

            # throw error if there is an http error

            if(http_error(r))
              stop_for_status(r)
            #						print(r)

            # Currently, only way to check if login was successful is if redirect is to /home
            # Also check that the Location header is set.

            if(!is.null(headers(r)$Location) && headers(r)$Location == paste(object@baseUrl, "/home", sep = ''))
            {
              if(object@verbose)
                print("Login SUCCESS")
            } else {
              stop("Login FAILED. Check credentials.")
            }

            return(object)

          }
)

#' @export
#' @rdname dtiSeg
setGeneric(name = "dtiSeg", def = function(object, data = "DtiSegData")
{
  standardGeneric("dtiSeg")
})

#' Submit a DTI segmentation request.
#'
#' \code{dtiMap} Submits an asynchronous DTI segmentation request, returning a
#' job ID as reference for subsequent requests to check and retreive results.
#' @param object Object of class \code{\link{MriCloudR-class}}.
#' @param data A object of \code{\link{DtiSegData}} containing payload data and
#' metadata for the upload.
#' @return Returns the job ID for the processing request.
#' @export
#' @rdname dtiSeg
setMethod(f = "dtiSeg", signature(object = "MriCloudR", data = "DtiSegData"),
          definition = function(object, data)
          {
            sliceInt = which(data$sliceType[1] == data$sliceType@levels)[[1]] - 1
            atlasInt = which(data$atlas[1] == data$atlas@levels)[[1]] - 1

            body = list(slice_type = sliceInt,
                        atlas_name = atlasInt,
                        processing_serverid = data$processingServer,
                        zip = upload_file(data$dataZip),
                        description = data$description);

            r <- POST(paste(object@baseUrl, "/dtimultiatlasseg", sep = ''), body = body, encode = "multipart", config(followlocation = 0L), progress(type = "up"));

            stop_for_status(r)
            parsed <- content(r, "parsed")
            if(!is.null(parsed$response$status) && (parsed$response$status == "submitted"))
            {
              if(object@verbose)
                print(paste("Job successfully submitted with jobId: ", parsed$response$jobId, sep = ''));
              return(as.character(parsed$response$jobId));
            } else
            {
              stop("Error submitting job")
              return(0)
            }

          }
)



#' @export
#' @rdname t1Seg
setGeneric(name = "t1Seg", def = function(object, data = "T1SegData")
{
  standardGeneric("t1Seg")
}
)

#' Submit a t1 segmentation request.
#'
#' \code{t1Seg} Submits an asynchronous t1 segmentation request, returning a
#' job ID as reference for subsequent requests to check and retreive results.
#'
#' @param object Object of class \code{\link{MriCloudR-class}}.
#' @param data A object of \code{\link{T1SegData}} containing payload data and
#' metadata for the upload.
#' @return Returns the job ID for the processing request.
#' @export
#' @rdname t1Seg
setMethod(f = "t1Seg", signature(object = "MriCloudR", data = "T1SegData"),
          definition = function(object, data)
          {
            # I want a better way to do this.  I.e. like a real enum which
            # should get the integer representation.

            sliceInt = which(data$sliceType[1] == data$sliceType@levels)[[1]] - 1
            atlasInt = which(data$atlas[1] == data$atlas@levels)[[1]] - 1

            body = list(slice_type = sliceInt,
                        atlas_name = atlasInt,
                        target_hdr = upload_file(data$hdr),
                        target_img = upload_file(data$img),
                        processing_serverid = data$processingServer,
                        age = data$age,
                        gender = data$gender[1],
                        description = data$description)

            #						print(paste(object@baseUrl, "/t1prep", sep = ''))

            r <- POST(paste(object@baseUrl, "/t1prep", sep = ''), body = body, encode = "multipart", config(followlocation = 0L), progress(type = "up"));

            stop_for_status(r)
            parsed <- content(r, "parsed")
            if(!is.null(parsed$response$status) && (parsed$response$status == "submitted"))
            {
              if(object@verbose)
                print(paste("Job successfully submitted with jobId: ", parsed$response$jobId, sep = ''));
              return(as.character(parsed$response$jobId));
            } else
            {
              stop("Error submitting job")
              return(0)
            }


          }
)

#' @export
#' @rdname isJobFinished
setGeneric(name = "isJobFinished", def = function(object, jobId = "character")
{
  standardGeneric("isJobFinished")
}
)

#' Check job status
#'
#' \code{isJobFinished} checks status of processing for \code{jobId}.
#'
#' @param object Object of class \code{\link{MriCloudR-class}}.
#' @param jobId The jobId of the request, obtained from a processing request
#' such as \code{\link{T1SegData}}
#' @return \code{TRUE} if the job is completed, otherwise returns \code{FALSE}
#' @export
#' @rdname isJobFinished
setMethod(f = "isJobFinished", signature(object = "MriCloudR", jobId = "character"),
          definition = function(object, jobId)
          {
            r <- GET(paste(c(object@baseUrl, "/jobstatus%3Fjobid=", jobId), collapse = ''))
            #						str(headers(r))

            stop_for_status(r)
            parsed <- content(r, "parsed")
            if(is.null(parsed$status))
              stop(paste("Error: ", parsed, sep = ''))

            if(parsed$status == "finished")
              return(TRUE)
            else
              return(FALSE)


          }
)


#' @rdname downloadResult
#' @export
setGeneric(name = "downloadResult",
           def = function(object, jobId = "character",
                          filename = "character",
                          waitForJobToFinish = TRUE)
           {
             standardGeneric("downloadResult")
           }
)

#' Download result of processing request
#'
#' \code{downloadResult} downloads the result of a processing request
#' associated with \code{jobId}, such as from a \code{\link{t1Seg}} request.
#'
#' @param object Object of class \code{\link{MriCloudR-class}}.
#' @param jobId The jobId of the request, obtained from a processing request
#' such as \code{\link{t1Seg}}
#' @param filename Output filename for result.
#' @param waitForJobToFinish TRUE or FALSE.  If TRUE, \code{downloadResult}
#' will wait until the job is finished and then download the result (default
#' value is TRUE).  If FALSE, it will attempt to download the result but will
#' return if the job is not completed.
#' @return TRUE if download successful. FALSE otherwise
#' @rdname downloadResult
#' @export
setMethod(f = "downloadResult",
          signature(object = "MriCloudR", jobId = "character",
                    filename = "character", waitForJobToFinish = 'logical'),
          definition = function(object, jobId, filename, waitForJobToFinish)
          {
            if (waitForJobToFinish) {
              max_iter = 1000
              i = 1
              while (!isJobFinished(object, jobId))
              {
                if(object@verbose) {
                  message(paste0(
                    "Job ", jobId,
                    " not completed.  Sleeping 30s"))

                }
                i = i + 1
                if (i > max_iter) {
                  stop("Job is not finished, waited, but timed out")
                }
                Sys.sleep(30)
              }
            }

            if (isJobFinished(object, jobId)) {
              r <- httr::GET(
                paste0(object@baseUrl, "/roivis/jobid=",
                       jobId, "filename=Result.zip"),
                httr::progress(type = "down"),
                httr::write_disk(filename))
              return(TRUE);
            } else {
              print(paste(c("Job ", jobId, " not completed. Can't download result!"), collapse = ''))
              return(FALSE);
            }

          }
)


