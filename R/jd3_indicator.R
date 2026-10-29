#' Extract any JDemetra+ indicator from a fitted model
#'
#' Wraps [rjd3toolkit::result()] on the Java result of the model. If the Java
#' pointer is no longer valid (e.g. after [saveRDS()]/[readRDS()]), the model is
#' transparently re-estimated (once per loaded object). The ids available are
#' listed by [jd3_dictionary()].
#'
#' @param object A fitted mable (`mdl_df`), a `mdl_ts` or a `jd3_model`.
#' @param id Indicator id (see [jd3_dictionary()]).
#' @param simplify For a mable only: simplify the result according to the type
#'   of the indicator (see *Value*). `FALSE` always returns a list-column.
#' @inheritParams jd3_model_methods
#'
#' @return For a `mdl_ts` or `jd3_model`, the indicator as returned by
#'   [rjd3toolkit::result()]: a number, a string, a `ts`, a matrix, a
#'   `JD3_TEST`...
#'
#' For a mable, a tibble with the key columns, `.model`, `id` and:
#'   * numbers or strings: a column `value`;
#'   * `ts` series: one row per date, with columns `index` and `value`;
#'   * tests: columns `statistic`, `p.value` and `distribution`;
#'   * anything else (or `simplify = FALSE`): a list-column `value` with one
#'     element per model.
#' With several ids (or `drop = FALSE`), a named list of such tibbles, one per id.
#' @seealso [jd3_dictionary()]
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' \donttest{
#' mb <- model(as_tsibble(AirPassengers), x13 = X13(value), ts = TRAMOSEATS(value))
#'
#' jd3_indicator(mb, "likelihood.aic")      # one number per model
#' jd3_indicator(mb, "sa")                  # seasonally adjusted series, long format
#' jd3_indicator(mb, "residuals.kurtosis")  # test: statistic and p-value
#'
#' # The raw object of a single model
#' jd3_indicator(mb$x13[[1]], "sa")
#' }
#' @export
jd3_indicator <- function(object, id, ...) UseMethod("jd3_indicator")

#' @param drop If `TRUE` (default) and a single `id` is given, the indicator
#'   itself is returned instead of a list of length one. Several ids always give
#'   a named list.
#' @rdname jd3_indicator
#' @export
jd3_indicator.jd3_model <- function(object, id, drop = TRUE, ...) {
    res <- rjd3toolkit::user_defined(get_jres(object), id)
    out <- lapply(id, function(i) res[[i]])     # by name; NULL if unknown
    if (is.null(names(id))) {
        names(out) <- id
    }
    names(out)[names(out) == ""] <- id[names(out) == ""]
    out <- out[lengths(out) > 0]

    if (drop && length(out) == 1L) out[[1L]] else out
}

#' @rdname jd3_indicator
#' @export
jd3_indicator.mdl_ts <- function(object, id, drop = TRUE, ...) {
    jd3_indicator(jd3_model(object), id, drop = drop)
}

#' @rdname jd3_indicator
#' @importFrom stats is.ts
#' @export
jd3_indicator.mdl_df <- function(object, id, simplify = TRUE, drop = TRUE, ...) {
    if (length(id) > 1L || !drop) {
        out <- lapply(id, function(i) jd3_indicator(object, i, simplify = simplify))
        names(out) <- id
        return(out)
    }
    mv   <- fabletools::mable_vars(object)
    keys <- tibble::as_tibble(object)[setdiff(names(object), mv)]

    # one entry per (model column, row of the mable)
    items <- unlist(lapply(mv, function(m) {
        lapply(seq_along(object[[m]]), function(i) {
            list(i = i, model = m,
                 value = jd3_indicator(jd3_model(object[[m]][[i]]), id))
        })
    }), recursive = FALSE)
    vals <- lapply(items, `[[`, "value")

    # one row (or n rows) of keys + .model + id for the entry `it`
    head_cols <- function(it, n = 1L) {
        out <- keys[rep(it$i, n), , drop = FALSE]
        out$.model <- it$model
        out$id     <- id
        out
    }

    if (simplify) {
        # numbers or strings
        if (all(vapply(vals, function(v)
            (is.numeric(v) || is.character(v)) && is.null(dim(v)) &&
            !is.ts(v) && length(v) == 1L, logical(1)))) {
            out <- do.call(rbind, lapply(items, head_cols))
            out$value <- unlist(vals)
            return(out)
        }
        # univariate time series: long format
        if (all(vapply(vals, function(v) is.ts(v) && is.null(dim(v)), logical(1)))) {
            out <- do.call(rbind, lapply(seq_along(items), function(k) {
                d   <- ts_to_tbl(vals[[k]])
                res <- head_cols(items[[k]], nrow(d))
                res$index <- d[[1]]
                res$value <- d[[2]]
                res
            }))
            return(out)
        }
        # tests
        if (all(vapply(vals, inherits, logical(1), what = "JD3_TEST"))) {
            out <- do.call(rbind, lapply(items, head_cols))
            out$statistic <- vapply(vals, function(v) as.numeric(v$value),  numeric(1))
            out$p.value   <- vapply(vals, function(v) as.numeric(v$pvalue), numeric(1))
            out$distribution   <- vapply(vals, attr, character(1), which = "distribution")
            return(out)
        }
    }

    # fallback: list-column
    out <- do.call(rbind, lapply(items, head_cols))
    out$value <- vals
    out
}
#' @keywords internal
#' @noRd
jd3_flatten <- function(v, name) {
    if (is.null(v)){
        NULL
    } else if (is.numeric(v) && is.null(dim(v)) && !is.ts(v) && length(v) == 1L) {
        return(setNames(list(as.numeric(v)), name))
    } else if (inherits(v, "JD3_TEST")) {
        # JD3_TEST: value and pvalue (CHECK)
        return(setNames(list(as.numeric(v$value), as.numeric(v$pvalue)),
                               paste0(name, c("_stat", "_pvalue"))))
    } else if (is.character(v) && length(v) == 1L){
        return(setNames(list(v), name))
    } else {
        # series, matrices
        setNames(list(NA_real_), name)
    }
}


#' @param ids For `glance()`: named or unnamed character vector of indicator ids
#'   (see [jd3_dictionary()]); the names become the column names. Numbers and
#'   strings give one column; tests give two columns, `<name>_stat` and
#'   `<name>_pvalue`; other indicators give `NA`. If `NULL`, the default set of
#'   the method is used (information criteria, number of observations, tests on
#'   the residuals and on the seasonally adjusted series, M and Q statistics
#'   for X-13, SEATS tests for TRAMO-SEATS).
#' @rdname jd3_model_methods
#' @export
glance.jd3_model <- function(x, ids = NULL, ...) {
    if (is.null(ids)) {
        ids <- x$engine$id_glance
    }
    if (is.null(names(ids))) {
        names(ids) <- ids
    }
    names(ids)[names(ids) == ""] <- ids[names(ids) == ""]

    vals <- jd3_indicator(x, unname(ids), drop = FALSE)
    indicators <- lapply(seq_along(ids), function(k) {
        jd3_flatten(vals[[unname(ids)[k]]], names(ids)[k])
    })
    indicators <- indicators[lengths(indicators) > 0]
    flat <- unlist(indicators, recursive = FALSE)
    tibble::as_tibble(as.list(flat))
}
#' List the indicators available in a fitted model
#'
#' Wraps [rjd3toolkit::dictionary()] on the Java result of the model. The
#' returned ids can be passed to [jd3_indicator()].
#'
#' @inheritParams jd3_indicator
#'
#' @return A data frame (class `JD3_FULL_DICTIONARY`) with one row per
#'   indicator: its id (`name`), description and output type. For a mable, the
#'   dictionary of the first model is returned.
#'
#' @seealso [jd3_indicator()]
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#'
#' mb <- model(tsibble::as_tsibble(AirPassengers), x13 = X13(value))
#' head(jd3_dictionary(mb))
#' @export
jd3_dictionary <- function(object, ...) UseMethod("jd3_dictionary")

#' @rdname jd3_dictionary
#' @export
jd3_dictionary.jd3_model <- function(object, ...) {
    rjd3toolkit::dictionary(get_jres(object))
}
#' @rdname jd3_dictionary
#' @export
jd3_dictionary.mdl_ts <- function(object, ...) jd3_dictionary(jd3_model(object))
#' @rdname jd3_dictionary
#' @export
jd3_dictionary.mdl_df <- function(object, ...) {
    mv <- fabletools::mable_vars(object)
    jd3_dictionary(jd3_model(object[[mv[1]]][[1]]))
}
