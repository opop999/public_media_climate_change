# Load necessary libraries
packages <-
  c(
    "stringr",
    "purrr",
    "tidyr",
    "quanteda",
    "wordcloud",
    "parallel",
    "data.table",
    "dtplyr",
    "dplyr"
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

list_of_udpipe_chunks <- list.files(path = path_to_udpipe_chunks,
                                    pattern = "*.rds",
                                    full.names = TRUE) # %>%
# .[grepl("2015-(10|11|12)", .)] %>% # Do you only want certain time periods to be included? Comment out this line otherwise.

# Specify pattern in regex.
lemma_or_token <- "token" # lemma / token
lowercase <- FALSE

kwic_pattern_regex <- list(climate = c(key_word = phrase(c("\\bklima\\S*")),
                                       filter_main = "klimatiz\\S+|klimatolo\\S+",
                                       filter_pre = "(společensk\\S+|politick\\S+)$",
                                       filter_post = "^ve společnost\\S+"),
                        global_warming = c(key_word = phrase(c("\\bglobáln\\S+ oteplován\\S+")),
                                           filter_main = NA,
                                           filter_pre = NA,
                                           filter_post = NA),
                        greenhouse_effect = c(key_word = phrase(c("\\bskleníkov\\S+ efekt\\S*")),
                                              filter_main = NA,
                                              filter_pre = NA,
                                              filter_post = NA),
                        carbon_footprint = c(key_word = phrase(c("\\buhlíkov\\S+ stop\\S+")),
                                             filter_main = NA,
                                             filter_pre = NA,
                                             filter_post = NA))

max_words_context <- 5 # Size of the window in which concordances will be found.
# Fewer UPOS speeds up calculations, but also lowers the interpretability.
upos_filter <-
  c(
    "VERB",
    "NOUN",
    "ADJ",
    "PROPN",
    "PUNCT",
    "ADV",
    "NUM",
    "ADP",
    "AUX",
    "PRON",
    "CCONJ",
    "SCONJ",
    "INTJ",
    "DET",
    "PART"
  )
context_direction <- c("pre", "post") # Names of resulting pre/post context columns for wordcloud direction. You can also just compare one.

get_kwics <- function(udpipe_chunk) {

  # We use DTPLYR for faster worflow.
  corpus_chunk <- udpipe_chunk %>%
    readRDS() %>%
    lazy_dt() %>%
    filter(upos %in% upos_filter) %>%
    mutate(doc_id,
           sentence_id,
           # Select token or lemma for different results
           word = str_replace_na(!!sym(lemma_or_token), replacement = ""),
           .keep = "none") %>%
    {if(lowercase) mutate(., word = tolower(word)) else .} %>%
    # Aggregate lemma to the level of individual texts.
    group_by(doc_id) %>%
    summarize(tokenized_text = str_squish(str_c(word, collapse = " "))) %>%
    ungroup() %>%
    as_tibble() %>%
    corpus(docid_field = "doc_id", text_field = "tokenized_text") %>%
    tokens()

concordance_key_words <- function(term_of_interest) {

  kwic_single_term <- quanteda::kwic(
    x = corpus_chunk,
    window = max_words_context,
    pattern = term_of_interest["key_word"],
    valuetype = "regex",
    case_insensitive = !lowercase
  )  %>%
    as_tibble()  %>%
    {if(!is.na(term_of_interest[["filter_main"]])) filter(., str_detect(.$keyword, regex(term_of_interest[["filter_main"]], ignore_case = !lowercase), negate = TRUE)) else .} %>%
    {if(!is.na(term_of_interest[["filter_pre"]])) filter(., str_detect(.$pre, regex(term_of_interest[["filter_pre"]], ignore_case = !lowercase), negate = TRUE)) else .} %>%
    {if(!is.na(term_of_interest[["filter_post"]])) filter(., str_detect(.$post, regex(term_of_interest[["filter_post"]], ignore_case = !lowercase), negate = TRUE)) else .}

}

kwic_chunk_combined <- lapply(kwic_pattern_regex, concordance_key_words) %>% bind_rows()

  print(paste("Chunk", udpipe_chunk, "finished concordancing."))

  return(kwic_chunk_combined)
}


# If we are using Linux or MacOS, we can use multiple CPUs to make the whole
# process much faster. Each core handles different chunk at the same time.

if (Sys.info()[['sysname']] == "Windows") {
  # Use normal apply with windows
  kwic_df_full <-
    lapply(list_of_udpipe_chunks, get_kwics) %>% bind_rows()

} else {
  kwic_df_full <-
    mclapply(list_of_udpipe_chunks, get_kwics, mc.cores = detectCores() - 2) %>% bind_rows()
}

# Wordcloud of all of the pre & post words: Automatically splits multi-word token elements
kwic_df_full %>%
  unite(all_context, all_of(context_direction), sep = " ") %>%
  pull(all_context) %>%
  strsplit(., split = " ") %>%
  unlist() %>%
  tibble(word = .) %>%
  count(word, sort = TRUE) %>%
  filter(!is.na(word)) %>%
  with(wordcloud(word, n, min.freq = 500, random.order = FALSE, max.words = 100, colors = brewer.pal(8, "Dark2")))


