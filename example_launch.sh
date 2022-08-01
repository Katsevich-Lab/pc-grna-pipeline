source ~/.research_config

nextflow run $LOCAL_CODE_DIR"/pc-grna-pipeline/main.nf" \
 --data_method_pair_file $LOCAL_CODE_DIR"/sceptre2-manuscript/param_files/data_method_pairs_pc.groovy" \
 --grna_modality "assignment" \
 --trial "true" \
 -resume
