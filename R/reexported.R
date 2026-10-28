# ==============================================================================
# R/reexports.R : functions re-exported so that users only need library(fable.rjd3)
#
# Origin of each generic (CHECK with the snippet at the end of the file: a wrong
# origin makes devtools::document() fail with "'x' is not an exported object
# from 'namespace:pkg'"; just move the line to the right section).
#
# Re-exported objects are identical to the originals, so loading fablejd3 and
# fabletools / fpp3 together gives no "masked from" warnings.
# DESCRIPTION: fabletools, generics, ggplot2, distributional, tsibble in Imports.
# ==============================================================================

# --- fabletools -----------------------------------------------------------------

#' @importFrom fabletools model
#' @export
fabletools::model

#' @importFrom fabletools report
#' @export
fabletools::report

#' @importFrom fabletools accuracy
#' @export
fabletools::accuracy

#' @importFrom fabletools stream
#' @export
fabletools::stream

#' @importFrom fabletools outliers
#' @export
fabletools::outliers

#' @importFrom fabletools model_sum
#' @export
fabletools::model_sum

# --- generics (verbs of the modelling framework) ----------------------------------

#' @importFrom generics forecast
#' @export
generics::forecast

#' @importFrom generics components
#' @export
generics::components

#' @importFrom generics glance
#' @export
generics::glance

#' @importFrom generics tidy
#' @export
generics::tidy

#' @importFrom generics augment
#' @export
generics::augment

#' @importFrom generics interpolate
#' @export
generics::interpolate

#' @importFrom generics refit
#' @export
generics::refit

# --- plotting and distributions ---------------------------------------------------

#' @importFrom ggplot2 autoplot
#' @export
ggplot2::autoplot

#' @importFrom distributional hilo
#' @export
distributional::hilo

# --- tsibble: needed to build the input data (optional, remove if unwanted) ------

#' @importFrom tsibble as_tsibble
#' @export
tsibble::as_tsibble

#' @importFrom tsibble tsibble
#' @export
tsibble::tsibble

#' @importFrom tsibble yearmonth
#' @export
tsibble::yearmonth

#' @importFrom tsibble yearquarter
#' @export
tsibble::yearquarter

#' @importFrom tsibble new_data
#' @export
tsibble::new_data
