
testthat::context("Reading New data")

csvfile <- system.file(
  "extdata", "TAS1H30182785_2019-09-17.csv.gz",
  package = "read.gt3x")
gt3xfile <-
  system.file(
    "extdata", "TAS1H30182785_2019-09-17.gt3x",
    package = "read.gt3x")


# Read ActiLife raw data output CSV
csvdata <- as.data.frame(data.table::fread(csvfile))
gt3xdataZeroes <- read.gt3x(gt3xfile, imputeZeroes = TRUE)
gt3xdata <- read.gt3x(gt3xfile)
tfile <- tempfile(fileext = ".gt3x")
file.copy(gt3xfile, tfile)
gt3xdata_full <- read.gt3x(gt3xfile, imputeZeroes = TRUE, asDataFrame = TRUE)

testthat::test_that("has_log_info", {
  testthat::expect_message({
    out <- read.gt3x(gt3xfile, imputeZeroes = TRUE, asDataFrame = TRUE,
                     debug = TRUE, verbose = 2)
  })

  testthat::expect_true(have_log_and_info(gt3xfile))
  tfile = tempfile()
  res =  unzip(gt3xfile, exdir = tfile)
  testthat::expect_true(have_log_and_info(tfile))
  testthat::expect_error(unzip.gt3x(tfile))
  unzip.gt3x(dirname(gt3xfile))
})
has_zoo <- requireNamespace("zoo", quietly = TRUE)
fzero <- function(df) {
  zero <- rowSums(df[, c("X", "Y", "Z")] == 0) == 3
  names(zero) <- NULL
  df$X[zero] <- NA
  df$Y[zero] <- NA
  df$Z[zero] <- NA
  df$X <- zoo::na.locf(df$X, na.rm = FALSE)
  df$Y <- zoo::na.locf(df$Y, na.rm = FALSE)
  df$Z <- zoo::na.locf(df$Z, na.rm = FALSE)

  df$X[is.na(df$X)] <- 0
  df$Y[is.na(df$Y)] <- 0
  df$Z[is.na(df$Z)] <- 0
  df
}

testthat::test_that("read.gt3x reads the first second of data correctly", {
  testthat::expect_true({
    all(unlist(head(csvdata, 100)) == unlist(head(gt3xdata, 100)))
  })
})

testthat::test_that("read.gt3x reads the fulldata correctly", {
  if (has_zoo) {
    csv2 <- csvdata
    colnames(csv2) <- sub("Accelerometer ", "", colnames(csv2))
    csv2[214100:214101, ]
    csv2 <- fzero(csv2)
    csv2[214100:214101, ]
    gt3xdata_full <- fzero(gt3xdata_full)
    gt3xdata_full <- gt3xdata_full[, c("X", "Y", "Z")]
    gt3xdata_full <- as.matrix(gt3xdata_full)
    d <- abs(csv2 - gt3xdata_full)
    bad <- rowSums(d > 1e-8) > 0
    testthat::expect_true(!any(bad))
  }
})

testthat::test_that("No lags in gt3x data.frame timestamps after imputation", {
  gt3xdf <- as.data.frame(gt3xdataZeroes)
  diffs <- diff(gt3xdf$time)
  testthat::expect_true(!any(diffs > 1))
})


testthat::test_that("Number of missing values correctly attributed", {
  nmis <-   sum(attr(gt3xdata, "missingness")$n_missing)
  testthat::expect_true(nrow(gt3xdata) + nmis == nrow(csvdata))
})

testthat::test_that("Removing the gt3x works fine", {
  testthat::expect_true(file.exists(tfile))
  res <- unzip_single_gt3x(tfile, remove_original = TRUE, verbose = TRUE)
  testthat::expect_is(res, "character")
  testthat::expect_false(file.exists(tfile))
  tfile2 <- tempfile()
  res <- unzip_single_gt3x(tfile2)
  testthat::expect_null(res)

  testthat::expect_message({
    res <- unzip_single_gt3x(NULL)
  }, "Unzipping faile")
  testthat::expect_null(res)
})

gt3xdata_full_no_zeroes <- read.gt3x(gt3xfile, asDataFrame = TRUE)
gt3xdata_one_record_batch <- read.gt3x(gt3xfile, asDataFrame = TRUE,
                                       batch_begin=1, batch_end=1)

testthat::test_that("read.gt3x reads a single record batch correctly", {
  testthat::expect_true(nrow(gt3xdata_one_record_batch) == 100)
  testthat::expect_true(all(gt3xdata_one_record_batch[1:100,] == gt3xdata_full_no_zeroes[1:100,]))
})


gt3xdata_forget_batch_end <- read.gt3x(gt3xfile, asDataFrame = TRUE, batch_begin=100)

testthat::test_that("read.gt3x reads entire file when forgetting to set batch_end", {
  testthat::expect_equal(nrow(gt3xdata_forget_batch_end), 33000)
})

gt3xdata_forget_batch_begin <- read.gt3x(gt3xfile, asDataFrame = TRUE, batch_end=2)

testthat::test_that("read.gt3x reads from batch 0 when forgetting to set batch_begin", {
  testthat::expect_equal(nrow(gt3xdata_forget_batch_begin), 200)
})

gt3xdata_bigger_batch <- read.gt3x(gt3xfile, asDataFrame = TRUE,
                                   batch_begin=11, batch_end=20)

testthat::test_that("read.gt3x reads a bigger batch from somewhere in the file correctly", {
  testthat::expect_true(nrow(gt3xdata_bigger_batch) == 1000)
  testthat::expect_true(all(gt3xdata_bigger_batch[1:100,] == gt3xdata_full_no_zeroes[1001:1100,]))
})

batch_size <- nrow(gt3xdata_one_record_batch)
total_rows <- nrow(gt3xdata_full_no_zeroes)
n_batches <- total_rows %/% batch_size
gt3xdata_last_batch <- read.gt3x(gt3xfile, asDataFrame = TRUE,
                                 batch_begin=n_batches, batch_end=n_batches)

testthat::test_that("read.gt3x reads a batch at the end of the file correctly", {
  testthat::expect_true(all(gt3xdata_last_batch[1:100,] == gt3xdata_full_no_zeroes[(batch_size*(n_batches-1) + 1):(batch_size*(n_batches-1)+100),]))
})

# Batching doesn't work well with impute_zeros yet; that option automatically
# makes the dataframe size the full size, which doesn't make sense for batching.
# Also, the batch counter currently only counts non-empty records, so comparing
# to a dataframe with impute_zeros (like gt3xdata_full) has to be done on a row
# by row basis, avoiding the zeroed rows.
# Therefore, for the time being, imputing zeroes is disabled when using
# batching, as confirmed by the following test:

gt3xdata_batch_impute <- read.gt3x(gt3xfile, asDataFrame = TRUE, imputeZeroes=TRUE,
                                   batch_begin = 11, batch_end = 20)

testthat::test_that("read.gt3x disables imputing zeroes when using batching", {
  testthat::expect_true(nrow(gt3xdata_batch_impute) == nrow(gt3xdata_bigger_batch))
  testthat::expect_true(all(gt3xdata_bigger_batch[1:100,] == gt3xdata_batch_impute[1:100,]))
})
