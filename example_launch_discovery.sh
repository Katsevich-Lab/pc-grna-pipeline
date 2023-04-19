source ~/.research_config

nextflow run $LOCAL_CODE_DIR"/pc-grna-pipeline/main.nf" \
 --data_method_pair_file $LOCAL_CODE_DIR"/sceptre2-manuscript/param_files/params_discovery_0423.groovy" \
 --grna_modality "assignment" \
 --result_dir $LOCAL_SCEPTRE2_DATA_DIR"/results/discovery_analyses" \
 --result_file_name "discovery_results_0423.rds" \
 --trial "false" \
 --discovery "true"