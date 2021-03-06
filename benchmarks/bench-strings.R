#' @examples
#' \dontrun{
#' s <- icd:::random_string(1e4);
#' microbenchmark::microbenchmark(icd:::trim(s), trimws(s))
#' }

#' @examples
#' \dontrun{
#' requireNamespace("microbenchmark")
#' requireNamespace("stringr")
#' x <- icd:::random_string(5e4);
#' microbenchmark::microbenchmark(
#'   gsub(x = x, pattern = "A", replacement = "", fixed = TRUE, useBytes = TRUE),
#'   gsub(x = x, pattern = "A", replacement = "", fixed = TRUE, useBytes = TRUE, perl = TRUE),
#'   gsub(x = x, pattern = "A", replacement = ""),
#'   stringr::str_replace_all(x, "A", "")
#'   )
#' }
