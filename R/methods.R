#' Extract the model object from a fitted mable cell
#'
#' Returns the `jd3_model` object stored in a fitted model. It is mostly useful
#' for programming; [jd3_indicator()] and [jd3_dictionary()] call it
#' internally.
#'
#' @param x A `mdl_ts` (e.g. `mb$x13[[1]]`) or a `jd3_model`.
#'
#' @return A `jd3_model` object: a list holding the data (a tsibble), the
#'   series (`ts`), the final specification (`spec`), the reference
#'   specification (`ref_spec`), the modelling context, the engine, the name of
#'   the response and a cache for the Java result.
#'
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' mb <- model(tsibble::as_tsibble(AirPassengers), x13 = X13(value))
#' m <- jd3_model(mb$x13[[1]])
#' class(m)
#' @export
jd3_model <- function(x) {
    if (inherits(x, "jd3_model")) x
    else if (inherits(x, "mdl_ts")) x[["fit"]]
    else abort("`x` must be a `mdl_ts` or a `jd3_model`.")
}

#' Methods for fitted JDemetra+ models
#'
#' Standard `fabletools` / `generics` verbs for models fitted with [X13()],
#' [TRAMOSEATS()], [REGARIMA()] and [TRAMO()]. They can be applied directly on a
#' mable. `components()` is only available for the seasonal adjustment models
#' ([X13()] and [TRAMOSEATS()]).
#'
#' @param object,x A `jd3_model` (usually accessed through a mable).
#' @inheritParams stats::printCoefmat
#' @param thresholds_pval Threshold used to interpret p-values statistic test.
#' By default `c(Severe = 0.001, Bad = 0.01, Uncertain = 0.05, Good = Inf)`.
#' @inheritParams X13
#'
#' @return
#' * `components()`: a `dable` with the response and the columns `trend`,
#'   `seasonal`, `irregular` and `season_adjust`.
#' * `glance()`: a one-row tibble of diagnostics.
#' * `tidy()`: a tibble with one row per coefficient (ARIMA parameters,
#'   regression variables, outliers, calendar effects) and the columns `term`,
#'   `estimate`, `std.error`, `statistic` and `p.value`. Coefficients fixed in
#'   the specification are included, with missing standard errors and tests.
#' * `report()`: invisibly, the model; prints the decomposition mode or the
#'   transformation, the number of observations, the coefficients, the tests on
#'   the residuals and, for seasonal adjustment models, the quality diagnostics
#'   (M and Q statistics, residual seasonality tests on the adjusted series).
#' * `model_sum()`: a short string describing the model.
#'
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' mb <- model(tsibble::as_tsibble(AirPassengers), x13 = X13(value))
#' components(mb)
#' glance(mb)
#' tidy(mb)
#' report(mb)
#' @name jd3_model_methods
NULL

#' @importFrom rlang list2 parse_expr `:=`
#' @rdname jd3_model_methods
#' @export
components.jd3_sa_model <- function(object, ...){
    jres <- get_jres(object)
    res_rjd <- rjd3toolkit::user_defined(
        jres,
        c("sa", "t", "s", "i", "sa", "mode")
    )

    out <- object$data
    resp <- object$resp

    out$trend         <- res_rjd$t
    out$seasonal      <- res_rjd$s
    out$irregular     <- res_rjd$i
    out$season_adjust <- res_rjd$sa
    mode <- tolower(res_rjd$mode)
    y_expr <- switch(
        mode,
        additive       = quote(trend + seasonal + irregular),
        multiplicative = quote(trend * seasonal * irregular),   # <- to adjust for X-11?
        logadditive    = quote(trend * seasonal * irregular),
        pseudoadditive = quote(trend * (seasonal + irregular - 1)),
        rlang::parse_expr("f(trend, seasonal, irregular)")
    )
    sa_expr <- switch(
        mode,
        additive       = quote(trend + irregular),
        multiplicative = quote(trend * irregular),              # <- idem
        logadditive    = quote(trend * irregular),
        pseudoadditive = quote(trend * irregular),
        rlang::parse_expr("f(trend, irregular)")
    )
    aliases <- rlang::list2(
        !!resp := y_expr,
        season_adjust = sa_expr
    )

    dcmp <- fabletools::as_dable(
        out, method = object$engine$method,
        resp = !!sym(object$resp),
        seasons = list(seasonal = "year"),
        aliases = aliases
    )
    dcmp
}

#' @rdname jd3_model_methods
#' @export
model_sum.jd3_model <- function(x) {
    jres <- get_jres(x)
    arima_model <- jget_arima_model(jres)
    sprintf("%s, %s", x$engine$method, arima_model)
}



#' @keywords internal
#' @noRd
get_fixed_coefficients <- function(spec) {
    if (!is.null(spec$regarima)) {
        spec <- spec$regarima
    }
    if (!is.null(spec$tramo)) {
        spec <- spec$tramo
    }
    res <- NULL
    ud_td <-
        ud_lpy <-
        ud_easter <-
        ud_out <-
        ud_ramps <-
        ud_users <-
        NULL

    if (length(spec$regression$td$users) > 0) {
        ud_td <- tibble::tibble(
            term = spec$regression$td$users,
            estimate = unlist(spec$regression$td$tdcoefficients["value",]),
            std.error = NA_real_,
            statistic = NA_real_,
            p.value = NA_real_
        )
        ud_td <- ud_td[unlist(spec$regression$td$tdcoefficients["type",]) == "FIXED",]

    }
    if (! (is.null(spec$regression$td$lpcoefficient) ||
           spec$regression$td$lpcoefficient$type != "FIXED")) {
        ud_lpy <- tibble::tibble(
            term = "Leap year",
            estimate = spec$regression$td$lpcoefficient$value,
            std.error = NA_real_,
            statistic = NA_real_,
            p.value = NA_real_
        )
    }
    if (! (is.null(spec$regression$easter$coef) ||
           spec$regression$easter$coef$type != "FIXED")) {
        ud_easter <- tibble::tibble(
            term = "easter",
            estimate = spec$regression$easter$coef$value,
            std.error = NA_real_,
            statistic = NA_real_,
            p.value = NA_real_
        )
    }

    ud_out <- get_fixed_outliers(spec)

    if (length(spec$regression$ramps) > 0) {
        ud_ramps <- do.call(rbind, lapply(spec$regression$ramps, function(ramp){
            if (is.null(ramp$coef) || ramp$coef$type != "FIXED") {
                NULL
            } else {
                tibble::tibble(
                    term = ramp$name,
                    estimate = ramp$coef$value,
                    std.error = NA_real_,
                    statistic = NA_real_,
                    p.value = NA_real_
                )
            }
        }))
    }
    if (length(spec$regression$users) > 0) {
        ud_users <- do.call(rbind, lapply(spec$regression$users, function(x){
            if (is.null(x$coef) || x$coef$type != "FIXED") {
                NULL
            } else {
                tibble::tibble(
                    term = x$name,
                    estimate = x$coef$value,
                    std.error = NA_real_,
                    statistic = NA_real_,
                    p.value = NA_real_
                )
            }
        }))
    }

    all_var <- rbind(ud_td, ud_lpy, ud_easter, ud_out, ud_ramps, ud_users)

    if (is.null(all_var)){
        tibble::tibble(
            term = character(),
            estimate = double(), std.error = double(),
            statistic = double(), p.value = double()
        )
    } else {
        all_var
    }
}
#' @keywords internal
#' @noRd
get_arima_coef <- function(jres){
    coef_arima <- rjd3toolkit::user_defined(
        jres,
        c("arima.theta(*)",
          "arima.phi(*)",
          "arima.btheta(*)",
          "arima.bphi(*)")
    )
    for (i in seq_along(coef_arima)) {
        if (!is.null(coef_arima[[i]])) {
            terms <- gsub("(arima\\.)|(\\(.*))", "", names(coef_arima[i]))
            terms <- sprintf("%s(%i)", terms, seq_len(nrow(coef_arima[[i]])))
            coef_arima[[i]] <- data.frame(
                terms,
                coef_arima[[i]]
            )
            colnames(coef_arima[[i]]) <- c(
                "term", "estimate", "std.error",
                "statistic", "p.value"
            )
        }
    }
    coef_arima <- do.call(rbind, coef_arima)
    rownames(coef_arima) <- NULL
    if (is.null(coef_arima)){
        tibble::tibble(
            term = character(),
            estimate = double(), std.error = double(),
            statistic = double(), p.value = double()
        )
    } else {
        tibble::as_tibble(coef_arima)
    }

}
#' @rdname jd3_model_methods
#' @export
tidy.jd3_model <- function(x, ...) {
    jres <- get_jres(x)
    res_rjd <- rjd3toolkit::user_defined(
        jres,
        c(
            "regression.details.description",
            "regression.description",
            "regression.details.coefficients",
            # "regression.details.type",
            # "regression.type",
            "regression.details.covar",
            "likelihood.df",
            "regression.ml.pcovar"
        )
    )

    term <- res_rjd[["regression.details.description"]]
    term[term == "const"] <- "Constant"
    term_glob <- res_rjd[["regression.description"]]
    est  <- res_rjd[["regression.details.coefficients"]]
    cov  <- res_rjd[["regression.details.covar"]]
    cov_ar  <- res_rjd[["regression.ml.pcovar"]]
    df   <- res_rjd[["likelihood.df"]]

    coef_arima <- get_arima_coef(jres)

    if (length(term_glob) == 0 && nrow(coef_arima) == 0)  {
        return(
            tibble::tibble(
                term = character(),
                estimate = double(), std.error = double(),
                statistic = double(), p.value = double()
            )
        )
    }
    fixed_coeff <- get_fixed_coefficients(x$spec)
    if (!is.null(fixed_coeff)){
        fixed_coeff <-
            fixed_coeff[fixed_coeff$term %in% setdiff(term_glob, term),]
    }
    se   <- sqrt(diag(as.matrix(cov)))
    t <- est / se

    est_coeff <- tibble::tibble(
        term = as.character(term),
        estimate = est, std.error = se, statistic = t,
        p.value = 2 * stats::pt(abs(t), df, lower.tail = FALSE)
    )

    tibble::as_tibble(rbind(
        coef_arima,
        est_coeff,
        fixed_coeff
    ))
}

#' @rdname jd3_model_methods
#' @export
report.jd3_model <- function(
        object,
        digits = max(3L, getOption("digits") - 3L),
        signif.stars = getOption("show.signif.stars"),
        thresholds_pval = getOption("fable.rjd3.thresholds_pval"),
        ...) {
    jres <- get_jres(object)
    arima_model <- jget_arima_model(jres)
    # a data frame, not a tibble: the terms are used as row names below, and
    # tibbles do not support row names
    reg_coef <- as.data.frame(tidy(object))
    colnames(reg_coef)[-1] <- c("Estimate", "Std. Error", "z value", "Pr(>|z|)")
    rownames(reg_coef) <- make.unique(reg_coef$term)
    reg_coef$term <- NULL

    # cat("Series:", object$resp, "\n")
    # cat("Model:", object$engine$method,",", arima_model, "\n")
    if (inherits(object, "jd3_sa_model")) {
        cat("Mode:", rjd3toolkit::result(jres, "mode"))
    } else {
        cat(
            "Transformation:",
            ifelse(rjd3toolkit::result(jres, "log") == 1, "Log", "None")
        )
    }
    cat("; N obs.:", rjd3toolkit::result(jres, "span.n"), "\n")

    cat("\n\nCoefficients\n")
    if (nrow(reg_coef) == 0L) {
        cat("No coefficient\n")
    } else {
        cat(utils::capture.output(
            stats::printCoefmat(
                reg_coef, digits = digits,
                signif.stars = signif.stars, na.print = "NA"
            )),
            sep = "\n"
        )
    }

    cat("\n")
    lb <- rjd3toolkit::result(jres, "residuals.lb")$pvalue
    normality <- rjd3toolkit::result(jres, "residuals.doornikhansen")$pvalue
    cat("Tests on residuals:",
        sprintf(
            "Independence (Ljung-Box: %s, %.3f);",
            thresholds(lb, thresholds_pval),
            lb),
        sprintf(
            "Normality (Doornik-Hansen: %s, %.3f)",
            thresholds(normality, thresholds_pval),
            normality)
    )

    if (inherits(object, "X13")) {
        q <- rjd3toolkit::result(jres, "m-statistics.q")
        qm2 <- rjd3toolkit::result(jres, "m-statistics.q-m2")
        sf <- rjd3toolkit::result(jres, "decomposition.seasonal-filters")
        tf <- rjd3toolkit::result(jres, "decomposition.d7-trend-filter")
        cat("\nFilters: ", sf,", H-",tf,"; ", sep = "")
        cat(sprintf(
            "M-Statistics: q (%s, %.3f); q-m2 (%s, %.3f)\n",
            ifelse(q <= 1, "Good", "Bad"), q,
            ifelse(qm2 <= 1, "Good", "Bad"), qm2))
    } else if (inherits(object, "TRAMOSEATS")) {
        seas_var <- rjd3toolkit::result(jres, "seats.svar-pvalue")
        irr_var <- rjd3toolkit::result(jres, "seats.ivar-pvalue")
        seas_irr_corr <- rjd3toolkit::result(jres, "seats.sicorr-pvalue")
        cat("\n")
    cat("Seats variance/cross-corr.:",
        sprintf(
            "seas (%s, %.3f); irr (%s, %.3f); seas/irr (%s, %.3f)",
            thresholds(seas_var, thresholds_pval), seas_var,
            thresholds(irr_var, thresholds_pval), irr_var,
            thresholds(seas_irr_corr, thresholds_pval), seas_irr_corr
        )
    )
    }
    if (inherits(object, "jd3_sa_model")) {
        qs <- rjd3toolkit::result(jres, "diagnostics.seas-sa-qs")$pvalue
        ftest <- rjd3toolkit::result(jres, "diagnostics.seas-sa-f")$pvalue
        cbt <- rjd3toolkit::result(jres, "diagnostics.seas-sa-combined")
        cbt_lasty <- rjd3toolkit::result(jres, "diagnostics.seas-sa-combined3")
        cat("Tests on SA:",
            sprintf(
                "QS (%s, %.3f);",
                thresholds(qs, thresholds_pval),
                qs),
            sprintf(
                "F-test (%s, %.3f)",
                thresholds(ftest, thresholds_pval),
                ftest)
        )
        cat("\n")
        cat(sprintf(
            "Combined test on SA: %s (last years: %s)",
            cbt, cbt_lasty
        ))
        if (rjd3toolkit::result(jres, "period") == 12){
            ftest_td <- rjd3toolkit::result(jres, "diagnostics.td-sa-all")$pvalue
            cat("\n")
            cat(sprintf(
                "Residual trading days on SA (F-test): %s (%.3f)",
                thresholds(ftest_td, thresholds_pval),
                ftest_td))
        }
    }
    invisible(object)
}

#' Fitted values, residuals, interpolation and updating of JDemetra+ models
#'
#' Methods for models fitted with [X13()], [TRAMOSEATS()], [REGARIMA()] or
#' [TRAMO()]. They can be applied directly on a mable.
#'
#' @details
#' * `fitted()` returns the one-step-ahead fitted values of the pre-adjustment
#'   model, on the scale of the series. Together with `residuals()`, it makes
#'   `augment()` and `accuracy()` work.
#' * `residuals()` returns the innovation residuals of the pre-adjustment model
#'   (`type = "innovation"`) or the linearized series the ARIMA part is applied
#'   to (`type = "regression"`). Dates for which a residual is not defined
#'   (e.g. lost to differencing) are `NA`.
#' * `interpolate()` replaces the missing values of the series by the
#'   estimates of the model. `new_data` must cover the same dates as the data
#'   used to fit the model.
#' * `refit()` applies the model to new data, using a JDemetra+ refresh policy
#'   (see [rjd3x13::x13_refresh()] and [rjd3tramoseats::tramoseats_refresh()]):
#'   the specification is refreshed from the estimated model and the
#'   reference specification stored in the model (see the `ref_spec` argument
#'   of [X13()]).
#' * `stream()` appends new observations to the data of the model and refreshes
#'   it in the same way. `new_data` contains the new observations only.
#'
#' @param object A fitted `jd3_model` (usually a column of a mable).
#' @param new_data A tsibble. For `interpolate()`, the data with missing values
#'   (same dates as the data of the model). For `refit()`, the new full data. For
#'   `stream()`, the new observations only.
#' @param specials Currently unused.
#' @param type Residual type: `"innovation"` (default) or `"regression"`.
#' @param policy Refresh policy, a character string (see the functions above for
#'   the available policies; default `"Fixed"`: the estimated parameters are
#'   kept).
#' @inheritParams rjd3x13::refresh
#' @inheritParams jd3_model_methods
#'
#' @return
#' * `fitted()`, `residuals()`: a numeric vector with one value per observation
#'   (`NA` where undefined). Called on a mable, a tibble with the index and the
#'   `.fitted` or `.resid` column.
#' * `interpolate()`: `new_data` with the missing values filled in.
#' * `refit()`, `stream()`: a `jd3_model` fitted on the new data. Called on a
#'   mable, a mable.
#'
#' @seealso [X13()], [TRAMOSEATS()], [forecast.jd3_model()], [jd3_model_methods]
#'
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' y  <- as_tsibble(AirPassengers)
#' mb <- model(y, x13 = X13(value))
#'
#' # Fitted values and residuals (also used by augment() and accuracy())
#' fitted(mb)
#' residuals(mb)                         # innovation residuals
#' residuals(mb, type = "regression")    # linearized series
#' augment(mb)
#' accuracy(mb)
#'
#' # Interpolation of missing values
#' y_na <- y
#' y_na$value[c(20, 21)] <- NA
#' mb_na <- model(y_na, x13 = X13(value))
#' interpolate(mb_na, y_na)
#'
#' # Updating a model when new observations arrive
#' start_new <- yearmonth("1960 Jan")
#' y_old  <- y[y$index < start_new, ]
#' y_new  <- y[y$index >= start_new, ]
#' mb_old <- model(y_old, x13 = X13(value))
#'
#' # stream(): append the new observations, estimated parameters kept
#' mb_ext <- stream(mb_old, y_new)
#' components(mb_ext)
#'
#' # refit(): apply the model to the full data
#' refit(mb_old, y)                      # refresh policy "Fixed" (default)
#' @name jd3_model_methods_extra
NULL


#' @importFrom stats  window start
#' @rdname jd3_model_methods_extra
#' @export
fitted.jd3_model <- function(object, ...) {
    # One-step-ahead fitted values on the scale of the series: z_t - e_t on the
    # transformed scale (z = log(yc) if log-transformed, else yc).
    # CHECK: `full_res` assumed to be the unstandardized one-step errors on the
    # transformed scale. If it is standardized, multiply by `residuals.ser`.
    jres <- get_jres(object)
    yc <- rjd3toolkit::result(jres, "yc")
    e <- rjd3toolkit::result(jres, "full_res")
    is_log <- rjd3toolkit::result(jres, "log") == 1
    if (is_log) {
        fitted <- exp(log(yc) - e)
    } else {
        fitted <- yc - e
    }

    window(fitted, start = start(object$y), extend = TRUE)
}

#' @rdname jd3_model_methods_extra
#' @export
residuals.jd3_model <- function(object, type = c("innovation", "regression"), ...) {
    type <- match.arg(type)
    # innovation: RegARIMA residuals (all dates, NA when not defined)
    # regression: linearized series `l` (transformed series minus regression
    #             effects), i.e. the series the ARIMA part is applied to
    id <- switch(type, innovation = "full_res", regression = "l")
    jres <- get_jres(object)
    res <- rjd3toolkit::result(jres, id)
    window(res, start = start(object$y), extend = TRUE)
}

#' @rdname jd3_model_methods_extra
#' @export
interpolate.jd3_model <- function(object, new_data = NULL, specials = NULL, ...) {
    out <- object$data
    if (!is.null(new_data)) {
        idx <- tsibble::index_var(out)
        if (!identical(new_data[[idx]], out[[idx]])) {
            abort("`new_data` must cover the same dates as the data used to fit the model.")
        }
        out <- new_data           # keep what the user passed, e.g. extra columns
    }
    resp <- tsibble::measured_vars(object$data)[1]
    miss <- is.na(out[[resp]])
    if (any(miss)) {
        jres <- get_jres(object)
        interpolate_d <- rjd3toolkit::result(
            jres,
            "yc"
        )
        # `yc` can be shorter than the series (e.g. series span): align it
        interpolate_d <- as.numeric(stats::window(
            interpolate_d,
            start = stats::start(object$y), end = stats::end(object$y),
            extend = TRUE
        ))
        out[[resp]][miss] <- interpolate_d[miss]
    }
    out
}

# ------------------------------------------------------------------------------
# refit() / stream(): apply the model to new data (refresh policies)
# ------------------------------------------------------------------------------
#' @keywords internal
#' @noRd
jd3_refit_impl <- function(
        object, .data,
        policy = c(
            "Fixed",
            "FreeParameters", "Complete",
            "Outliers_StochasticComponent", "Outliers",
            "FixedParameters", "FixedAutoRegressiveParameters",
            "Current"
        ),
        period = 0,
        start = NULL,
        end = NULL
) {
    prep <- tsibble_to_ts(.data)
    spec <- jd3_refresh_spec(
        object, policy, period, start, end
    )
    jres <- run_jd3(object$engine, prep$ts, spec, object$context)

    make_jd3_model(
        .data = .data,
        jres = jres,
        spec = spec,
        ref_spec = object$ref_spec,
        context = object$context,
        engine =  object$engine,
        name = class(object)[1],
        extra_class = class(object)[-1]
    )
}

# Result specification (estimated parameters): obtained by re-estimating with the
# R function (x13() / tramoseats()) and cached in the object (survives saveRDS).
#' @keywords internal
#' @noRd
jd3_result_spec <- function(object) {
    if (is.null(object$cache$result_spec)) {
        jfun <- object$engine$jfun
        rfun <- substr(jfun, 2, nchar(jfun))
        est_fun    <- pkg_fun(rfun, object$engine$pkg)
        object$cache$result_spec <- est_fun(
            ts = object$y,
            spec = object$spec,
            context = object$context
        )$result_spec

    }
    object$cache$result_spec
}
#' @keywords internal
#' @noRd
jd3_refresh_spec <- function(
        object,
        policy = c(
            "Fixed",
            "FreeParameters", "Complete",
            "Outliers_StochasticComponent", "Outliers",
            "FixedParameters", "FixedAutoRegressiveParameters",
            "Current"
        ),
        period = 0,
        start = NULL,
        end = NULL
) {
    choices <- c("FreeParameters", "Complete", "Outliers_StochasticComponent",
                 "Outliers", "FixedParameters", "FixedAutoRegressiveParameters",
                 "Fixed", "Current")
    matched_idx <- which(tolower(policy)[1] == tolower(choices))

    if (length(matched_idx) == 0) {
        stop(sprintf("Argument 'policy' invalid. Accepted values: %s",
                     paste(choices, collapse = ", ")))
    }
    policy <- choices[matched_idx]
    refresh_fun <- pkg_fun(object$engine$refresh_fun, object$engine$pkg)
    refresh_fun(
        jd3_result_spec(object),
        refspec = object$ref_spec,
        policy = policy,
        period = period,
        start = start,
        end = end
    )
}

#' @rdname jd3_model_methods_extra
#' @export
refit.jd3_model <- function(
        object, new_data, specials = NULL,
        policy = c(
            "Fixed",
            "FreeParameters", "Complete",
            "Outliers_StochasticComponent", "Outliers",
            "FixedParameters", "FixedAutoRegressiveParameters",
            "Current"
        ),
        period = 0,
        start = NULL,
        end = NULL,
        ...
) {
    jd3_refit_impl(
        object = object, .data = new_data, policy = policy,
        period = period, start = start, end = end
    )
}

#' @rdname jd3_model_methods_extra
#' @export
stream.jd3_model <- function(
        object, new_data, specials = NULL,
        policy = c(
            "Fixed",
            "FreeParameters", "Complete",
            "Outliers_StochasticComponent", "Outliers",
            "FixedParameters", "FixedAutoRegressiveParameters",
            "Current"
        ),
        period = 0, start = NULL, end = NULL, ...
) {
    idx  <- tsibble::index_var(object$data)
    resp <- object$resp
    old  <- tibble::as_tibble(object$data)[c(idx, resp)]
    new  <- tibble::as_tibble(new_data)[c(idx, resp)]

    # the new observations must follow the series immediately
    if (min(new[[idx]]) != max(old[[idx]]) + jd3_step_units(old[[idx]])) {
        abort("`new_data` must start right after the end of the data of the model.")
    }
    full <- tsibble::as_tsibble(rbind(old, new), index = idx)
    jd3_refit_impl(
        object = object, .data = full, policy = policy,
        period = period, start = start, end = end
    )
}
