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

# Remove stopwords, numbers, and interpunction from the lemma variable
corpus_df_clean <- corpus_df %>%
  mutate(lemma = str_remove_all(lemma, "\\d+")) %>%
  mutate(lemma = str_remove_all(lemma, "[[:punct:]]+")) %>%
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
  inner_join(lemma_counts, by = "lemma") %>%
  mutate(lemma = str_trim(lemma))

# Write to CSV
write.csv(top_lemmata, "top_1000_lemmata.csv", row.names = FALSE)

# Sample the top 5000 lemmata
top_5000_lemmata <- lemma_counts %>%
  group_by(lemma) %>%
  summarise(total_count = sum(across(everything()))) %>%
  top_n(5000, total_count) %>%
  inner_join(lemma_counts, by = "lemma") %>%
  mutate(lemma = str_trim(lemma))

# Write to CSV
write.csv(top_5000_lemmata, "top_5000_lemmata.csv", row.names = FALSE)


# The code below first loads the top 1000 lemmata from the CSV file using read.csv(). It then creates a bar chart of the top 20 lemmata using ggplot() and geom_bar(). The reorder() function is used to sort the lemmata by their total count in descending order. The xlab(), ylab(), and ggtitle() functions are used to add labels to the x-axis, y-axis, and plot title, respectively.
# You can modify the code to show more or fewer lemmata by changing the number in top_lemmata[1:20, ] to the desired number.

library(ggplot2)

# Load the top 1000 lemmata
top_lemmata <- read.csv("top_1000_lemmata.csv")

# Create a bar chart of the top 20 lemmata
library(scales)

ggplot(top_lemmata[2:21, ], aes(x = reorder(lemma, -total_count), y = total_count, fill = lemma)) +
  geom_bar(stat = "identity") +
  xlab("Lemma") +
  ylab("Total Count") +
  ggtitle("Top 20 most frequent lemmata") +
  scale_y_continuous(labels = function(x) {
    ifelse(x >= 1e6, paste0(x / 1e6, " million"),
           ifelse(x >= 1e3, paste0(x / 1e3, " 000"), as.character(x)))
  })

#Specific lemmata that Andrea Culková asked for:
climate_lemmafreq <- lemma_counts %>%
  group_by(lemma) %>%
  summarise(total_count = sum(across(everything()))) %>%
  filter(lemma %in% c("ekologie", "ekolog", "environment", "environmentální", "znečištění", "nízkoemisní", "uhlík", "uhlíkový", "co2", "fosilní", "dekarbonizace", "vedra", "vedro", "oteplování", "povodeň", "tornádo")) %>%
  inner_join(lemma_counts, by = "lemma") %>%
  mutate(lemma = str_trim(lemma))

# Write to CSV
write.csv(climate_lemmafreq, "climate_lemma_frequencies.csv", row.names = FALSE)

english_labels <- c("Flood(ing)", "Tornado", "Pollution", "Ecologist", "Heat(wave)", "Ecology", "Warming", "Fossil (Adj.)", "Carbon (Adj.)", "Low-emission (Adj.)", "Carbon (Noun)", "Environmental", "De-carbonization", "Environment")
english_translations <- c("povodeň"="Flood(ing)", "tornádo"="Tornado", "znečištění"="Pollution", "ekolog"="Ecologist", "vedro"="Heat(wave)", "ekologie"="Ecology", "oteplování"="Warming", "fosilní"="Fossil (Adj.)", "uhlíkový"="Carbon (Adj.)", "nízkoemisní"="Low-emission (Adj.)", "uhlík"="Carbon (Noun)", "environmentální"="Environmental", "dekarbonizace"="De-carbonization", "environment"="Environment")
english_translations <- as.factor(english_translations)


# Define the order of the lemmata
lemma_order <- c("povodeň", "tornádo", "znečištění", "ekolog", "vedro", "ekologie", "oteplování", "fosilní", "uhlíkový", "nízkoemisní", "uhlík", "environmentální", "dekarbonizace", "environment")

climate_lemmafreq$english_labels
# Define a custom color palette TO DO: FIX THESE TO MATCH THE LEMMA ORDER
custom_palette <- c("#1f77b4", "#aec7e8", "#000000", "#66bd63", "#d73027", "#1a9850", "#f46d43", "#969696", "#525252", "#e6f5d0", "#737373", "#d9ef8b", "#a6d96a", "#66c2a5")
names(custom_palette) = c("povodeň", "tornádo", "znečištění", "ekolog", "vedro", "ekologie", "oteplování", "fosilní", "uhlíkový", "nízkoemisní", "uhlík", "environmentální", "dekarbonizace", "environment")

#Plot this:
climate_lemmafreq_sorted <- climate_lemmafreq[order(-climate_lemmafreq$total_count),]
climate_lemmafreq_sorted$english_labels <- c("Flood(ing)", "Tornado", "Pollution", "Ecologist", "Heat(wave)", "Ecology", "Warming", "Fossil (Adj.)", "Carbon (Adj.)", "Low-emission (Adj.)", "Carbon (Noun)", "Environmental", "De-carbonization", "Environment")

ggplot(climate_lemmafreq_sorted, aes(x = reorder(lemma, -total_count), y = total_count, fill = lemma)) +
  geom_bar(stat = "identity") +
  xlab("Lemma") +
  ylab("Total Count") +
  ggtitle("Frequency of specific climate lemmata") +
  scale_y_continuous(labels = function(x) {
    ifelse(x >= 1e6, paste0(x / 1e6, " 000 000"),
           ifelse(x >= 1e3, paste0(x / 1e3, " 000"), as.character(x)))
  }) +
  scale_fill_manual(name = "Climate words", values = custom_palette, labels = english_translations)
