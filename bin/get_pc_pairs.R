#!/usr/bin/env Rscript
sceptre2_dir <- paste0(.get_config_path("LOCAL_SCEPTRE2_DATA_DIR"), "data/")

# Get CL args
args <- commandArgs(trailingOnly = TRUE)
trial <- as.logical(args[1])
datasets <- args[seq(2, length(args))]|> unique()

# loop over datasets, outputting the positive control pairs
out <- NULL
for (i in seq(1, length(datasets))) {
  dataset_name <- datasets[i]
  pos_control_df <- readRDS(paste0(sceptre2_dir, sub("/[^/]*$", "", dataset_name), "/pos_control_pairs.rds"))
  my_idxs <- seq(1L, nrow(pos_control_df))
  if (trial) {
    out <- c(out, paste(dataset_name, 1L))
  } else {
    out <- c(out, paste(dataset_name, my_idxs))
  }
}

# write to disk
file_con <- file("dataset_names_raw.txt")
writeLines(out, file_con)
close(file_con)
