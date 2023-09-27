library(dplyr)
library(tidyr)
library(stringr)

# Load the stopwords
stop_words_cs <- read_lines("StopwordsCS.txt")
stop_words_czech_television <- read_lines("StopwordsCTV.txt")

# Create a list of corpus names
corpus_names <- c()
for (year in 2012:2022) {
  if (year == 2022) {
    corpus_names <- c(corpus_names, paste0("Corpus", year - 2000, "_", sprintf("%02d", 1:4)))
  } else {
    corpus_names <- c(corpus_names, paste0("Corpus", year - 2000, "_", sprintf("%02d", 1:12)))
  }
}

# Create a list of file paths
file_paths <- list.files("~/Rprojekt/Climate/2.data_transformations/data/udpipe_processed/", pattern = "udpipe_regex_.*\\.rds", full.names = TRUE)

# Loop through the file paths and create the corpora
for (i in seq_along(file_paths)) {
  corpus_name <- str_extract(file_paths[i], "Corpus\\d{2}_\\d{2}")
  if (corpus_name %in% corpus_names) {
    assign(corpus_name, readRDS(file_paths[i]) %>% select(doc_id, lemma))
  }
}

# Combine all corpora into a single data frame
corpus_df <- bind_rows(mget(corpus_names), .id = "corpus")

# Remove stopwords and numbers from the lemma variable
corpus_df_clean <- corpus_df %>%
  mutate(lemma = str_remove_all(lemma, "\\d+")) %>%
  filter(!lemma %in% stop_words_cs) %>%
  filter(!lemma %in% stop_words_czech_television)

# Count the number of occurrences of each lemma in each corpus
lemma_counts <- corpus_df_clean %>%
  group_by(corpus, lemma) %>%
  summarise(count = n()) %>%
  pivot_wider(names_from = "corpus", values_from = "count", values_fill = 0)

# Sample the top 1000 lemmata
top_lemmata <- lemma_counts %>%
  group_by(lemma) %>%
  summarise(total_count = sum(across(everything()))) %>%
  top_n(1000, total_count) %>%
  inner_join(lemma_counts, by = "lemma")

# Write to CSV
write.csv(top_lemmata, "top_1000_lemmata.csv", row.names = FALSE)

# Sample the top 5000 lemmata
top_5000_lemmata <- lemma_counts %>%
  group_by(lemma) %>%
  summarise(total_count = sum(across(everything()))) %>%
  top_n(5000, total_count) %>%
  inner_join(lemma_counts, by = "lemma")

# Write to CSV
write.csv(top_5000_lemmata, "top_5000_lemmata.csv", row.names = FALSE)


# The code below first loads the top 1000 lemmata from the CSV file using read.csv(). It then creates a bar chart of the top 20 lemmata using ggplot() and geom_bar(). The reorder() function is used to sort the lemmata by their total count in descending order. The xlab(), ylab(), and ggtitle() functions are used to add labels to the x-axis, y-axis, and plot title, respectively.
# You can modify the code to show more or fewer lemmata by changing the number in top_lemmata[1:20, ] to the desired number.

library(ggplot2)

# Load the top 1000 lemmata
top_lemmata <- read.csv("top_1000_lemmata.csv")

# Create a bar chart of the top 20 lemmata
ggplot(top_lemmata[1:20, ], aes(x = reorder(lemma, -total_count), y = total_count)) +
  geom_bar(stat = "identity") +
  xlab("Lemma") +
  ylab("Total Count") +
  ggtitle("Top 20 Lemmata")
