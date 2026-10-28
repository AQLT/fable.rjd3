# A "step" is a call to a `set_*()` / `add_*()` function of rjd3toolkit
# (spec -> spec), recorded by a special and applied later in `build_spec()`.

rjd3_spec_fun <- function(fn, ...) {
    structure(list(fn = fn, args = list(...)), class = "rjd3_spec_fun")
}

#' Specials available in the model formula
#'
#' Specials are used on the right-hand side of the formula of [X13()],
#' [TRAMOSEATS()], [REGARIMA()] or [TRAMO()],
#' e.g. `X13(y ~ transform(fun = "Log") + xreg(strike))`.
#' Each one records a call to a function of \pkg{rjd3toolkit} that is applied to
#' the base specification (the `spec` argument).
#'
#' @section Specials:
#' * `spec(x)`: base specification (name or specification object); equivalent
#'   to the `spec` argument of [X13()], [TRAMOSEATS()], [REGARIMA()] or [TRAMO()].
#' * `basic(...)`: arguments passed to [rjd3toolkit::set_basic()].
#' * `transform(...)`: arguments passed to [rjd3toolkit::set_transform()].
#' * `estimate(...)`: arguments passed to [rjd3toolkit::set_estimate()].
#' * `automodel(...)`: arguments passed to [rjd3toolkit::set_automodel()].
#' * `outlier(...)`: arguments passed to [rjd3toolkit::set_outlier()].
#' * `add_outlier(...)`: arguments passed to [rjd3toolkit::add_outlier()]
#'   (e.g. `type = "AO", date = "2020-04-01"`).
#' * `easter(...)`: arguments passed to [rjd3toolkit::set_easter()].
#' * `tradingdays(...)`: arguments passed to [rjd3toolkit::set_tradingdays()].
#' * `arima(...)`: arguments passed to [rjd3toolkit::set_arima()].
#' * `ramp(...)`: arguments passed to [rjd3toolkit::add_ramp()].
#' * `usrdefvar(...)`: arguments passed to [rjd3toolkit::add_usrdefvar()].
#' * `x11(...)`: arguments passed to [rjd3x13::set_x11()] (X-11 decomposition
#'   parameters; use with [X13()] only).
#' * `seats(...)`: arguments passed to [rjd3tramoseats::set_seats()] (SEATS
#'   decomposition parameters; use with [TRAMOSEATS()] only).
#' * `benchmarking(...)`: arguments passed to [rjd3toolkit::set_benchmarking()]
#'   (use with [X13()] or [TRAMOSEATS()] only).
#' * `xreg(...)`: user-defined regressors taken from
#'   columns of the tsibble and added to the context.
#'
#' @section Precedence:
#' The base `spec` is applied first, then the specials (in the order above,
#' `jd3()` last), then `xreg()`. Later settings override earlier ones.
#'
#' @name jd3_specials
#' @seealso [X13()], [TRAMOSEATS()]
NULL

#' @importFrom fabletools new_specials
specials_rjd3 <- fabletools::new_specials(
    spec        = function(x, ...) x,
    basic   = function(...) rjd3_spec_fun("set_basic", ...),
    transform   = function(...) rjd3_spec_fun("set_transform", ...),
    estimate    = function(...) rjd3_spec_fun("set_estimate", ...),
    automodel   = function(...) rjd3_spec_fun("set_automodel", ...),
    outlier     = function(...) rjd3_spec_fun("set_outlier", ...),
    add_outlier = function(...) rjd3_spec_fun("add_outlier", ...),
    easter      = function(...) rjd3_spec_fun("set_easter", ...),
    tradingdays = function(...) rjd3_spec_fun("set_tradingdays", ...),
    arima       = function(...) rjd3_spec_fun("set_arima", ...),
    ramp = function(...) rjd3_spec_fun("add_ramp", ...),
    usrdefvar = function(...) rjd3_spec_fun("add_usrdefvar", ...),
    benchmarking = function(...) rjd3_spec_fun("set_benchmarking", ...),
    x11         = function(...) rjd3_spec_fun("set_x11", ...),
    seats       = function(...) rjd3_spec_fun("set_seats", ...),
    xreg = function(..., regeffect = NULL, group = "r") {
        ex  <- enexprs(...)
        val <- list(...)
        nm  <- names(ex)
        if (is.null(nm)) nm <- rep("", length(ex))
        lab <- vapply(ex, as_label, character(1))
        nm  <- make.names(ifelse(nm == "", lab, nm))
        list(
            vars = setNames(val, nm),
            regeffect = regeffect,
            group = group
        )
    }
)

.step_order <- c(
    "basic",
    "transform", "estimate", "automodel",
    "outlier", "add_outlier",
    "easter", "tradingdays", "arima",
    "ramp", "usrdefvar", "benchmarking",
    "x11", "seats"
)

# Build the final specification and modelling context.
# Precedence: base spec < formula specials < xreg.
#' @importFrom stats setNames
build_jd3_spec <- function(spec, context, specials, y, engine, ref_spec = spec) {
    bad <- intersect(engine$unsupported, names(specials))
    bad <- bad[lengths(specials[bad]) > 0]
    if (length(bad) > 0) {
        warning(sprintf("Special `%s()` is not available for %s.",
                        paste(bad, collapse = "()`, `"), engine$method))
        specials[bad] <- NULL
    }

    if (length(specials$spec)) {
        spec <- specials$spec[[length(specials$spec)]]
    }
    spec_fun <- pkg_fun(engine$spec_fun, engine$pkg)
    base <- if (is.character(ref_spec)) spec_fun(ref_spec)
    else ref_spec

    steps <- do.call(c, unname(lapply(intersect(.step_order, names(specials)),
                                      function(n) specials[[n]])))
    spec <- Reduce(function(s, st) {
        f <- pkg_fun(st$fn, c("rjd3toolkit", engine$pkg))
        do.call(f, c(list(s), st$args))
    }, steps, init = base)

    # user-defined regressors
    for (x in specials$xreg) {
        for (nm in names(x$vars)) {
            var <- as_ts_like(x$vars[[nm]], y)
            var <- setNames(list(var), nm)
            if (is.null(context)) {
                context <- rjd3toolkit::modelling_context(
                    variables = setNames(list(var), x$group)
                    )
            } else {
                context <- rjd3toolkit::complete_modelling_context(
                    context,
                    y = setNames(list(var), x$group),
                    overwrite = TRUE
                )
            }
            if (!is.null(x$regeffect)) {
                spec <- remove_usrdefvar(spec, name = nm)
                spec <- rjd3toolkit::add_usrdefvar(
                    spec,
                    group = x$group,
                    name = nm
                    )
            }
        }
    }
    list(spec = spec, context = context, ref_spec = base)
}

remove_usrdefvar <- function(spec, name = NULL) {
    if (is.null(name)){
        return (spec)
    }
    spec_tmp <- spec
    if (!is.null(spec$regarima)) {
        spec_tmp <- spec_tmp$regarima
    } else if (!is.null(spec$tramo)) {
        spec_tmp <- spec$tramo
    }
    users_spec <- spec_tmp$regression$users
    if (length(users_spec) > 0) {
        ids <- vapply(users_spec, function(x) x$id, character(1))
        users_spec <- users_spec[ids != name]
        if (length(users_spec) == 0) {
            spec_tmp$regression["users"] <- list(NULL)
        } else {
            spec_tmp$regression["users"] <- list(users_spec)
        }
    }
    if (!is.null(spec$regarima)) {
        spec$regarima <- spec_tmp
        spec_tmp <- spec_tmp$regarima
    } else if (!is.null(spec$tramo)) {
        spec$tramo <- spec_tmp
    } else {
        spec <- spec_tmp
    }
    spec
}
