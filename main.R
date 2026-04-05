rm(list = ls())
message("Starting Pipeline...")


source("R/01_setup.R")
source("R/02_data_preparation.R")
source("R/03_modeling.R")
source("R/04_evaluation.R")
source("R/05_visualization.R")

message("SuCCESS: full pipeline finished.")
message("results in 'outputs/' folder")