.engines <- list(
    X13 = list(
        pkg = "rjd3x13", jfun = "jx13",
        spec_fun = "x13_spec", refresh_fun = "x13_refresh",
        method = "X-13ARIMA",
        unsupported = "seats",
        id_glance = c(
            aicc = "likelihood.aicc",
            nobs = "likelihood.nobs",
            nparams = "likelihood.nparams",
            nout = "regression.nout",
            lb = "residuals.lb",                      # Ljung-Box test
            normality = "residuals.doornikhansen",    # Doornik-Hansen normality test,
            ftest_sa = "diagnostics.seas-sa-f",
            qs_test_sa = "diagnostics.seas-sa-qs",
            combined_test_sa = "diagnostics.seas-sa-combined",
            combined_test_sa_lastyears = "diagnostics.seas-sa-combined3",
            td_on_sa = "diagnostics.td-sa-all",
            Q = "m-statistics.q", Q_M2 = "m-statistics.q-m2"
        )
    ),
    TRAMOSEATS = list(
        pkg = "rjd3tramoseats", jfun = "jtramoseats",
        spec_fun = "tramoseats_spec", refresh_fun = "tramoseats_refresh",
        method = "TRAMO-SEATS",
        unsupported = "x11",
        id_glance = c(
            aicc = "likelihood.aicc",
            nobs = "likelihood.nobs",
            nparams = "likelihood.nparams",
            nout = "regression.nout",
            lb = "residuals.lb",                      # Ljung-Box test
            normality = "residuals.doornikhansen",    # Doornik-Hansen normality test,
            ftest_sa = "diagnostics.seas-sa-f",
            qs_test_sa = "diagnostics.seas-sa-qs",
            combined_test_sa = "diagnostics.seas-sa-combined",
            combined_test_sa_lastyears = "diagnostics.seas-sa-combined3",
            td_on_sa = "diagnostics.td-sa-all",
            seas_var = "seats.svar-pvalue",
            irr_var = "seats.ivar-pvalue",
            seas_irr_corr = "seats.sicorr-pvalue"
        )
    ),
    REGARIMA = list(
        pkg = "rjd3x13", jfun = "jregarima",
        spec_fun = "regarima_spec", refresh_fun = "regarima_refresh",
        method = "REGARIMA",
        unsupported = c("x11", "seats", "benchmarking"),
        id_glance = c(
            aicc = "likelihood.aicc",
            nobs = "likelihood.nobs",
            nparams = "likelihood.nparams",
            nout = "regression.nout",
            lb = "residuals.lb",                      # Ljung-Box test
            normality = "residuals.doornikhansen",    # Doornik-Hansen normality test,
            ftest_sa = "diagnostics.seas-sa-f",
            qs_test_sa = "diagnostics.seas-sa-qs",
            combined_test_sa = "diagnostics.seas-sa-combined",
            combined_test_sa_lastyears = "diagnostics.seas-sa-combined3",
            td_on_sa = "diagnostics.td-sa-all"
        )
    ),
    TRAMO = list(
        pkg = "rjd3tramoseats", jfun = "jtramo",
        spec_fun = "tramo_spec", refresh_fun = "tramo_refresh",
        method = "TRAMO",
        unsupported = c("x11", "seats", "benchmarking"),
        id_glance = c(
            aicc = "likelihood.aicc",
            nobs = "likelihood.nobs",
            nparams = "likelihood.nparams",
            nout = "regression.nout",
            lb = "residuals.lb",                      # Ljung-Box test
            lb2 = "residuals.lb2",                      # Ljung-Box test
            normality = "residuals.doornikhansen"    # Doornik-Hansen normality test,
        )
    )
)

# Run the estimation and return the Java result
#' @keywords internal
#' @noRd
run_jd3 <- function(engine, y, spec, context = NULL, ...) {
    f    <- pkg_fun(engine$jfun, engine$pkg)
    args <- list(y, spec = spec)
    if (!is.null(context))     args$context     <- context
    do.call(f, args)
}

# Generic training function
#' @keywords internal
#' @noRd
make_jd3_model <- function(
        .data, jres,
        spec, context,
        engine, name,
        ref_spec = spec,
        extra_class = NULL,
        ...
) {
    prep <- tsibble_to_ts(.data)
    y    <- prep$ts
    cache <- new.env(parent = emptyenv())
    cache$jres <- jres

    structure(
        list(
            data = .data,
            y = y,
            spec = spec,
            ref_spec = ref_spec,
            context = context,
            engine = engine,
            resp = prep$measure,
            cache = cache
        ),
        class = c(name, extra_class)
    )
}
#' @keywords internal
#' @noRd
train_jd3 <- function(
        .data, name, spec, context,
        specials,
        ref_spec = spec,
        extra_class = NULL, ...) {
    engine <- .engines[[name]]
    prep   <- tsibble_to_ts(.data)
    y      <- prep$ts

    built <- build_jd3_spec(
        spec = spec, context = context,
        specials = specials, y = y, engine = engine,
        ref_spec = ref_spec
        )
    jres  <- run_jd3(engine, y, built$spec, built$context)

    make_jd3_model(
        .data = .data,
        jres = jres,
        spec = built$spec,
        ref_spec = built$ref_spec,
        context = built$context,
        engine = engine,
        name = name,
        extra_class = extra_class
    )
}

#' X-13ARIMA seasonal adjustment (JDemetra+ v3)
#'
#' Defines an X-13ARIMA model to be used inside [fabletools::model()].
#' The model is estimated with [rjd3x13::jx13()] and the Java result is kept in
#' the fitted model, so that all JDemetra+ indicators can be extracted
#' afterwards (see [jd3_indicator()]).
#'
#' The specification can be set in two (combinable) ways:
#'
#' 1. **Ex ante**, with the `spec` argument: a name or a
#'    specification object created with [rjd3x13::x13_spec()] and modified with
#'    the `set_*()` functions of \pkg{rjd3toolkit}.
#' 2. **In the formula**, with specials such as `transform()` or `xreg()`
#'    (see [jd3_specials]). This is the only way to use regressors that are
#'    columns of the tsibble.
#'
#' Specials override the base `spec`.
#'
#' @param formula Model formula: the name of the variable to adjust (`y`), or
#'   `y ~ specials` (see [jd3_specials]).
#' @param spec Estimate specification: a character name or a
#'   specification object from [rjd3x13::x13_spec()].
#' @param ref_spec Reference specification: the base specification modifyed by the specials.
#' Defaults to `spec`.
#' @param context A modelling context created with
#'   [rjd3toolkit::modelling_context()] (e.g. for custom calendars), or `NULL`.
#' @param ... Currently unused.
#'
#' @return A model definition that can be passed to [fabletools::model()]. Once
#'   fitted, the mable column contains a `jd3_model` object. Use
#'   [components()][jd3_model_methods] to get the decomposition as a `dable`
#'   (columns `trend`, `seasonal`, `irregular` and `season_adjust`).
#'
#' @seealso [TRAMOSEATS()], [REGARIMA()], [jd3_specials], [jd3_model_methods],
#'   [jd3_indicator()], [jd3_dictionary()]
#'
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' y <- tsibble::as_tsibble(AirPassengers)
#'
#' # Default specification
#' mb <- model(y, x13 = X13(value))
#' components(mb)
#'
#' # Specification created ex ante with rjd3toolkit
#' my_spec <- rjd3x13::x13_spec("rsa3")
#' my_spec <- rjd3toolkit::set_transform(my_spec, fun = "Log")
#' mb <- model(y, x13 = X13(value, spec = my_spec))
#'
#' # Specification set in the formula with specials
#' mb <- model(
#'   y,
#'   x13 = X13(value ~ transform(fun = "Log") +
#'               outlier(outliers.type = c("AO", "LS")))
#' )
#'
#' # Regressor taken from a column of the tsibble
#' y$shock <- as.numeric(y$index == tsibble::yearmonth("1955 Jan"))
#' mb <- model(y, x13 = X13(value ~ xreg(shock, regeffect = "Series")))
#' @importFrom fabletools new_model_class new_model_definition
#' @export
X13 <- function(
        formula,
        spec = c("rsa4", "rsa0", "rsa1", "rsa2c", "rsa3", "rsa5c"),
        context = NULL,
        ref_spec = spec,
        ...
) {
    mod <- new_model_class("X13", train = train_x13,
                           specials = specials_rjd3)
    new_model_definition(
        mod, {{formula}}, spec = spec,
        context = context,
        ref_spec = ref_spec,
        ...)
}
#' @keywords internal
#' @noRd
train_x13 <- function(
        .data, specials,
        spec = NULL,
        context = NULL,
        ref_spec = spec,
        ...
) {
    train_jd3(
        .data = .data, name = "X13", spec = spec,
        context = context, specials = specials,
        ref_spec = ref_spec,
        extra_class = c("jd3_model", "jd3_sa_model"),
        ...
    )
}

#' TRAMO-SEATS seasonal adjustment (JDemetra+ v3)
#'
#' Defines a TRAMO-SEATS model to be used inside [fabletools::model()]. The
#' model is estimated with [rjd3tramoseats::.jtramoseats()] and the Java result
#' is kept in the fitted model. Arguments and specials are the same as for
#' [X13()].
#'
#' @inheritParams X13
#' @param spec Base specification: a character name or a
#'   specification object from [rjd3tramoseats::tramoseats_spec()].
#'
#' @return A model definition that can be passed to [fabletools::model()]. Once
#'   fitted, the mable column contains a `jd3_model` object. Use
#'   [components()][jd3_model_methods] to get the decomposition as a `dable`
#'   (columns `trend`, `seasonal`, `irregular` and `season_adjust`).
#'
#' @seealso [X13()], [TRAMO()], [jd3_specials], [jd3_model_methods]
#'
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' y <- tsibble::as_tsibble(AirPassengers)
#'
#' mb <- model(y, ts = TRAMOSEATS(value))
#' components(mb)
#'
#' # Fit both methods side by side and plot the seasonally adjusted series
#' mb <- model(y, x13 = X13(value), ts = TRAMOSEATS(value))
#' if (requireNamespace("ggtime", quietly = TRUE)) {
#'   ggtime::autoplot(components(mb))
#' }
#' @export
TRAMOSEATS <- function(
        formula,
        spec = c("rsafull", "rsa0", "rsa1", "rsa2", "rsa3",
                 "rsa4", "rsa5"),
        context = NULL,
        ref_spec = spec,
        ...
) {
    mod <- new_model_class("TRAMOSEATS", train = train_tramoseats,
                           specials = specials_rjd3)
    new_model_definition(
        mod, {{formula}}, spec = spec,
        context = context,
        ref_spec = ref_spec,
        ...)
}
#' @keywords internal
#' @noRd
train_tramoseats <- function(
        .data,
        specials,
        spec = c("rsafull", "rsa0", "rsa1", "rsa2", "rsa3",
                 "rsa4", "rsa5"),
        context = NULL,
        ref_spec = spec,
        ...
) {
    train_jd3(
        .data = .data, name = "TRAMOSEATS", spec = spec,
        context = context, specials = specials,
        ref_spec = ref_spec,
        extra_class = c("jd3_model", "jd3_sa_model"),
        ...
    )
}

#' Reg-ARIMA Model
#'
#' Defines a Reg-ARIMA model (pre-adjustment model used in X-13)
#' to be used inside [fabletools::model()]. The
#' model is estimated with [rjd3x13::jregarima()] and the Java result
#' is kept in the fitted model. Arguments and specials are the same as for
#' [X13()].
#'
#' @inheritParams X13
#' @param spec Base specification: a character name or a
#'   specification object from [rjd3x13::regarima_spec()].
#'
#' @return A model definition that can be passed to [fabletools::model()]. Once
#'   fitted, the mable column contains a `jd3_model` object. Use
#'   [components()][jd3_model_methods] to get the decomposition as a `dable`
#'   (columns `trend`, `seasonal`, `irregular` and `season_adjust`).
#'
#' @seealso [X13()], [jd3_specials], [jd3_model_methods]
#'
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' y <- tsibble::as_tsibble(AirPassengers)
#'
#' mb <- model(y, ts = TRAMOSEATS(value))
#' components(mb)
#'
#' # Fit both methods side by side and plot the seasonally adjusted series
#' mb <- model(y, x13 = X13(value), ts = TRAMOSEATS(value))
#' if (requireNamespace("ggtime", quietly = TRUE)) {
#'   ggtime::autoplot(components(mb))
#' }
#' @export
REGARIMA <- function(
        formula, spec = c("rg4", "rg0", "rg1", "rg2c", "rg3", "rg5c"),
        context = NULL,
        ref_spec = spec,
        ...
) {
    mod <- new_model_class("REGARIMA", train = train_regarima,
                           specials = specials_rjd3)
    new_model_definition(
        mod, {{formula}}, spec = spec,
        context = context,
        ref_spec = ref_spec,
        ...)
}
#' @keywords internal
#' @noRd
train_regarima <- function(
        .data, specials,
        spec = c("rg4", "rg0", "rg1", "rg2c", "rg3", "rg5c"),
        context = NULL,
        ref_spec = spec,
        ...
) {
    train_jd3(
        .data = .data, name = "REGARIMA", spec = spec,
        context = context, specials = specials,
        ref_spec = ref_spec,
        extra_class = c("jd3_model", "jd3_arima_model"),
        ...
    )
}

#' TRAMO Model
#'
#' Defines a TRAMO model (pre-adjustment model used in TRAMO-SEATS)
#' to be used inside [fabletools::model()]. The
#' model is estimated with [rjd3tramoseats::jtramo()] and the Java result
#' is kept in the fitted model. Arguments and specials are the same as for
#' [TRAMOSEATS()].
#'
#' @inheritParams X13
#' @param spec Base specification: a character name or a
#'   specification object from [rjd3tramoseats::tramo_spec()].
#'
#' @return A model definition that can be passed to [fabletools::model()]. Once
#'   fitted, the mable column contains a `jd3_model` object. Use
#'   [components()][jd3_model_methods] to get the decomposition as a `dable`
#'   (columns `trend`, `seasonal`, `irregular` and `season_adjust`).
#'
#' @seealso [TRAMOSEATS()], [jd3_specials], [jd3_model_methods]
#'
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' y <- tsibble::as_tsibble(AirPassengers)
#'
#' mb <- model(y, ts = TRAMOSEATS(value))
#' components(mb)
#'
#' # Fit both methods side by side and plot the seasonally adjusted series
#' mb <- model(y, x13 = X13(value), ts = TRAMOSEATS(value))
#' if (requireNamespace("feasts", quietly = TRUE) &&
#'     requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::autoplot(components(mb))
#' }
#' @export
TRAMO <- function(
        formula,
        spec = c("trfull", "tr0", "tr1", "tr2", "tr3",
                 "tr4", "tr5"),
        context = NULL,
        ref_spec = spec,
        ...
) {
    mod <- new_model_class("TRAMO", train = train_tramo,
                           specials = specials_rjd3)
    new_model_definition(
        mod, {{formula}}, spec = spec,
        context = context,
        ref_spec = ref_spec,
        ...)
}
#' @keywords internal
#' @noRd
train_tramo <- function(
        .data, specials,
        spec = c("trfull", "tr0", "tr1", "tr2", "tr3",
                 "tr4", "tr5"),
        context = NULL,
        ref_spec = spec,
        ...) {
    train_jd3(
        .data = .data, name = "TRAMO", spec = spec,
        context = context, specials = specials,
        ref_spec = ref_spec,
        extra_class = c("jd3_model", "jd3_arima_model"),
        ...
    )
}
