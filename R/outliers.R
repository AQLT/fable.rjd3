# ==============================================================================
# outliers.jd3_model
#
# CONTRACT (source of fabletools:::outliers.mdl_ts):
#     outliers.mdl_ts <- function(object, ...) object$data[outliers(object$fit, ...), ]
# so the model method must return the ROW POSITIONS (integers) of the outlying
# observations in the training data; fabletools turns them into a table of rows
# of the data (outliers.mdl_df adds the keys and `.model`). feasts does the same:
# `which(!is.na(seasonal::outlier(fit)))`.
#
# SOURCE of the outliers: indicators `regression.nout` (number of outliers) and
# `regression.outlier(i)`, i = 1..nout. Each one is a 1-row matrix whose row
# name is "<TYPE> (<period>)", e.g. "AO (1951-01)", with columns Estimate,
# Std. Error, T-stat, Pr(>|t|).
#
# The type (AO, LS, TC, SO) and the statistics are not part of the fabletools
# output (rows of the data only): use jd3_outlier_table() to get them.
# ==============================================================================

# Label of each period of the series, in the format used by JDemetra+ in the
# names of the outliers: "YYYY-MM" with the FIRST month of the period, for
# monthly and quarterly series alike (e.g. "1951-01"; third quarter 1950 is
# "1950-07"). as.Date() of a yearmonth / yearquarter is the first day of the period.
#' @keywords internal
#' @noRd
jd3_period_label <- function(idx) format(as.Date(idx), "%Y-%m")

# One row per outlier: label, type, date, estimate, std.error, statistic,
# p.value and `position` (row in the data of the model).
#' @keywords internal
#' @noRd
jd3_outlier_table <- function(object) {
    jres <- get_jres(object)
    nout <- rjd3toolkit::result(jres, "regression.nout")

    empty <- tibble::tibble(
        label = character(), type = character(), date = character(),
        estimate = double(), std.error = double(), statistic = double(),
        p.value = double(), position = integer()
    )
    if (nout == 0) {
        return(empty)
    }

    res  <- rjd3toolkit::user_defined(
        jres, sprintf("regression.outlier(%d)", seq_len(nout))
    )
    res <- res[lengths(res) >0]
    rows <- lapply(res, function(m) {
        m <- as.matrix(m)
        # columns by position: Estimate, Std. Error, T-stat, Pr(>|t|)
        tibble::tibble(
            label = rownames(m)[1], estimate = m[1, 1],
            std.error = m[1, 2], statistic = m[1, 3], p.value = m[1, 4]
        )
    })
    tab <- do.call(rbind, unname(rows))
    fixed_coeff <- get_fixed_outliers(object$spec)
    if (!is.null(fixed_coeff)){
        res_rjd <- rjd3toolkit::user_defined(
            jres,
            c(
                "regression.details.description",
                "regression.description"
            )
        )

        term <- res_rjd[["regression.details.description"]]
        term[term == "const"] <- "Constant"
        term_glob <- res_rjd[["regression.description"]]
        fixed_coeff <-
            fixed_coeff[fixed_coeff$term %in% setdiff(term_glob, term),]
    }
    if (is.null(fixed_coeff) || is.null(tab)) {
        return (empty)
    }

    # "AO (1951-01)" -> type "AO", date "1951-01"
    tab$type <- sub("^\\s*([A-Za-z]+)\\s*\\(.*\\)\\s*$", "\\1", tab$label)
    tab$date <- sub("^.*\\((.*)\\)\\s*$", "\\1", tab$label)

    # position of each outlier in the data
    idx    <- object$data[[tsibble::index_var(object$data)]]
    labels <- jd3_period_label(idx)
    tab$position <- match(tab$date, labels)
    if (anyNA(tab$position)) {
        abort(sprintf(
            "Outlier date(s) not found in the series: %s. Period labels look like: %s.",
            paste(tab$date[is.na(tab$position)], collapse = ", "),
            paste(utils::head(labels, 2), collapse = ", ")
        ))
    }
    tab[c("label", "type", "date", "estimate", "std.error", "statistic",
          "p.value", "position")]
}

#' Identify the outliers of a JDemetra+ model
#'
#' Returns the outlying observations detected (or specified) in the
#' pre-adjustment model of a model fitted with [X13()] or [TRAMOSEATS()]:
#' additive outliers (AO), level shifts (LS), transitory changes (TC) and
#' seasonal outliers (SO). An outlier is dated at one observation, even when
#' its effect (e.g. a level shift) lasts longer.
#'
#' @inheritParams jd3_model_methods_extra
#' @param type Optional character vector of outlier types to keep, e.g.
#'   `c("AO", "LS")`. `NULL` (default) keeps all of them.
#'
#' @return For a `jd3_model`, an integer vector with the row positions of the
#'   outliers in the data of the model (the contract of
#'   [fabletools::outliers()]). Called on a mable, `outliers()` returns the
#'   corresponding rows of the data, with the key columns and `.model`. The
#'   type, estimate and test statistics of the outliers are available in
#'   [tidy()][jd3_model_methods].
#'
#' @seealso [X13()], [TRAMOSEATS()], [jd3_model_methods]
#'
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' mb <- model(tsibble::as_tsibble(AirPassengers), x13 = X13(value))
#'
#' # Rows of the data that are outliers
#' outliers(mb)
#'
#' # Additive outliers only
#' outliers(mb, type = "AO")
#' @export
outliers.jd3_model <- function(object, type = NULL, ...) {
    tab <- jd3_outlier_table(object)
    if (!is.null(type)) tab <- tab[tab$type %in% type, ]
    sort(unique(tab$position))
}

#' @keywords internal
#' @noRd
get_fixed_outliers <- function(spec){
    if (!is.null(spec$regarima)) {
        spec <- spec$regarima
    }
    if (!is.null(spec$tramo)) {
        spec <- spec$tramo
    }

    ud_out <- NULL
    if (length(spec$regression$outliers) > 0) {
        ud_out <- do.call(rbind, lapply(spec$regression$outliers, function(out){
            if (is.null(out$coef) || out$coef$type != "FIXED") {
                NULL
            } else {
                tibble::tibble(
                    term = sprintf(
                        "%s (%s)",
                        out$code,
                        substr(out$pos, 1, 7)
                    ),
                    estimate = out$coef$value,
                    std.error = NA_real_,
                    statistic = NA_real_,
                    p.value = NA_real_
                )
            }
        }))

    }
    ud_out
}
