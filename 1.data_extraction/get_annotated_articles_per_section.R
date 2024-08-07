# This function extracts annotated news articles from the Newton Media API based on the specified search criteria.
# The function returns a list of datasets, which contain article title and annotation.
# 
# Arguments:
#   - search_string: A character string specifying the search query.
#   - page_size: An integer specifying the number of articles to retrieve per API call.
#   - min_date: A character string specifying the minimum date for the search query in the format "YYYY-MM-DD HH:MM:SS".
#   - max_date: A character string specifying the maximum date for the search query in the format "YYYY-MM-DD HH:MM:SS".
#   - country: An integer specifying the country ID for the search query (1 for Czech Republic, 2 for Slovakia).
#   - sort: An integer specifying the sorting order for the search query (1 for relevance, 2 for date descending, 3 for date ascending).
#   - section: A character string specifying the section of the news articles to retrieve (optional).
#   - media_history_id: An integer specifying the media history ID for the search query (optional).
#   - duplicities: A logical value indicating whether to include duplicate articles in the search results.
#   - newton_api_token: A character string specifying the API token for the Newton Media API.
#   - return_df: A logical value indicating whether to return the extracted articles as a data frame (default is TRUE).
#   - log: A logical value indicating whether to log the progress of the extraction process (default is TRUE).
#   - log_path: A character string specifying the file path for the log file (optional).
# 
# Returns:
#   A data frame with the extracted news articles.
# 
# Examples:
#   extract_annotated_articles_by_section(search_string = "climate change",
#                                          min_date = "2021-01-01 00:00:00",
#                                          max_date = "2021-12-31 23:59:59",
#                                          country = 1,
#                                          sort = 2,
#                                          newton_api_token = "your_api_token_here")

extract_annotated_articles_by_section <- function(search_string = "*",
                                                  page_size = 10000,
                                                  min_date,
                                                  max_date,
                                                  country = 1,
                                                  sort = 2,
                                                  section = NULL,
                                                  media_history_id = NULL,
                                                  duplicities = FALSE,
                                                  newton_api_token,
                                                  return_df = TRUE,
                                                  log = TRUE,
                                                  log_path = "") {

  # 0. Load libraries ------------------------------------------

  # Package names
  packages <- c("httr", "dplyr", "jsonlite")

  # Install packages not yet installed
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)) {
    install.packages(packages[!installed_packages])
  }

  # Packages loading
  invisible(lapply(packages, library, character.only = TRUE))

  # 1. Verify function's inputs ------------------------------------------

  stopifnot(
    is.logical(log),
    is.character(log_path),
    is.character(search_string),
    length(search_string) == 1,
    is.numeric(page_size),
    page_size > 0 & page_size <= 10000,
    is.character(section) | is.null(section),
    is.numeric(media_history_id) | is.null(media_history_id),
    is.character(min_date),
    is.character(max_date),
    nchar(min_date) == 19,
    nchar(max_date) == 19,
    is.numeric(country),
    country %in% c(1, 2),
    is.numeric(sort),
    sort %in% c(1, 2, 3),
    is.logical(duplicities),
    is.character(newton_api_token),
    nchar(newton_api_token) > 30
  )
  # Add log printing for long extractions
  if (log == TRUE) {
    # Custom function to print console output to a file
    cat_sink <- function(..., file = paste0(log_path, "get_annotated_articles_log.txt"), append = TRUE) {
      cat(..., file = file, append = append)
    }  } else {
      cat_sink <- cat
    }

  cat_sink("\n>--------------------<\n\n", as.character(Sys.time()))

  # 2. Get total number of results ------------------------------------------

  get_total_results <- function() {
    httr::POST(
      url = "https://api.newtonmedia.eu/v2/archive/searchCount",
      httr::add_headers(
        Accept = "application/json",
        `Content-Type` = "application/json",
        Authorization = paste("token", as.character(newton_api_token))
      ),
      encode = "json",
      body = toJSON(list(
        QueryText = unbox(search_string),
        DateFrom = unbox(min_date),
        DateTo = unbox(max_date),
        showDuplicities = unbox(duplicities),
        CountryIds = country,
        SectionQuery = section,
        sourceHistoryIds = media_history_id
      ))
    ) %>%
      content(as = "parsed") %>%
      .[["count"]]
  }

  total_results <- get_total_results()

  if (total_results > 10000) {
    cat_sink(
      "\nWARNING: Total number of news items within selected time period is larger than 10000.\n",
      "Articles above this limit will not be saved. Consider shortening the time window.\n"
    )
  } else {
    cat_sink("\nTotal number of news items is under the limit of 10000.\n")
  }

  stopifnot(!is.null(total_results))

  total_pages <- ceiling(total_results / page_size)

  cat_sink(
    "\nWithin the search period of",
    min_date, "-", max_date, ":",
    "\nThe number of total results is:", total_results,
    "\nThe selected page size is:", page_size,
    "\nTotal number of API calls will be:", total_pages, "\n"
  )

  # 3. Loop over pages ------------------------------------------

  ## Create empty list to append results to
  annotated_articles_list <- vector(mode = "list", length = total_pages)

  if (total_pages >= 1) {
    for (i in seq_len(total_pages)) {
      annotated_articles_list[[i]] <- httr::POST(
        url = "https://api.newtonmedia.eu/v2/archive/search",
        httr::add_headers(
          Accept = "application/json",
          `Content-Type` = "application/json",
          Authorization = paste("token", as.character(newton_api_token))
        ),
        encode = "json",
        body = toJSON(list(
          QueryText = unbox(search_string),
          DateFrom = unbox(min_date),
          DateTo = unbox(max_date),
          CurrentPage = unbox(i),
          PageSize = unbox(page_size),
          Sorting = unbox(sort),
          showDuplicities = unbox(duplicities),
          CountryIds = country,
          SectionQuery = section,
          sourceHistoryIds = media_history_id
        ))
      )

      if (httr::status_code(annotated_articles_list[[i]]) == 500) {
        cat_sink("\nWARNING: API call nr.", i, " failed with error code 500. Missing data are likely.")

        # Replace with empty dataset so bind_row at the end is successful
        annotated_articles_list[[i]] <- tibble()
      } else if (httr::status_code(annotated_articles_list[[i]]) == 200) {
        annotated_articles_list[[i]] <- annotated_articles_list[[i]] %>%
          content(as = "text") %>%
          fromJSON(flatten = TRUE) %>%
          .[["articles"]] %>% # Remove columns that do not provide any useful information to our research or are duplicates
          .[, !colnames(.) %in% c(
            "language",
            "isRead",
            "isBookmarked",
            "userQueryId",
            "mediaType.code",
            "mediaType.name"
          )] %>%
          mutate(section = section)

        cat_sink("\nAPI call nr.", i, "executed. The number of rows is", nrow(annotated_articles_list[[i]]))
      } else {
        cat_sink("\nWARNING: API call nr.", i, " returned the following code: ", httr::status_code(annotated_articles_list[[i]]), ". Check the connection.")
      }

      # Random wait time as not to overwhelm the API
      pause <- runif(1, 0.02, 0.2)
      cat_sink("\nPausing for", pause, "seconds.\n")
      Sys.sleep(pause)
    }
  } else if (total_pages == 0) {
    cat_sink("\nNo results for the selected period, skipping extraction.\n")
  }

  cat_sink(
    "\nSUMMARY: Total amount of articles for this period is", total_results,
    "\nAmount collected:", sum(unlist(lapply(annotated_articles_list, nrow))),
    "\nAbsolute difference of", abs(total_results - sum(unlist(lapply(annotated_articles_list, nrow)))),
    "\n>--------------------<\n\n"
  )

  if (return_df == TRUE) {
    return(bind_rows(annotated_articles_list))
  } else if (return_df == FALSE) {
    return(annotated_articles_list)
  }
}
