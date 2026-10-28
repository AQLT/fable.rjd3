# tsibble -> ts ------------------------------------------------------------------

tsibble_to_ts <- function(.data) {
  measures <- tsibble::measured_vars(.data)
  if (length(measures) > 1) {
    abort("Seasonal adjustment only applies to a single (univariate) series.")
  }
  idx <- .data[[tsibble::index_var(.data)]]
  d   <- as.Date(idx[1])
  yr  <- as.integer(format(d, "%Y"))
  mo  <- as.integer(format(d, "%m"))

  if (inherits(idx, "yearmonth")) {
    freq <- 12L; start <- c(yr, mo)
  } else if (inherits(idx, "yearquarter")) {
    freq <- 4L;  start <- c(yr, (mo - 1L) %/% 3L + 1L)
  } else {
    abort("The index must be of class `yearmonth` or `yearquarter`.")
  }
  list(ts = stats::ts(.data[[measures]], start = start, frequency = freq),
       measure = measures)
}

as_ts_like <- function(x, template) {
  stats::ts(as.numeric(x), start = stats::start(template),
            frequency = stats::frequency(template))
}

# Look up a function in a list of packages ------------------------------------------

pkg_fun <- function(name, pkgs) {
  for (p in pkgs) {
    f <- tryCatch(getExportedValue(p, name), error = function(e) NULL)
    if (!is.null(f)) return(f)
  }
  abort(sprintf("Function `%s` not found in: %s.", name,
                paste(pkgs, collapse = ", ")))
}

# Is the Java pointer still valid? ----------------------------------------------------
# The pointer is lost after saveRDS()/readRDS() or when the object crosses a
# `future` worker. The Java object lives in the `$internal` field of the result.

jd3_alive <- function(j) {
  !is.null(j) && !is.null(j$internal) && !rJava::is.jnull(j$internal)
}

#
# # Align an indicator (a `ts` possibly shorter than the series, e.g. residuals
# # lost to differencing) on the time axis of the series `y`; NA elsewhere.
# align_to_series <- function(x, y) {
#     n <- length(y)
#     if (!stats::is.ts(x)) {                      # fallback: assume it ends with y
#         x <- as.numeric(x)
#         return(c(rep(NA_real_, max(n - length(x), 0)), utils::tail(x, n)))
#     }
#     as.numeric(stats::window(x, start = stats::start(y), end = stats::end(y),
#                              extend = TRUE))
# }

jget_arima_model <- function(jres){
    arima_model <- rjd3toolkit::user_defined(
        jres,
        sprintf("arima.%s",
                c("p","d","q","bp","bd","bq")))
    arima_model <- paste0(
        "ARIMA(",arima_model[[1]], ",",
        arima_model[[2]], ",",
        arima_model[[3]], ")(",
        arima_model[[4]], ",",
        arima_model[[5]], ",",
        arima_model[[6]], ")")
    arima_model
}

thresholds <- function(x, thresholds_pval = getOption("fable.rjd3.thresholds_pval")) {
    base::cut(
        x,
        breaks = c(0, thresholds_pval),
        labels = names(thresholds_pval)
        )
}

