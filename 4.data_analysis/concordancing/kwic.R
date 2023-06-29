# Load necessary libraries
packages <-
  c(
    "dplyr",
    "stringr",
    "purrr",
    "tidyr",
    "quanteda",
    "wordcloud"
  )

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))


# Values to adjust --------------------------------------------------------

path_to_udpipe_chunks <- "2.data_transformations/data/udpipe_processed"
# Specify pattern, could be in regex. Here we try to ensure that the words are matched exactly, which means they are either at the beginning "^" or end "$" of the sentence or they have non-letter characters around them "\W" : (?<=^|\\W)(klima|oteplování)(?=$|\\W)
# This string can also be modifies for bigrams etc.
# Fixed is most useful for lemmatized version, while regex for tokenized version of the text
lemma_or_token <- "token" # lemma / token
kwic_pattern_type <- "regex" # fixed / regex
# This pattern is work in progress! We can specify which stems get matched and which will not (like "klimatiz*")
kwic_pattern_list <- list("regex" = "\\b((?!klimatiz\\S+\\b)(klima\\S*|globáln\\S+\\soteplov\\S+|skleníkov\\S+\\sefekt\\S*|uhlíkov\\S+\\sstop\\S+))\\b",
                          "fixed" = phrase(c("klima", "globální oteplování", "skleníkový efekt", "uhlíková stopa")))

max_words_context <- 5 # Size of the window
context_direction <- c("pre", "post") # Names of resulting pre/post context columns for wordcloud direction. You can also just compare one.
upos_filter <- c("VERB", "NOUN", "ADJ", "PROPN", "PUNCT") # Fewer UPOS speeds up calculations, but also lowers the interpretability
# sub_pattern <- ".*"  # Uncomment and specify if you only want documents that contain certain terms in the kwic context, for all select ".*"

# Put the udpipe lemmatized chunks together to one
udpipe_processed_df <- list.files(path = path_to_udpipe_chunks,
                                  pattern = "*.rds",
                                  full.names = TRUE) %>%
  # .[grepl("2015-(10|11|12)", .)] %>% # Do you only want certain periods to be included? Comment out this line otherwise.
  map(~filter(readRDS(.x), upos %in% upos_filter) %>%
        select(c("doc_id", "sentence_id", !!sym(lemma_or_token)))) %>%
  bind_rows() # Reading each chunk from the list while keeping only columns of interest

# -------------------------------------------------------------------------

# Process to a format usable with Quanteda's kwic function
txt <- udpipe_processed_df %>%
  mutate(word = tolower(str_replace_na(!!sym(lemma_or_token), replacement = ""))) %>% # Select token or lemma for different results
  group_by(doc_id) %>% # Aggregate lemma to the level of individual texts. This could be also modified to individual sentences.
  summarize(tokenized_text = str_squish(str_c(word, collapse = " "))) %>%
  ungroup() %>%
  corpus(docid_field = "doc_id", text_field = "tokenized_text") %>%
  tokens(remove_punct = FALSE,
         remove_numbers = TRUE,
         padding = TRUE,
         remove_symbols = TRUE)
# -------------------------------------------------------------------------

# Concordances with our search pattern
kwics <- kwic(
  txt,
  window = max_words_context,
  pattern = kwic_pattern_list[[kwic_pattern_type]],
  valuetype = kwic_pattern_type
) %>%
  # filter(str_detect(pre, sub_pattern) | str_detect(post, sub_pattern)) %>% # Uncomment for further filter by a pattern of interest around the keyword
  as_tibble()


# -------------------------------------------------------------------------

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







