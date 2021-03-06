# this is common code to all the tests, each of which runs test_check with a different filter:
library("icd")
if (!require("icd.data")) message("Testing without icd.data installed")
if (!requireNamespace("icd.data", versionCheck = ">= 1.1")) {
  message("Testing without icd.data >= 1.1 installed")
}
library("testthat", warn.conflicts = FALSE, quietly = TRUE)
# Set ICD_TEST_SLOW to yes/true to run slow tests
if (identical(Sys.getenv("NOT_CRAN"), "false")) {
  options(icd.data.offline = TRUE)
  options(icd.data.absent_action = "stop")
  # ensure we don't write a temporary directory we don't clean up
  options(icd.data.resource = NA)
}
testthat::test_check("icd")
