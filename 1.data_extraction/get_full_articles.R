# This file contains a function that extracts full articles from the Newton Media API based on the specified search criteria. The function takes in several parameters such as search_string, page_size, min_date, max_date, sort, newton_api_token, media_history_id, media_id, duplicities, return_df, log, and log_path. The function returns a list of API responses or a data frame containing the extracted articles depending on the value of the return_df parameter. 

# Required packages: httr, dplyr, jsonlite

# Function: extract_full_articles
# Description: Extracts full articles from the Newton Media API based on the specified search criteria.
# Parameters:
#   search_string: A character string specifying the search criteria.
#   page_size: An integer specifying the number of articles to be returned per page.
#   min_date: A character string specifying the minimum date of the search period in the format "YYYY-MM-DD".
#   max_date: A character string specifying the maximum date of the search period in the format "YYYY-MM-DD".
#   sort: A character string specifying the sorting order of the search results.
#   newton_api_token: A character string specifying the API token for the Newton Media API.
#   media_history_id: An optional numeric value specifying the media history ID.
#   media_id: An optional numeric value specifying the media ID.
#   duplicities: A logical value specifying whether to include duplicates in the search results.
#   return_df: A logical value specifying whether to return a data frame or a list of API responses.
#   log: A logical value specifying whether to log the extraction process.
#   log_path: A character string specifying the path to the log file.
# Returns: A list of API responses or a data frame containing the extracted articles depending on the value of the return_df parameter.

extract_full_articles <- function(search_string = "*",
                                  page_size = 100,
                                  min_date,
                                  max_date,
                                  sort = "PublishDate_desc",
                                  newton_api_token,
                                  media_history_id = NULL,
                                  media_id = NULL,
                                  duplicities = FALSE,
                                  return_df = FALSE,
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
    is.character(search_string),
    length(search_string) == 1,
    is.numeric(page_size),
    page_size > 0,
    is.numeric(media_history_id) | is.null(media_history_id),
    is.numeric(media_id) | is.null(media_id),
    is.character(min_date),
    is.character(max_date),
    nchar(min_date) == 10,
    nchar(max_date) == 10,
    is.character(sort),
    is.logical(duplicities),
    is.logical(return_df),
    is.logical(log),
    is.character(log_path),
    is.character(newton_api_token),
    nchar(newton_api_token) > 30
  )
  # Add log printing for long extractions
  if (log == TRUE) {
    sink(file = paste0(log_path, "get_full_articles_log.txt"), append = TRUE, split = TRUE, type = c("output", "message"))
    cat("\n>--------------------<\n\n")
    print(Sys.time())
  }

  # 2. Get total number of results ------------------------------------------
  total_results <- httr::POST(
    url = "https://api.newtonmedia.eu/v2/archive/searchCount",
    httr::add_headers(
      Accept = "application/json",
      `Content-Type` = "application/json",
      Authorization = paste("token", as.character(newton_api_token))
    ),
    encode = "json",
    body = toJSON(list(
      QueryText = unbox(search_string),
      DateFrom = unbox(paste0(min_date, "T00:00:00")),
      DateTo = unbox(paste0(as.Date(max_date) - 1, "T23:59:59")),
      showDuplicities = unbox(duplicities),
      sourceHistoryIds = media_history_id
    ))
  ) %>%
    content(as = "parsed") %>%
    .[["count"]]

  if (total_results > 10000) {
    cat(
      "\nWARNING: Total number of news items within selected time period is larger than 10000.\n",
      "Articles above this limit will not be saved. Consider shortening the time window.\n"
    )
  } else if (is.null(total_results))  {
    stop("\nUnable to retrieve the total number of results for this time window. Check the API.\n")
  } else {
    cat("\nOK: Total number of news items is under the limit of 10000.\n")
  }

  total_pages <- ceiling(total_results / page_size)

  cat(
    "\nWithin the search period of",
    min_date, "-", max_date, ":",
    "\nThe number of total results is:", total_results,
    "\nThe selected page size is:", page_size,
    "\nTotal number of API calls will be:", total_pages, "\n"
  )

  # 3. Loop over pages ------------------------------------------

  ## Create empty list to append results to
  full_articles_list <- vector(mode = "list", length = total_pages)

  # Start counting the extraction length
  start_time <- Sys.time()

  for (i in seq_len(total_pages)) {

    full_articles_list[[i]] <- GET(
      url = "https://api.newtonmedia.eu/v2/archive/archives/search",
      httr::add_headers(
        Accept = "application/json",
        Authorization = paste("token", as.character(newton_api_token))
      ),
      query = list(
        page = i,
        size = page_size,
        query = search_string,
        from = min_date,
        to = max_date,
        orderBy = sort,
        sourceIds = media_id
      )
    )

    if (httr::status_code(full_articles_list[[i]]) == 500) {
      cat("\nWARNING: API call nr.", i, " failed with error code 500. Missing data are likely.")

      # Replace with empty dataset so bind_row at the end is successful
      full_articles_list[[i]] <- tibble()

    } else if (httr::status_code(full_articles_list[[i]]) == 200) {
      full_articles_list[[i]] <- full_articles_list[[i]] %>%
        content(as = "text") %>%
        fromJSON(flatten = TRUE) %>%
        .[, !colnames(.) %in% c(
          "LanguageCode",
          "Annotation"
        )]

      cat("\nAPI call nr.", i, "executed. The number of rows is", nrow(full_articles_list[[i]]))
    } else {
      cat("\nWARNING: API call nr.", i, " returned the following code: ", httr::status_code(full_articles_list[[i]]), ". Check the connection.")
    }

    # Random wait time as not to overwhelm the API
    pause <- runif(1, 1, 3)
    cat("\nPausing for", pause, "seconds.\n")
    Sys.sleep(pause)
  }

  cat(
    "\nSUMMARY: Total amount of articles for this period is", total_results,
    "\nAmount collected:", sum(unlist(lapply(full_articles_list, nrow))),
    "\nAbsolute difference of", abs(total_results - sum(unlist(lapply(full_articles_list, nrow)))), "\n",
    "\n\nExtraction of the period from", min_date, "to", max_date, "(excluding) has finished.\n")

  print(Sys.time() - start_time)

  cat("\n>--------------------<\n\n")

  # Redirect sink back to console
  if (log == TRUE) {
    sink(type = c("output", "message"))
  }

  if (return_df == TRUE) {
    return(bind_rows(full_articles_list))
  } else if (return_df == FALSE) {
    return(full_articles_list)
  }

}
