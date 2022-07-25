source(file.path("get_full_articles_individual_new_api.R"))

# Create empty list to which we will append with every API call
additional_full_articles_list <- vector(mode = "list", length = nrow(missing_annotations_df))

# Loop over the dataset with annotations of missing full articles
for (i in seq_len(nrow(missing_annotations_df))) {
  additional_full_articles_list[[i]] <- extract_full_articles_individual_new_api(
    article_code = missing_annotations_df$code[[i]],
    date_published = missing_annotations_df$datePublished[[i]],
    search_history_id = missing_annotations_df$searchHistoryId[[i]],
    newton_api_token = Sys.getenv("NEWTON_TOKEN"),
    log = FALSE,
    log_path = ""
  )

  # Random wait time as not to overwhelm the API
  pause <- runif(1, 0.02, 0.1)
  cat("\nAPI call", i, "for article id", missing_annotations_df$code[[i]], "executed. \nPausing for", pause, "seconds.\n==============\n")
  Sys.sleep(pause)

  # Longer pause and save checkpoint
  if (i %% 5000 == 0) {
    cat("\nAfter 10000 calls: Pausing for 60 seconds.\n")
    Sys.sleep(60)
    gc()
    saveRDS(additional_full_articles_list, paste0("data/data_validity/checkpoint_", i, "_additional_full_articles.rds"))
  }
}

saveRDS(additional_full_articles_list, "data/data_validity/final_additional_full_articles.rds")










