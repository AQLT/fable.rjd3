#' fable.rjd3: 'fabletools' Interface to JDemetra+ v3 Seasonal Adjustment
#'
#' Seasonal adjustment of `tsibble` series with X-13ARIMA-SEATS ([X13()]) and
#' TRAMO-SEATS ([TRAMOSEATS()]), using the JDemetra+ v3 R packages
#' \pkg{rjd3x13} and \pkg{rjd3tramoseats}.
#'
#' Models store the underlying Java object, so any indicator available in
#' JDemetra+ can be extracted with [jd3_indicator()] and listed with
#' [jd3_dictionary()]. The usual `fabletools` verbs work on the fitted
#' mable: [components()][jd3_model_methods], [glance()][jd3_model_methods],
#' [tidy()][jd3_model_methods] and [report()][jd3_model_methods].
#'
#' @keywords internal
#' @import fabletools
#' @importFrom generics components tidy glance
#' @importFrom rlang abort expr sym enexprs as_label
"_PACKAGE"
