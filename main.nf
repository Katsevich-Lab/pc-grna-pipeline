params.result_dir = "$PWD"
params.result_file_name = "pc_results.rds"
params.trial = "false"
params.grouped = "true"

// STEP 0: Determine the dataset-method pairs; put the dataset method pairs into a map, and put the datasets into an array
GroovyShell shell = new GroovyShell()
evaluate(new File(params.data_method_pair_file))
def data_method_pairs_list_indiv = []
def data_method_pairs_list_grouped = []
data_list_str = ""

for (entry in data_method_pairs_indiv) {
  data_list_str += " " + entry.key
  for (value in entry.value) {
      data_method_pairs_list_indiv << [entry.key, value]
  }
}
for (entry in data_method_pairs_grouped) {
  data_list_str += " " + entry.key
  for (value in entry.value) {
    data_method_pairs_list_grouped << [entry.key, value]
  }
}

// Create channels
data_method_pairs_ch_indiv = Channel.from(data_method_pairs_list_indiv)
data_method_pairs_ch_grouped = Channel.from(data_method_pairs_list_grouped)

// Define the get_matrix_entry function
def get_matrix_entry(data_method_ram_matrix, row_names, col_names, my_row_name, my_col_name) {
  row_idx = row_names.findIndexOf{ it == my_row_name }
  col_idx = col_names.findIndexOf{ it == my_col_name }
  return data_method_ram_matrix[row_idx][col_idx]
}

// Define the get_vector_entry function
def get_vector_entry(vector, col_names, my_col_name) {
  idx = col_names.findIndexOf{ it == my_col_name }
  return vector[idx]
}


// PROCESS 1: obtain
process obtain_pc_pairs {
  debug true

  queue "short.q"
  memory "2 GB"

  output:
  path 'dataset_names_raw.txt'

  """
  get_pc_pairs.R ${params.trial} ${params.grouped} $data_list_str
  """
}


process run_method {
  debug true

  queue "$queue"
  // memory "$ram GB"

  tag "$dataset+$method"

  //output:
  //file 'raw_result.rds'

  input:
  tuple val(dataset), val(idx), val(method), val(queue), val(ram), val(opt_args)

  // """
  // run_method.R $dataset $idx $method ${params.grna_modality} ${params.grouped} $opt_args
  // """

  // """
  // echo $dataset $idx $method ${params.grna_modality} ${params.grouped} $opt_args
  // """

  """
  echo $dataset $idx $method ${params.grna_modality} ${params.grouped} $opt_args
  """
}


process combine_results {
  queue 'short.q'
  publishDir params.result_dir, mode: 'copy'

  output:
  file "$params.result_file_name"

  input:
  file 'raw_result'

  """
  collect_results.R $params.result_file_name raw_result*
  """
}


workflow {
  // step 0: get datasets and indexes
  obtain_pc_pairs()

  dataset_names_raw_ch = obtain_pc_pairs.out
  dataset_idx_pairs = dataset_names_raw_ch.splitText().map{it.trim().split(" ")}.map{[it[0], it[1]]}
  dataset_no_idx = dataset_idx_pairs.unique({it[0]}).map{[it[0], 0]}

  // step 1: combine with the methods
  data_method_pairs_indiv_tuples = dataset_idx_pairs.combine(data_method_pairs_ch_indiv, by: 0).map{
    [it[0], // dataset
    it[1], // idx
    it[2], // method
    get_matrix_entry(data_method_queue_matrix, row_names, col_names, it[0], it[2]), // queue
    get_matrix_entry(data_method_ram_matrix, row_names, col_names, it[0], it[2]), // RAM
    get_vector_entry(optional_args, col_names, it[2])] // optional args
  }
  data_method_pair_grouped_tuples = dataset_no_idx.combine(data_method_pairs_ch_grouped, by: 0).map{
    [it[0], // dataset
    it[1], // idx
    it[2], // method
    get_matrix_entry(data_method_queue_matrix, row_names, col_names, it[0], it[2]), // queue
    get_matrix_entry(data_method_ram_matrix, row_names, col_names, it[0], it[2]), // RAM
    get_vector_entry(optional_args, col_names, it[2])] // optional args
  }

  method_input = data_method_pairs_indiv_tuples.mix(data_method_pair_grouped_tuples)

  // step 2: run method
  run_method(method_input)


  // step 3: combine results
  // raw_results = run_method.out.collect()
  // combine_results(raw_results)
}
