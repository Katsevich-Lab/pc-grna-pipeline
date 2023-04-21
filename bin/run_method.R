#!/usr/bin/env Rscript
sceptre2_dir <- paste0(.get_config_path("LOCAL_SCEPTRE2_DATA_DIR"), "data/")

# Get CL args; set sceptre2 offsite dir
args <- commandArgs(trailingOnly = TRUE)
dataset_name <- args[1]
idx <- as.integer(args[2])
method_name <- args[3]
grna_modality <- args[4]
pairs_file <- args[5]
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
response_grna_group_pairs <- readRDS(paste0(sceptre2_dir, dataset_name, "/", pairs_file))

# if idx > 0, slice the response grna group pairs accordingly
if (idx > 0) {
  unique_grna_groups <- response_grna_group_pairs$grna_group |> unique()
  curr_grna_group <- as.character(unique_grna_groups[idx])
  response_grna_group_pairs <- response_grna_group_pairs |> dplyr::filter(grna_group == curr_grna_group)
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
