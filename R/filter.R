#' Filter ICD codes by validity.
#'
#' Filters a data.frame of patients for valid or invalid ICD codes
#' @param x a data.frame containing a column of ICD codes
#' @template icd_name
#' @template short_code
#' @template invert
#' @param ... arguments passed to the class-specific functions
#' @keywords manip
#' @export
filter_valid <- function(x, icd_name = get_icd_name(x),
                         short_code = guess_short(.subset2(x, icd_name)),
                         invert = FALSE) {
  assert_data_frame(x, min.cols = 1, col.names = "named")
  assert_string(icd_name)
  assert_flag(short_code)
  assert_flag(invert)
  # don't UseMethod: the data frame itself doesn't have an ICD version class
  icd_ver <- guess_version(.subset2(x, icd_name))
  if (icd_ver == "icd9") {
    icd9_filter_valid(
      x = x, icd_name = icd_name,
      short_code = short_code, invert = invert
    )
  } else if (icd_ver == "icd10") {
    icd10_filter_valid(
      x = x, icd_name = icd_name,
      short_code = short_code, invert = invert
    )
  } else {
    stop("could not identify ICD code type")
  }
}

#' @describeIn filter_valid Filter invalid rows from data frame of patients with
#'   ICD codes. This can also be achieved with \code{filter_valid} and
#'   \code{invert = TRUE}
#' @export
filter_invalid <- function(x, icd_name = get_icd_name(x),
                           short_code = guess_short(x[[icd_name]]),
                           invert = FALSE) {
  filter_valid(
    x = x, icd_name = icd_name,
    short_code = short_code, invert = !invert
  )
}

#' @describeIn filter_valid Filter data frame for valid ICD codes
#' @export
icd9_filter_valid <- function(x, icd_name = get_icd_name(x),
                              short_code = guess_short(x[[icd_name]]),
                              invert = FALSE) {
  assert_data_frame(x, min.cols = 1, col.names = "named")
  assert_string(icd_name)
  assert_flag(short_code)
  assert_flag(invert)
  assert_data_frame(x, min.cols = 1, col.names = "named")
  x[is_valid.icd9(as_char_no_warn(.subset2(x, icd_name)),
    short_code = short_code
  ) != invert, ]
}

#' @rdname filter_valid
#' @export
icd10_filter_valid <- function(x, icd_name = get_icd_name(x),
                               short_code = guess_short(x[[icd_name]]),
                               invert = FALSE) {
  assert_data_frame(x, min.cols = 1, col.names = "named")
  assert_string(icd_name)
  assert_flag(short_code)
  assert_flag(invert)
  x[
    is_valid.icd10(
      as_char_no_warn(
        .subset2(x, icd_name)
      ),
      short_code = short_code
    ) != invert,
  ]
}

#' @rdname filter_valid
#' @export
icd9_filter_invalid <- function(x, icd_name = get_icd_name(x),
                                short_code = guess_short(x[[icd_name]]),
                                invert = FALSE) {
  assert_data_frame(x, min.cols = 1, col.names = "named")
  assert_string(icd_name)
  assert_flag(short_code)
  assert_flag(invert)
  icd9_filter_valid(
    x = x, icd_name = icd_name,
    short_code = short_code, invert = !invert
  )
}

#' @rdname filter_valid
#' @export
icd10_filter_invalid <- function(x, icd_name = get_icd_name(x),
                                 short_code = guess_short(x[[icd_name]]),
                                 invert = FALSE) {
  assert_data_frame(x, min.cols = 1, col.names = "named")
  assert_string(icd_name)
  assert_flag(short_code)
  assert_flag(invert)
  icd10_filter_valid(
    x = x, icd_name = icd_name,
    short_code = short_code, invert = !invert
  )
}

#' Filters data frame based on present-on-arrival flag
#'
#' Present On Arrival (POA) is not a simple flag, since many codes are exempt,
#' unspecified, or unknown. Therefore, two options are given: get all the
#' comorbidities where the POA flag was definitely negative, coded as 'N' or
#' definitely positive and coded as 'Y'. Negating one set won't give the other
#' set unless all codes were either Y or N.
#' @param x input vector of ICD codes
#' @template poa_name
#' @template poa
#' @examples
#' \dontrun{
#' library(magrittr, warn.conflicts = FALSE, quietly = TRUE)
#' myData <- data.frame(
#'   visit_id = c("v1", "v2", "v3", "v4"),
#'   diag = c("39891", "39790", "41791", "4401"),
#'   poa = c("Y", "N", NA, "Y"),
#'   stringsAsFactors = FALSE
#' )
#' myData %>% filter_poa_not_no() %>% comorbid_ahrq()
#' # can fill out named fields also:
#' myData %>%
#'   filter_poa_yes(poa_name = "poa") %>%
#'   comorbid_ahrq(
#'     icd_name = "diag", visit_name = "visit_id",
#'     short_code = TRUE
#'   )
#' # can call the core comorbid() function with an arbitrary mapping
#' myData %>%
#'   filter_poa_yes() %>%
#'   comorbid_elix(
#'     icd_name = "diag", visit_name = "visit_id",
#'     short_mapping = TRUE
#'   )
#' }
#' @keywords manip
#' @export
filter_poa <- function(x, poa_name = "poa", poa = poa_choices) {
  poa <- match.arg(poa)
  assert_data_frame(x, min.cols = 1, col.names = "named")
  assert_string(poa_name)
  stopifnot(poa_name %in% names(x))
  switch(poa,
    "yes" = filter_poa_yes(x, poa_name = poa_name),
    "no" = filter_poa_no(x, poa_name = poa_name),
    "notYes" = filter_poa_not_yes(x, poa_name = poa_name),
    "notNo" = filter_poa_not_no(x, poa_name = poa_name)
  )
}

.filter_poa <- function(x, poa_name, choice, invert = FALSE) {
  assert_data_frame(x, min.cols = 1, col.names = "named")
  stopifnot(is.character(poa_name), length(poa_name) == 1L, !is.na(poa_name))
  assert_character(choice, min.chars = 1, min.len = 1, any.missing = FALSE)
  assert_flag(invert)
  stopifnot(poa_name %in% names(x))
  p <- x[[poa_name]]
  if (invert) {
    return(x[is.na(p) | p %nin% choice, names(x) != poa_name])
  }
  x[!is.na(p) & p %in% choice, names(x) != poa_name]
}

#' @describeIn filter_poa Select rows where Present-on-Arrival flag is
#'   explicitly 'Yes.'
#' @export
filter_poa_yes <- function(x, poa_name = "poa") {
  .filter_poa(x, poa_name, choice = c("Y", "y"), invert = FALSE)
}

#' @describeIn filter_poa Select rows where Present-on-Arrival flag is
#'   explicitly 'No.'
#' @export
filter_poa_no <- function(x, poa_name = "poa") {
  .filter_poa(x, poa_name, choice = c("N", "n"), invert = FALSE)
}

#' @describeIn filter_poa Select rows where Present-on-Arrival flag is
#'   anything but 'No.' This includes unknown, exempt, other codes, and of
#'   course all those marked 'Yes.'
#' @export
filter_poa_not_no <- function(x, poa_name = "poa") {
  .filter_poa(x, poa_name, choice = c("N", "n"), invert = TRUE)
}

#' @describeIn filter_poa Select rows where Present-on-Arrival flag is
#'   anything but 'Yes.' This would group exempt, unknown and other codes under
#'   'Not POA' which is unlikely to be a good choice, since exempt codes, of
#'   which there are a quite large number, tend to describe chronic or
#'   out-of-hospital characteristics.
#' @export
filter_poa_not_yes <- function(x, poa_name = "poa") {
  .filter_poa(x, poa_name, choice = c("Y", "y"), invert = TRUE)
}
