library(tidyverse)

options <- commandArgs(trailingOnly = TRUE)

outdir <- options[1]

if (!dir.exists(outdir)){
	dir.create(outdir)
}


results <- file.path(outdir, "results.rds") %>% readRDS(.)

results_gbm <- results$results_gbm
results_xgb_shap <- results$results_xgb_shap
results_xgb_gain <- results$results_xgb_gain
varimp_store_gbm <- results$varimp_store_gbm
varimp_store_xgb_gain <- results$varimp_store_xgb_gain
varimp_store_xgb_shap <- results$varimp_store_xgb_shap


true_names <- "tremors-paper-var-names.csv" %>% read_csv() %>% select(2,3)

varimp_store_gbm <- lapply(varimp_store_gbm, function(x) x %>% left_join(true_names, by=c("var"="new_names")) %>% select(-var) %>% relocate(Overall, proper_names, id, s) %>% magrittr::set_colnames(c("Overall", "var", "id", "s")))

varimp_store_xgb_gain <- lapply(varimp_store_xgb_gain, function(x) x %>% left_join(true_names, by=c("var"="new_names")) %>% select(-var) %>% relocate(Overall, proper_names, id, s) %>% magrittr::set_colnames(c("Overall", "var", "id", "s")))


varimp_store_xgb_shap <- lapply(varimp_store_xgb_shap, function(x) x %>% left_join(true_names, by=c("var"="new_names")) %>% select(-var) %>% relocate(mean_abs_shap, proper_names, id) %>% magrittr::set_colnames(c("mean_abs_shap", "var", "id")))



init_gbm <- varimp_store_gbm[[1]] %>% select(var, s)
init_xgb_shap <- varimp_store_xgb_shap[[1]] %>% select(var, mean_abs_shap)
init_xgb_gain <- varimp_store_xgb_gain[[1]] %>% select(var, s)

all_names <- read_csv(file.path(outdir, "merged.csv")) %>% select(-status) %>% colnames()

allvars <- data.frame(varnames = all_names) %>% left_join(true_names, by=c("varnames" = "new_names")) %>% as_tibble()

data <- allvars

integrate_data <- function(allvars, df){
	vctr <- allvars %>% left_join(df, by=c("proper_names"="var")) %>% pull(3)

	vctr[is.na(vctr)] <- 0

	vctr
}


data$gbm_pct_imp <- integrate_data(allvars, init_gbm)
data$xgb_shap_val <- integrate_data(allvars, init_xgb_shap)
data$xgb_gain_pct_imp <- integrate_data(allvars, init_xgb_gain)

data %>% select(2:5) %>% arrange(desc(gbm_pct_imp)) %>% magrittr::set_colnames(c("Symptom", "GBM Percent Importance", "XGB Mean Absolute Shapley Value", "XGB Gain Percent Importance")) %>% writexl::write_xlsx(., file.path(outdir, "initial-sx-importances.xlsx")) 











