% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/children.R
\name{children}
\alias{children}
\alias{children.character}
\alias{children.icd9cm}
\alias{children.icd9}
\alias{children.icd10}
\alias{children.icd10cm}
\alias{children.icd10who}
\title{Get children of ICD codes}
\usage{
children(x, ...)

\method{children}{character}(x, ...)

\method{children}{icd9cm}(x, short_code = guess_short(x),
  defined = TRUE, billable = FALSE, ...)

\method{children}{icd9}(x, short_code = guess_short(x), defined = TRUE,
  billable = FALSE, ...)

\method{children}{icd10}(x, short_code = guess_short(x), defined,
  billable = FALSE, ...)

\method{children}{icd10cm}(x, short_code = guess_short(x), defined,
  billable = FALSE, ...)

\method{children}{icd10who}(x, short_code = guess_short(x), defined,
  billable = NULL, leaf = NULL, ...)
}
\arguments{
\item{x}{data, e.g. character vector of ICD codes.}

\item{...}{arguments passed on to other functions}

\item{short_code}{single logical value which determines whether the ICD-9
code provided is in short (\code{TRUE}) or decimal (\code{FALSE}) form.
Where reasonable, this is guessed from the input data.}

\item{defined}{single logical value, whether returned codes should only
include those which have definitions. Definition is based on the ICD
version being used, e.g. ICD-9-CM, the WHO version of ICD-10, or other.}

\item{billable}{single logical value, identical to 'leaf'. Leaf is preferred
as most adaptations of WHO ICD codes are not oriented around money.}

\item{leaf}{single logical value, whether to limit return codes also by
whether they are billable, i.e. leaf nodes. This is really only designed
for use with ICD-9-CM, ICD-10-CM etc, since the WHO versions are not
designed for billing, but for public health and death reporting.}
}
\value{
Returns a vector of ICD codes, with class of \code{character} and the
  class of the identified or specified ICD code, e.g. \code{icd9}
}
\description{
Expand ICD codes to all possible sub-codes, optionally limiting to those
codes which are \emph{defined} or \emph{billable} (leaf nodes).
}
\section{Methods (by class)}{
\itemize{
\item \code{character}: Get child codes, guessing ICD version and short
versus decimal format

\item \code{icd9cm}: Get children of ICD-9-CM codes

\item \code{icd9}: Get children of ICD-9 codes, based on the super-set
ICD-9-CM at present

\item \code{icd10}: Get children of ICD-10 codes (warns because this
only applies to ICD-10-CM for now).

\item \code{icd10cm}: Get children of ICD-10-CM codes

\item \code{icd10who}: Get children of ICD-10-CM codes
}}

\examples{
library(magrittr, warn.conflicts = FALSE, quietly = TRUE)
# magrittr not required by icd
# icd.data package highly recommended, but not a depependency for comorbidity calculations
if (requireNamespace("icd.data", quietly = TRUE)) {
  # no children other than self
  children("10201", short_code = TRUE, defined = FALSE)

  # guess it was ICD-9 and a short, not decimal code
  children("0032")

  # empty because 102.01 is not meaningful
  children("10201", short_code = TRUE, defined = TRUE)
  x <- children("003", short_code = TRUE, defined = TRUE)
  explain_code(x, condense = FALSE, short_code = TRUE)

  children(short_code = FALSE, "100.0")
  children(short_code = FALSE, "100.00")
  children(short_code = FALSE, "2.34")
}
}
\seealso{
Other ICD-9 ranges: \code{\link{condense}},
  \code{\link{expand_range}}
}
\concept{ICD-9 ranges}
\keyword{manip}
