# This script extracts annotated articles from a list of missing identifiers.
# It sources the function to extract a single annotated article from the file "get_single_annotated_article.R".
# An empty list is created to store missing annotations.
# The script loops through each missing identifier and extracts the annotated article using the search string and other parameters.
# A random wait time is added to avoid overwhelming the API.
# A message is printed indicating the API call has been executed and the pause time.
# A longer pause and save checkpoint is added every 5000 calls.
# The final missing annotations list is saved.
# Source the function to extract a single annotated article
source(file.path("get_single_annotated_article.R"))

# Create an empty list to store missing annotations
missing_annotations_list <- vector(mode = "list", length = nrow(missing_identifier))

# Loop through each missing identifier
for (i in seq_along(missing_identifier$Code)) {

  # Extract the annotated article using the search string and other parameters
  missing_annotations_list[[i]] <- extract_annotated_article(search_string = missing_identifier$Content[[i]],
                                                             page_size = 10,
                                                             search_in_title = FALSE,
                                                             doc_id = missing_identifier$Code[[i]],
                                                             media_history_id = missing_identifier$history_id[[i]],
                                                             min_date = missing_identifier$PublishDate[[i]],
                                                             max_date = missing_identifier$PublishDate[[i]],
                                                             newton_api_token = Sys.getenv("NEWTON_TOKEN"),
                                                             log = FALSE)
  # Random wait time as not to overwhelm the API
  pause <- runif(1, 0.02, 0.1)
  
  # Print a message indicating the API call has been executed and the pause time
  cat("\nAPI call", i, "for article id", missing_identifier$Code[[i]], "executed. \nPausing for", pause, "seconds.\n==============\n")
  
  # Pause for the random wait time
  Sys.sleep(pause)

  # Longer pause and save checkpoint every 5000 calls
  if (i %% 5000 == 0) {
    cat("\nAfter 5000 calls: Pausing for 60 seconds.\n")
    Sys.sleep(60)
    gc()
    saveRDS(missing_annotations_list, paste0("data/data_validity/checkpoint_", i, "_missing_annotations_list.rds"))
  }

}

# Save the final missing annotations list
saveRDS(missing_annotations_list, "data/data_validity/final_missing_annotations_list.rds")
