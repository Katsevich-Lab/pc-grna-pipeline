#!/usr/bin/env Rscript
sceptre2_dir <- paste0(.get_config_path("LOCAL_SCEPTRE2_DATA_DIR"), "data/")

# Get CL args
args <- commandArgs(trailingOnly = TRUE)
trial <- as.logical(args[1])
pairs_to_analyze_file <- args[2]
datasets <- args[seq(4, length(args))] |> unique()

# loop over datasets, outputting the positive control pairs
out <- NULL
for (i in seq(1, length(datasets))) {
  dataset_name <- datasets[i]
  df <- readRDS(paste0(sceptre2_dir, dataset_name, "/tf_pairs_grouped.rds"))
  n_grnas <- length(unique(df$grna_group))
  my_idxs <- seq(1L, n_grnas)
  out <- c(out, paste(dataset_name, if (trial) 1L else my_idxs))
}

# write to disk
file_con <- file("dataset_names_raw.txt")
writeLines(out, file_con)
close(file_con)
