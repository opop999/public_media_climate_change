# Load necessary libraries
library(quanteda)
library(tidyr)
library(dplyr)
library(stringr)
library(purrr)
library(wordcloud)

kwic_pattern <- "(klima)|(globální oteplování)" # Specify pattern, could be in regex
max_words_context <- 5 # Size of the window
context_direction <- c("pre_word", "post_word") # Window direction
sub_pattern <- ".*"  # Specify if you only want documents that contain certain terms in the kwic context, for all select ".*"

# Put the udpipe lemmatized chunks together to one
udpipe_processed_df <- list.files(path = "path-to-udpipe-chunks",
                                  pattern = "*.rds",
                                  full.names = TRUE) %>%
  .[grepl("2015-(10|11|12)", .)] %>% # Do you only want certain periods to be included? Comment out this line otherwise.
  map_dfr(readRDS)

# Process to a format usable with Quanteda's kwic function
txt <- udpipe_processed_df %>%
  filter(upos %in% c("VERB", "NOUN", "ADJ", "PROPN")) %>%
  mutate(word = tolower(str_replace_na(lemma, replacement = ""))) %>% # Select token or lemma for different results
  group_by(doc_id) %>%
  summarize(tokenized_text = str_squish(str_c(word, collapse = " "))) %>%
  ungroup() %>%
  corpus(docid_field = "doc_id", text_field = "tokenized_text") %>%
  tokens(remove_punct = TRUE,
         remove_numbers = TRUE,
         padding = FALSE,
         remove_symbols = TRUE)

# Concordances with our search pattern
kwics <- kwic(
  txt,
  window = 5,
  pattern = kwic_pattern,
  valuetype = "regex"
) %>%
  filter(str_detect(pre, sub_pattern) | str_detect(post, sub_pattern)) %>%  # Further filter by a pattern of interest around the keyword
  as_tibble() %>%
  # Get maximum number of words in pre and post columns, but not more than is specified by "max_words_context"
  # If using just word() function, NAs are intruduced where selected number of words exceed existing number of words
  # for this reason, we use a nested if_else statement to deal with exceptions.
  mutate(
    pre_word = word(pre,
                    start = if_else(
                      if_else(
                        -str_count(pre, pattern = "\\S+") == 0,
                        -1,
                        as.double(-str_count(pre, pattern = "\\S+"))
                      ) < -max_words_context,
                      -max_words_context,
                      if_else(-str_count(pre, pattern = "\\S+") == 0,
                              -1,
                              as.double(-str_count(pre, pattern = "\\S+"))
                      )
                    ),
                    end = -1
    ),
    post_word = word(post, start = 1, end = if_else(
      if_else(
        -str_count(post, pattern = "\\S+") == 0,
        -1,
        as.double(-str_count(post, pattern = "\\S+"))
      ) < max_words_context,
      max_words_context,
      if_else(-str_count(post, pattern = "\\S+") == 0,
              -1,
              as.double(-str_count(post, pattern = "\\S+"))
      )
    ))
  )

# Wordcloud of all of the pre & post words: Automatically splits multi-word token elements
kwics %>%
  unite(all_context, all_of(context_direction), sep = " ") %>%
  pull(all_context) %>%
  strsplit(., split = " ") %>%
  unlist() %>%
  tibble(word = .) %>%
  count(word, sort = TRUE) %>%
  filter(!is.na(word)) %>%
  with(wordcloud(word, n, min.freq = 500, random.order = FALSE, max.words = 100, colors = brewer.pal(8, "Dark2")))

