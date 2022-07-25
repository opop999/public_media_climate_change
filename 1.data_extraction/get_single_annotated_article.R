# This function extracts media articles according to selected criteria.
# The output is a list of datasets, which contain article title and annotation.

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
