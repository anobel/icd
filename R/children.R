#' Get children of ICD codes
#'
#' Expand ICD codes to all possible sub-codes, optionally limiting to those
#' codes which are \emph{defined} or \emph{billable} (leaf nodes).
#' @param x data, e.g. character vector of ICD codes.
#' @param defined single logical value, whether returned codes should only
#'   include those which have definitions. Definition is based on the ICD
#'   version being used, e.g. ICD-9-CM, the WHO version of ICD-10, or other.
#' @template billable
#' @template short_code
#' @template dotdotdot
#' @keywords manip
#' @family ICD-9 ranges
#' @examples
#' library(magrittr, warn.conflicts = FALSE, quietly = TRUE)
#' # magrittr not required by icd
#' # icd.data package highly recommended, but not a depependency for comorbidity calculations
#' if (requireNamespace("icd.data", quietly = TRUE)) {
#'   # no children other than self
#'   children("10201", short_code = TRUE, defined = FALSE)
#' 
#'   # guess it was ICD-9 and a short, not decimal code
#'   children("0032")
#' 
#'   # empty because 102.01 is not meaningful
#'   children("10201", short_code = TRUE, defined = TRUE)
#'   x <- children("003", short_code = TRUE, defined = TRUE)
#'   explain_code(x, condense = FALSE, short_code = TRUE)
#' 
#'   children(short_code = FALSE, "100.0")
#'   children(short_code = FALSE, "100.00")
#'   children(short_code = FALSE, "2.34")
#' }
#' @return Returns a vector of ICD codes, with class of \code{character} and the
#'   class of the identified or specified ICD code, e.g. \code{icd9}
#' @export
children <- function(x, ...) {
  require_icd_data()
  UseMethod("children")
}

#' @describeIn children Get child codes, guessing ICD version and short
#'   versus decimal format
#' @export
children.character <- function(x, ...) {
  require_icd_data()
  ver <- guess_version(x)
  # eventually UseMethod again, but this would be circular until the icd10
  # method is defined.
  if (ver %in% icd9_classes) {
    return(children.icd9cm(x = x, ...))
  }
  if (ver == "icd10") {
    return(children.icd10(x = x, ...))
  }
  if (ver == "icd10cm") {
    return(children.icd10cm(x = x, ...))
  }
}

#' @describeIn children Get children of ICD-9-CM codes
#' @export
children.icd9cm <- function(x,
                            short_code = guess_short(x),
                            defined = TRUE,
                            billable = FALSE,
                            ...) {
  stopifnot(is.factor(x) || is.character(x))
  stopifnot(is.logical(short_code))
  stopifnot(is.logical(defined))
  stopifnot(is.logical(billable))
  require_icd_data()
  res <- if (short_code) {
    .Call("_icd_icd9ChildrenShortUnordered",
      icd9Short = toupper(x),
      # TODO: update to use new icd.data naming scheme
      icd9cmReal = icd.data::icd9cm_hierarchy$code,
      onlyReal = defined
    )
  } else {
    .Call("_icd_icd9ChildrenDecimalCpp",
      icd9Decimal = toupper(x),
      icd9cmReal = icd.data::icd9cm_hierarchy$code,
      onlyReal = defined
    )
  }
  res <- sort.icd9(res)
  res <- if (billable) {
    get_billable.icd9cm(icd9cm(res), short_code)
  } else {
    as.icd9(res)
  }
  if (is.icd9cm(x)) {
    return(as.icd9cm(res))
  }
  res
}

#' @describeIn children Get children of ICD-9 codes, based on the super-set
#'   ICD-9-CM at present
#' @export
children.icd9 <- function(x, short_code = guess_short(x),
                          defined = TRUE, billable = FALSE, ...)
  children.icd9cm(x,
    short_code = short_code,
    defined = defined, billable = billable
  )

#' @describeIn children Get children of ICD-10 codes (warns because this
#'   only applies to ICD-10-CM for now).
#' @export
children.icd10 <- function(x,
                           short_code = guess_short(x),
                           defined,
                           billable = FALSE, ...) {
  require_icd_data()
  res <- children.icd10cm(x, short_code, defined, billable, ...)
  if (!is.icd10cm(x)) {
    cl <- class(res)
    cl <- cl[cl != "icd10cm"]
    class(res) <- cl
  }
  res
}

#' @describeIn children Get children of ICD-10-CM codes
#' @export
children.icd10cm <- function(x,
                             short_code = guess_short(x),
                             defined,
                             billable = FALSE,
                             ...) {
  require_icd_data()
  if (!missing(defined) && !defined) {
    stop("Only finding children of 'defined' ICD-10-CM codes is supported.")
  }
  children_defined.icd10cm(x = x, short_code = short_code)
}

#' @describeIn children Get children of ICD-10-CM codes
#' @export
children.icd10who <- function(x,
                              short_code = guess_short(x),
                              defined,
                              billable = NULL,
                              leaf = NULL,
                              ...) {
  require_icd_data()
  if (!missing(defined) && !defined) {
    stop("Only finding children of 'defined' ICD-10-CM codes is supported.")
  }
  children_defined.icd10who(x = x, short_code = short_code)
}

#' Find only the defined children of ICD codes
#'
#' Find defined ICD-10 children based on 2016 ICD-10-CM list. "defined" may be a
#' three digit code, or a leaf node. This is distinct from 'billable'.
#'
#' @keywords internal
#' @noRd
children_defined <- function(x)
  UseMethod("children_defined")

#' @describeIn children_defined Internal function to get the children of
#'   ICD-10-CM code(s)
#' @param warn single logical value, if \code{TRUE} will generate warnings when
#'   some input codes are not known ICD-10-CM codes
#' @param use_cpp single logical flag, whether to use C++ version
#' @export
#' @keywords internal
#' @noRd
children_defined.icd10cm <- function(x,
                                     short_code = guess_short(x),
                                     warn = FALSE,
                                     verbose = FALSE) {
  require_icd_data()
  stopifnot(is.factor(x) || is.character(unclass(x)))
  stopifnot(is.logical(short_code))
  stopifnot(is.logical(warn))
  x <- trimws(toupper(x))
  if (!short_code) {
    x <- decimal_to_short.icd10cm(x)
  }
  ver <- icd_data_get_icd10cm_active_ver()
  if (verbose) message("Using ICD-10-CM version: ", ver)
  nc <- .icd10cm_get_nchars(ver)
  lu <- icd_data_icd10cm_active()
  if (length(nc) != nrow(lu)) browser()
  kids <- icd10_children_defined_rcpp(
    x = x,
    lookup = lu,
    nc = nc
  )
  as.icd10cm(kids, short_code)
}

#' @describeIn children_defined Internal function to get the children of WHO
#'   ICD-10 code(s)
#' @param warn single logical value, if \code{TRUE} will generate warnings when
#'   some input codes are not known ICD-10-CM codes
#' @param use_cpp single logical flag, whether to use C++ version
#' @param who_ver Single character string of the name of the WHO ICD data to
#'   use. Default is \code{icd10who2016}. Internal use only.
#' @examples
#' \dontrun{
#' icd:::children_defined.icd10who("H16")
#' icd:::children_defined.icd10who("A01")
#' icd:::children_defined.icd10who("XYZ")
#' }
#' @export
#' @keywords internal
#' @noRd
children_defined.icd10who <- function(x,
                                      short_code = guess_short(x),
                                      who_ver = "icd10who2016",
                                      warn = FALSE) {
  require_icd_data(version = "1.1")
  stopifnot(is.factor(x) || is.character(unclass(x)))
  stopifnot(is.logical(short_code))
  stopifnot(is.logical(warn))
  x <- trimws(toupper(x))
  if (!short_code) {
    x <- decimal_to_short.icd10cm(x)
  }
  d <- if (who_ver == "icd10who2008fr") {
    .idget("icd10who2008fr")
  } else {
    .idget("icd10who2016")
  }
  stopifnot(!is.null(d))
  stopifnot(!is.null(d[["code"]]))
  # TODO: cache nchar call, like with ICD-10-CM
  kids <- icd10_children_defined_rcpp(x, d, nchar(d[["code"]]), warn = warn)
  as.icd10who(kids, short_code = short_code)
}
