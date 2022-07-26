#!/usr/bin/env Rscript
sceptre2_dir <- paste0(.get_config_path("LOCAL_SCEPTRE2_DATA_DIR"), "data/")

# Get CL args; set sceptre2 offsite dir
args <- commandArgs(trailingOnly = TRUE)
dataset_name <- args[1]
idx <- as.integer(args[2])
method_name <- args[3]
grna_modality <- args[4]
grouped <- as.logical(args[5])
if (length(args) >= 6) {
  optional_args <- args[seq(6, length(args))]
} else {
  optional_args <- NULL
}

# Load packages
library(ondisc)
library(lowmoi)

# read response matrix and grna expression matrix
response_odm <- load_dataset_modality(dataset_name)
grna_dataset_name <- get_grna_dataset_name(dataset_name, grna_modality)
grna_odm <- load_dataset_modality(grna_dataset_name)
# update the gene-grna groups and grna ODM, if running a singleton experiment

if (grouped) {
  response_grna_group_pairs <- readRDS(paste0(sceptre2_dir, dataset_name, "/pos_control_pairs_grouped.rds"))
} else {
  response_grna_group_pairs <- readRDS(paste0(sceptre2_dir, dataset_name, "/pos_control_pairs_single.rds"))
  curr_targets <- grna_odm@feature_covariates$target
  curr_ids <- row.names(grna_odm@feature_covariates)
  curr_ids[curr_targets == "non-targeting"] <- "non-targeting"
  grna_odm@feature_covariates$target <- curr_ids
  response_grna_group_pairs <- response_grna_group_pairs |> dplyr::rename("grna_group" = "grna_id")
  row.names(grna_odm) <- NULL
}

# if idx > 0, slice the response grna group pairs accordingly
if (idx > 0) {
  response_grna_group_pairs <- response_grna_group_pairs |> dplyr::slice(idx)
}

# add additional args
to_pass_list <- list(response_odm = response_odm,
                     grna_odm = grna_odm,
                     response_grna_group_pairs = response_grna_group_pairs)
if (!is.null(optional_args)) { # if there are optional arguments specified, add them to the list
  optional_args <- strsplit(x = optional_args, split = ":") |> unlist()
  values_vect <- NULL
  names_vect <- NULL
  for (str in optional_args) {
    str_split <- strsplit(x = str, split = "=", fixed = TRUE)[[1]]
    values_vect <- c(values_vect, str_split[2])
    names_vect <- c(names_vect, str_split[1])
  }
  to_append_list <- purrr::set_names(as.list(values_vect), names_vect)
  to_pass_list <- c(to_pass_list, to_append_list)
}

result_df <- do.call(what = method_name, args = to_pass_list)

if (!identical(sort(colnames(result_df)), c("grna_group", "p_value", "response_id"))) {
  stop(paste0("The output of `", method_name, "` must be a data frame with columns `response_id`, `grna_group`, and `p_value`."))
}

# add columns indicating the undercover grna, dataset name, and method name
out <- result_df |>
  dplyr::mutate(dataset = dataset_name, method = method_name) |>
  dplyr::mutate_at(.vars = c("response_id", "grna_group", "dataset", "method"), .funs = factor)

# save result
saveRDS(object = out, file = "raw_result.rds")
