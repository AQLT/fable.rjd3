# ==============================================================================
# forecast.jd3_model : forecast of the RAW series (pre-adjustment model)
#
# HISTORY / DECISIONS (so that we can find out later what was done and why)
#
# 1. Signature. fabletools calls `forecast(object$fit, new_data, specials = ,
#    times = , ...)` (source of fabletools:::forecast.mdl_ts). `h` is NOT passed
#    to the model method: fabletools builds `new_data` (future dates) from `h`,
#    so the horizon is recovered with `nrow(new_data)`.
#
# 2. Source of the numbers: the stored Java result, ids from the dictionary
#      y_f(h)  : forecast of the original series
#      y_ef(h) : forecast error (stdev) of the original series
#      l_f(h)  : forecast of the linearized series, TRANSFORMED scale (log)
#      log     : 1 if the series is log-transformed
#    Tested on AirPassengers: all.equal(ylin_f(h), exp(l_f(h))) is TRUE, so the
#    back-transformation is a plain exp() (no bias correction inside JD+):
#    y_f = exp(forecast of log y)  =>  y_f is the MEDIAN of a log-normal.
#
# 3. What y_ef is (RegSarimaModel.internalForecasts) ?
# https://github.com/jdemetra/jdplus-main/blob/d07772d0c375c2b9245dead722122396afb4dd98/jdplus-main-base/jdplus-toolkit-base-parent/jdplus-toolkit-base-core/src/main/java/jdplus/toolkit/base/core/regsarima/regular/RegSarimaModel.java#L425-L463
#      f, ef = forecast and stdev of the linearized (log) series
#      fy    = backTransform(f + pre-adjustment effects)             -> y_f
#      efy   = LogNormal.stdev(f, ef)   if log transformation         -> y_ef
#      efy   = ef                       otherwise
#    So `y_ef` is the stdev of a log-normal on the ORIGINAL scale, not the
#    stdev of the log. The log-scale stdev `ef` (what dist_lognormal() needs
#    as `sdlog`) is recovered by inverting LogNormal.stdev(m, s) with m = l_f
#    (see jd3_sdlog_from_sd()). Earlier attempts that were WRONG: sdlog =
#    y_ef / y_f (delta method, only approximate) and log1p(y_ef / y_f).
#
# 4. Bias. No `bias_correction` argument (it was considered and removed).
#    log(y) is normal and unbiased; the "bias" only appears when the
#    distribution of y is summarised by one number:
#      median = exp(m)               (= y_f)
#      mean   = exp(m + sdlog^2 / 2) (bias-corrected, grows with the horizon
#                                     because sdlog does)
#    The returned distribution is faithful to the model (median = y_f) and the
#    user chooses the summary with the `point_forecast` argument of forecast():
#      forecast(mb, h = 12)                                   # .mean: corrected
#      forecast(mb, h = 12, point_forecast = list(.median = median))  # y_f
#    Shifting the distribution so that `.mean` equals y_f was rejected: it
#    would distort the quantiles.
#    Additive case (log = 0): normal distribution, mean = median = y_f.
# ==============================================================================

# Inverse of Java's LogNormal.stdev(m, s) = sqrt((exp(s^2) - 1) * exp(2m + s^2)).
# With u = exp(s^2) and v = (sd / exp(m))^2:  (u - 1) * u = v
#   => u - 1 = 2v / (1 + sqrt(1 + 4v))   (numerically stable form)
#   => s     = sqrt(log1p(u - 1))
#' @keywords internal
#' @noRd
jd3_sdlog_from_sd <- function(sd, m) {
    v <- (sd / exp(m))^2
    sqrt(log1p(2 * v / (1 + sqrt(1 + 4 * v))))
}

#' Forecast of the raw series
#'
#' Forecasts the raw series from the pre-adjustment model (RegARIMA / TRAMO)
#' of a model fitted with [X13()] or [TRAMOSEATS()]. The values are read from
#' the stored JDemetra+ result, so the seasonal adjustment itself is not
#' affected. For the past, see [backast()].
#'
#' @section Distribution:
#' For log-transformed series, the forecast distribution is log-normal, with a
#' median equal to JDemetra+'s forecast (a plain back-transformation of the
#' forecast of the log). Its mean is therefore the bias-corrected forecast, and
#' the difference grows with the horizon. For other series, the distribution is
#' normal and its mean equals the median.
#'
#' The default point forecast `.mean` of the resulting fable is the mean of the
#' distribution. Use the `point_forecast` argument of `forecast()` to choose
#' another summary, e.g. `point_forecast = list(.median = median)` to obtain
#' JDemetra+'s forecast.
#'
#' @inheritParams jd3_model_methods_extra
#' @param new_data A tsibble of future dates, built by \pkg{fabletools} from the
#'   horizon `h`. It must start right after the end of the series.
#' @param ... Other arguments passed by `forecast()` (e.g. `times`), ignored.
#'
#' @return A distribution vector (see \pkg{distributional}) with one element per
#'   row of `new_data`: log-normal if the series is log-transformed, normal
#'   otherwise. Called through `forecast()` on a mable, the result is a fable.
#'
#' @seealso [backast()], [X13()], [TRAMOSEATS()], [jd3_indicator()] to
#'   extract the raw indicators (`y_f`, `y_ef`...).
#'
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' y  <- tsibble::as_tsibble(AirPassengers)
#' mb <- model(y, x13 = X13(value))
#'
#' # The mean is the bias-corrected forecast
#' fabletools::forecast(mb, h = 12)
#'
#' # JDemetra+'s own forecast (median of the distribution)
#' fabletools::forecast(mb, h = 12, point_forecast = list(.median = median))
#' @export
forecast.jd3_model <- function(object, new_data = NULL, ...) {
    h    <- nrow(new_data)
    jres <- get_jres(object)
    res_rjd <- rjd3toolkit::user_defined(
        jres,
        c(
            sprintf("y_f(%s)", h),
            sprintf("y_ef(%s)", h),
            "log"
        )
    )
    mu <- res_rjd[[1]]
    se <- res_rjd[[2]]
    is_log <- res_rjd[[3]] == 1

    if (is_log) {
        # log-transformed: log-normal, median = y_f
        lf    <- rjd3toolkit::result(jres, sprintf("l_f(%s)", h))
        sdlog <- jd3_sdlog_from_sd(se, lf)
        return(distributional::dist_lognormal(log(mu), sdlog))
    } else {
        # additive: normal distribution (mean = median = y_f)
        return(distributional::dist_normal(mu, se))
    }
}

#' Backcast of the raw series
#'
#' Backcasts the raw series, i.e. predicts the periods preceding its start,
#' from the pre-adjustment model of a model fitted with [X13()] or
#' [TRAMOSEATS()]. \pkg{fabletools} has no backcast generic, so this function
#' plays the role of [forecast()][forecast.jd3_model] for the past. The distribution
#' is built as for forecasts (log-normal for log-transformed series, normal
#' otherwise; see the *Distribution* section of [forecast.jd3_model]).
#'
#' @inheritParams forecast.jd3_model
#' @param h Number of periods to backcast, immediately before the start of the
#'   series.
#'
#' @return For a `jd3_model` or a `mdl_ts`, a tsibble with the `n` dates
#'   preceding the series and a distribution column `dist` (see
#'   \pkg{distributional}). For a mable, a tibble with the key columns, `.model`,
#'   the dates and `dist`, one block per model. Use `mean()` or `median()` on
#'   `dist` to get a point backcast; the median equals JDemetra+'s backcast.
#'
#' @seealso [forecast.jd3_model], [jd3_indicator()] for the raw indicators (`y_b`,
#'   `y_eb`...).
#'
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' y  <- tsibble::as_tsibble(AirPassengers)
#' mb <- model(y, x13 = X13(value))
#'
#' bc <- backast(mb, h = 12)
#' bc
#'
#' # A single model
#' bc1 <- backast(mb$x13[[1]], h = 12)
#' median(bc1$dist)
#' @export
backast <- function(object, h, ...) UseMethod("backast")

#' @rdname backast
#' @export
backast.jd3_model <- function(object, h, ...) {
    jres <- get_jres(object)
    res_rjd <- rjd3toolkit::user_defined(
        jres,
        c(
            sprintf("y_b(%s)", h),
            sprintf("y_eb(%s)", h),
            "log"
        )
    )
    mu <- res_rjd[[1]]
    se <- res_rjd[[2]]
    is_log <- res_rjd[[3]] == 1

    if (is_log) {
        # --- log-transformed: log-normal, median = y_f
        lf    <- rjd3toolkit::result(jres, sprintf("l_b(%s)", h))
        sdlog <- jd3_sdlog_from_sd(se, lf)
        dist <- distributional::dist_lognormal(log(mu), sdlog)
    } else {
        # additive: normal distribution (mean = median = y_f)
        dist <- distributional::dist_normal(mu, se)
    }
    idx   <- tsibble::index_var(object$data)
    first <- min(object$data[[idx]])
    out   <- tibble::tibble(!!idx := first - rev(seq_len(h)), dist = dist)
    tsibble::as_tsibble(out, index = !!rlang::sym(idx))
}

#' @rdname backast
#' @export
backast.mdl_ts <- function(object, h, ...) backast(jd3_model(object), h)

#' @rdname backast
#' @export
backast.mdl_df <- function(object, h, ...) {
    mv   <- fabletools::mable_vars(object)
    keys <- tibble::as_tibble(object)[setdiff(names(object), mv)]
    blocks <- lapply(mv, function(m) {
        lapply(seq_along(object[[m]]), function(i) {
            bc <- tibble::as_tibble(backast(jd3_model(object[[m]][[i]]), h))
            tibble::tibble(keys[i, , drop = FALSE], .model = m, bc)
        })
    })
    bind_blocks(unlist(blocks, recursive = FALSE))
}
#' @keywords internal
#' @noRd
bind_blocks <- function(blocks) {
    cols <- names(blocks[[1]])
    out  <- lapply(cols, function(col) {
        do.call(c, unname(lapply(blocks, `[[`, col)))
    })
    names(out) <- cols
    tibble::as_tibble(out)
}
