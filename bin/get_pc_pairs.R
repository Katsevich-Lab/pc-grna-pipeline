#!/usr/bin/env Rscript
sceptre2_dir <- paste0(.get_config_path("LOCAL_SCEPTRE2_DATA_DIR"), "data/")

# Get CL args
args <- commandArgs(trailingOnly = TRUE)
trial <- as.logical(args[1])
grouped <- as.logical(args[2])
datasets <- args[seq(3, length(args))] |> unique()

# loop over datasets, outputting the positive control pairs
out <- NULL
for (i in seq(1, length(datasets))) {
  grna_dataset_name <- lowmoi::get_grna_dataset_name(dataset_name, grna_modality)
  grna_odm <- lowmoi::load_dataset_modality(grna_dataset_name)
  grna_feature_covariates <- grna_odm |> get_feature_covariates()
  dataset_name <- datasets[i]
  
  if (grouped) {
    ok_grna_groups <- grna_feature_covariates |>
      dplyr::group_by(target) |>
      dplyr::summarize(n_nonzero = sum(n_nonzero)) |>
      dplyr::filter(n_nonzero >= 10) |>
      dplyr::pull(target)
  
    pos_control_df <- readRDS(paste0(sceptre2_dir,
                                     dataset_name,
                                     "/pos_control_pairs_grouped.rds")) |>
      dplyr::filter(grna_group %in% ok_grna_groups)
    
  } else {
    ok_grna_ids <- grna_feature_covariates |>
      tibble::rownames_to_column(var = "grna_id") |>
      dplyr::filter(n_nonzero >= 10) |>
      dplyr::pull(grna_id)
    
    pos_control_df <- readRDS(paste0(sceptre2_dir,
                                     dataset_name,
                                     "/pos_control_pairs_single.rds")) |>
      dplyr::filter(grna_id %in% ok_grna_ids)
  }
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
