source(file.path("get_single_annotated_article.R"))

missing_annotations_list <- vector(mode = "list", length = nrow(missing_identifier))

for (i in seq_along(missing_identifier$Code)) {

  missing_annotations_list[[i]] <- extract_annotated_article(search_string = missing_identifier$Title[[i]],
                                                             page_size = 1,
                                                             doc_id = missing_identifier$Code[[i]],
                                                             media_history_id = missing_identifier$history_id[[i]],
                                                             min_date = missing_identifier$PublishDate[[i]],
                                                             max_date = missing_identifier$PublishDate[[i]],
                                                             newton_api_token = Sys.getenv("NEWTON_TOKEN"),
                                                             log = FALSE)
  # Random wait time as not to overwhelm the API
  pause <- runif(1, 0.02, 0.1)
  cat("\nAPI call", i, "for article id", missing_identifier$Code[[i]], "executed. \nPausing for", pause, "seconds.\n==============\n")
  Sys.sleep(pause)

  # Longer pause and save checkpoint
  if (i %% 10000 == 0) {
    cat("\nAfter 10000 calls: Pausing for 600 seconds.\n")
    Sys.sleep(600)
    gc()
    saveRDS(missing_annotations_list, paste0("data/data_validity/checkpoint_", i, "_missing_annotations_list.rds"))
  }

}

saveRDS(missing_annotations_list, "data/data_validity/final_missing_annotations_list.rds")
