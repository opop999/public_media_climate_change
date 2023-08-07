# This script reads in preprocessed text data in chunks, processes each chunk using the NameTag API for named entity recognition,
# and saves the resulting dataframes locally. The script pauses for approximately 10 minutes between each chunk to avoid overloading the API.
# The resulting dataframes can be used for further analysis of named entities in the text data.
source(file.path("ner_nametag_api.R"))

for (ner_file in all_chunks_path_ner) {

  one_chunk <- readRDS(ner_file)

  nametag_df_chunk <- nametag_process(article_id = one_chunk$article_id,
                                      article_text = one_chunk$text,
                                      log = FALSE)

  saveRDS(nametag_df_chunk, paste0(file.path("data", "nametag_") , basename(ner_file)))

  rm(nametag_df_chunk, one_chunk)
  gc()

  cat("\nThe following chunk was processed by NameTag and saved locally:", basename(ner_file), "\n")

  # Pause cca 10 mins between chunks
  Sys.sleep(abs(rnorm(1, 600, sd = 100)))

}
