# This script reads in regex chunks of text data, processes them using the udpipe_process function from udpipe_api_process.R,
# saves the resulting udpipe data frames locally, and pauses for approximately 10 minutes between chunks. 

source(file.path("udpipe_api_process.R"))

for (regex_file in all_regex_chunks) {

  one_chunk <- readRDS(regex_file)

  udpipe_df_chunk <- udpipe_process(article_id = one_chunk$article_id,
                                    article_text = one_chunk$text,
                                    log_path = file.path("docs/"),
                                    log = FALSE)

  saveRDS(udpipe_df_chunk, paste0(file.path("data", "udpipe_processed", "udpipe_"), basename(regex_file)))

  rm(udpipe_df_chunk, one_chunk)

  gc()

  cat("\nThe following chunk was processed by UDPIPE and saved locally:", basename(regex_file), "\n")

  # Pause ~10 mins between chunks
  Sys.sleep(abs(rnorm(1, 600, sd = 100)))

}
