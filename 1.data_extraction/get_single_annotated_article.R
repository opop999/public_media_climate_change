# This file contains a function that extracts media articles according to selected criteria.
# The output is a list of datasets, which contain article title and annotation.
#
# Function:
# extract_annotated_article
#
# Arguments:
# search_string: A character string containing the search query.
# search_in_title: A logical value indicating whether to search in the article title or not. Default is TRUE.
# page_size: An integer indicating the number of articles to be returned per page. Default is 1.
# min_date: A character string indicating the minimum date of the articles to be returned. Format: "YYYY-MM-DDTHH:MM:SS". 
# max_date: A character string indicating the maximum date of the articles to be returned. Format: "YYYY-MM-DDTHH:MM:SS".
# country: An integer indicating the country of the articles to be returned. 1 for Czech Republic, 2 for Slovakia. Default is 1.
# sort: An integer indicating the sorting order of the articles to be returned. 1 for relevance, 2 for date, 3 for popularity. Default is 2.
# media_history_id: An integer indicating the media history ID of the articles to be returned. Default is NULL.
# duplicities: A logical value indicating whether to show duplicities or not. Default is FALSE.
# newton_api_token: A character string containing the API token for the Newton Media Archive.
# log: A logical value indicating whether to print log messages or not. Default is TRUE.
# log_path: A character string indicating the path to the log file. Default is "".
# doc_id: A character string indicating the ID of the document to be extracted.
#
# Value:
# A list of datasets, which contain article title and annotation.
#
# Example:
# extract_annotated_article(search_string = "climate change", min_date = "2021-01-01T00:00:00", max_date = "2021-12-31T23:59:59", newton_api_token = "your_api_token_here")


extract_annotated_article <- function(search_string,
                                      search_in_title = TRUE,
                                      page_size = 1,
                                      min_date,
                                      max_date,
                                      country = 1,
                                      sort = 2,
                                      media_history_id,
                                      duplicities = FALSE,
                                      newton_api_token,
                                      log = TRUE,
                                      log_path = "",
                                      doc_id)
{

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
    is.character(doc_id),
    is.character(search_string),
    length(search_string) == 1,
    is.numeric(page_size),
    page_size > 0 & page_size <= 10000,
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
    cat_sink <- function(..., file = paste0(log_path, "get_single_annotated_article_log.txt"), append = TRUE) {
      cat(..., file = file, append = append)
    }  } else {
      cat_sink <- cat
    }

  # 2. Extract single annotation ------------------------------------------

    result <- httr::POST(
        url = "https://api.newtonmedia.eu/v2/archive/search",
        httr::add_headers(
          Accept = "application/json",
          `Content-Type` = "application/json",
          Authorization = paste("token", as.character(newton_api_token))
        ),
        encode = "json",
        body = toJSON(list(
          QueryText = unbox(search_string),
          SearchInTitle = unbox(search_in_title),
          DateFrom = unbox(min_date),
          DateTo = unbox(max_date),
          CurrentPage = unbox(1),
          PageSize = unbox(page_size),
          Sorting = unbox(sort),
          showDuplicities = unbox(duplicities),
          CountryIds = country,
          sourceHistoryIds = media_history_id
        ))
      )

  if (httr::status_code(result) == 200 &
      as.numeric(result$headers$`content-length`) >= 300) {
    result <- result %>%
      content(as = "text") %>%
      fromJSON(flatten = TRUE) %>%
      .[["articles"]] %>% # Remove columns that do not provide any useful information to our research or are duplicates
      .[,!colnames(.) %in% c(
        "language",
        "isRead",
        "isBookmarked",
        "userQueryId",
        "mediaType.code",
        "mediaType.name"
      )]
    cat_sink("\nAPI call for article", doc_id, "executed.")

  } else if (httr::status_code(result) == 200 &
             as.numeric(result$headers$`content-length`) < 300) {

    cat_sink("\nWARNING: API call for article",
             doc_id, "returned empty response.")

    # Replace with empty dataset so bind_row at the end is successful
    result <- tibble()

  } else if (httr::status_code(result) == 500) {
    cat_sink("\nWARNING: API call for article",
             doc_id,
             "failed with error code 500.")

    # Replace with empty dataset so bind_row at the end is successful
    result <- tibble()

  } else {
    cat_sink(
      "\nWARNING: API call for article id",
      doc_id,
      "returned the following code: ",
      httr::status_code(result),
      ". Check the connection."
    )
  }

  return(result)

}
