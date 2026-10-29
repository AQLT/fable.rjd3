
# Number of months between two consecutive observations of an index:
# 1 monthly, 2 bimonthly, 3 quarterly, 4 four-monthly, 6 semi-annual, 12 annual.
#' @keywords internal
#' @noRd
jd3_step_months <- function(idx) {
  d <- as.Date(idx)
  m <- as.integer(format(d, "%Y")) * 12L + as.integer(format(d, "%m"))
  step <- unique(diff(m))
  if (length(step) != 1L) {
    abort("The series must be regular: at least two observations and a constant interval are required.")
  }
  if (12L %% step != 0L) {
    abort(sprintf("The interval between observations (%d months) must divide a year.", step))
  }
  step
}

# Step of an index in its own unit (months for yearmonth, quarters for yearquarter):
# the number to add to a date to get the next observation.
#' @keywords internal
#' @noRd
jd3_step_units <- function(idx) {
  step <- jd3_step_months(idx)
  if (inherits(idx, "yearquarter")) step %/% 3L else step
}

# The frequency is deduced from the interval, not from the class of the index: a
# `yearmonth` index with a step of 2 months is a bimonthly series (frequency 6),
# with a step of 6 months a semi-annual series (frequency 2).
#' @keywords internal
#' @noRd
tsibble_to_ts <- function(.data) {
  measures <- tsibble::measured_vars(.data)
  if (length(measures) > 1) {
    abort("Seasonal adjustment only applies to a single (univariate) series.")
  }
  idx <- .data[[tsibble::index_var(.data)]]
  if (!inherits(idx, c("yearmonth", "yearquarter"))) {
    abort(paste0("The index must be of class `yearmonth` or `yearquarter`, with an ",
                 "interval dividing a year (monthly, bimonthly, quarterly, ",
                 "four-monthly or semi-annual series)."))
  }
  step <- jd3_step_months(idx)
  freq <- 12L %/% step

  d  <- as.Date(idx[1])
  yr <- as.integer(format(d, "%Y"))
  mo <- as.integer(format(d, "%m"))
  if ((mo - 1L) %% step != 0L) {
    abort(sprintf(
      "With an interval of %d months, the first observation must be in month %s.",
      step, paste(seq(1L, 12L, by = step), collapse = ", ")
    ))
  }
  list(ts = stats::ts(.data[[measures]], start = c(yr, (mo - 1L) %/% step + 1L),
                      frequency = freq),
       measure = measures)
}

# A `ts` (frequency 1, 2, 3, 4, 6 or 12) as a tibble with columns `index`
# (yearquarter if quarterly, yearmonth otherwise) and `value`.
#' @keywords internal
#' @noRd
ts_to_tbl <- function(x) {
  f <- stats::frequency(x)
  if (f < 1 || 12 %% f != 0) {
    abort(sprintf("A frequency of %s is not supported: it must divide 12.", f))
  }
  st <- stats::start(x)
  k  <- seq_along(x) - 1 + (st[2L] - 1)                 # 0-based period count
  yr <- st[1L] + k %/% f
  mo <- (k %% f) * (12 / f) + 1
  d  <- as.Date(sprintf("%d-%02d-01", as.integer(yr), as.integer(mo)))
  idx <- if (f == 4) tsibble::yearquarter(d) else tsibble::yearmonth(d)
  tibble::tibble(index = idx, value = as.numeric(x))
}

#' @keywords internal
#' @noRd
as_ts_like <- function(x, template) {
  stats::ts(as.numeric(x), start = stats::start(template),
            frequency = stats::frequency(template))
}

# Look up a function in a list of packages ------------------------------------------
#' @keywords internal
#' @noRd
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
#' @keywords internal
#' @noRd
jd3_alive <- function(j) {
  !is.null(j) && !is.null(j$internal) && !rJava::is.jnull(j$internal)
}
# Access the Java object (re-estimated on demand if the pointer is dead) ----------
#' @keywords internal
#' @noRd
get_jres <- function(object) {
    if (!jd3_alive(object$cache$jres)) {
        object$cache$jres <- run_jd3(
            object$engine, object$y, object$spec,
            object$context
        )
    }
    object$cache$jres
}
#' @keywords internal
#' @noRd
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
#' @keywords internal
#' @noRd
thresholds <- function(x, thresholds_pval = getOption("fable.rjd3.thresholds_pval")) {
    base::cut(
        x,
        breaks = c(0, thresholds_pval),
        labels = names(thresholds_pval),
        include.lowest = TRUE      # a p-value of exactly 0 belongs to the first class
        )
}

