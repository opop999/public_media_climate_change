get_count_per_media <- function(search_string = "*", min_date, max_date, media_history_id_vector, section_vector, media_id_vector, media_name, duplicities = FALSE, newton_api_token, log = TRUE, log_path = "") {

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
    is.character(section_vector),
    is.character(media_id_vector) | is.numeric(media_id_vector),
    is.character(media_name),
    length(search_string) == 1,
    is.numeric(media_history_id_vector) | is.character(media_history_id_vector),
    is.character(min_date),
    is.character(max_date),
    nchar(min_date) == 19,
    nchar(max_date) == 19,
    is.logical(duplicities),
    is.character(newton_api_token),
    nchar(newton_api_token) > 30,
    is.logical(log),
    is.character(log_path),
    !is.na(media_history_id_vector)
  )

  # Add log printing for long extractions
  if (log == TRUE) {
    sink(file = paste0(log_path, "get_media_count_log.txt"), append = TRUE, split = TRUE)
    cat("\n")
    print(Sys.time())
  }

  cat("\nThe total number of sections & the total amount of API calls:", length(section_vector), "\n")

  # 2. Loop over each media id ------------------------------------------

  ## Create empty list to append results to
  articles_id_count <- vector(mode = "list", length = length(section_vector))

  # Start counting the extraction length
  start_time <- Sys.time()

  for (i in seq_along(section_vector)) {
    articles_id_count[[i]] <- httr::POST(
      url = "https://api.newtonmedia.eu/v2/archive/searchCount",
      httr::add_headers(
        Accept = "application/json",
        `Content-Type` = "application/json",
        Connection = "keep-alive",
        `Accept-Encoding` = "gzip, deflate, br",
        Authorization = paste("token", as.character(newton_api_token))
      ),
      encode = "json",
      body = toJSON(list(
        QueryText = unbox(search_string),
        DateFrom = unbox(min_date),
        DateTo = unbox(max_date),
        showDuplicities = unbox(duplicities),
        sourceHistoryIds = media_history_id_vector[[i]],
        SectionQuery = section_vector[[i]]
      ))
    )

    if (httr::status_code(articles_id_count[[i]]) == 500) {
      cat("\nWARNING: API call nr.", i, "for media", media_name[[i]], "with id", media_history_id_vector[[i]], "in period", min_date, "-", max_date, "failed with error code 500. Missing data are likely.")
      articles_id_count[[i]] <- NA # Replace with NA if failed data extraction
    } else if (httr::status_code(articles_id_count[[i]]) == 200) {
      articles_id_count[[i]] <- articles_id_count[[i]] %>%
        content(as = "parsed") %>%
        c(period_start = min_date,
          period_end = max_date,
          media_name = media_name[[i]],
          hist_id = media_history_id_vector[[i]],
          id = media_id_vector[[i]],
          media_section = section_vector[[i]],.)

      cat("\nAPI call nr.", i, "for media", media_name[[i]], "with id", media_history_id_vector[[i]], "and section", section_vector[[i]], "in period", min_date, "-", max_date, "executed sucessfully")
    } else {
      cat("\nWARNING: API call nr.", i, "for media", media_name[[i]], "with id", media_history_id_vector[[i]], "and section", section_vector[[i]], "in period", min_date, "-", max_date, "returned the following code: ", httr::status_code(articles_id_count[[i]]), ". Check the connection.")
    }

    # Random wait time as not to overwhelm the API
    pause <- runif(1, 0.1, 0.5)
    cat("\nPausing for", pause, "seconds.\n")
    Sys.sleep(pause)
  }

  cat(
    "\nSUMMARY: Total amount of sections for this period is", length(section_vector),
    "\nAmount collected:", sum(!is.na(articles_id_count)),
    "\nAbsolute difference of", abs(length(section_vector) - sum(!is.na(articles_id_count))), "\n"
  )

  print(Sys.time() - start_time)

  # Redirect sink back to console
  if (log == TRUE) {
    sink()
  }

  return(articles_id_count)
}
