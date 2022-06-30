## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ---- eval = FALSE------------------------------------------------------------
#  library(read.gt3x)
#  gt3xfile <- gt3x_datapath(1) # this downloads a long recording

## ---- eval = FALSE------------------------------------------------------------
#    N = 24 * 3600 # batch size in seconds (24 hours per day x 3600 seconds per hour)
#    i = 1
#    while (i > 0) {
#      try(expr = {
#        batch_data = read.gt3x(gt3xfile,
#                               batch_begin = 1 + ((i - 1) * N),
#                               batch_end = i * N)
#      }, silent = TRUE)
#      if (exists("batch_data")) {
#        cat("\nbatch #", i, "loaded with", nrow(batch_data),"rows")
#        # ... <= Insert your memory hungry algorithm
#        # ... <= Do not forget to store the output of your memory hungry algorithm somewhere
#  
#        rm(batch_data) # <= remove the batch_data object to free up memory before loading the next batch
#      } else {
#        break() # end while loop when no more batches can be extracted
#      }
#      i = i + 1
#    }

