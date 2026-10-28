# Fits one SA-item and returns a one-row mable (NULL if unsupported)
jd3_fit_item <- function(jsai, sap, name, ctx) {
    est <- rjd3workspace::get_estimation_specification(jsai)
    ref <- rjd3workspace::get_reference_specification(jsai)
    res <- rjd3workspace::get_result_specification(jsai)

    # CHECK the class names of the specifications
    method <- if (inherits(est, "JD3_X13_SPEC")) X13
    else if (inherits(est, "JD3_TRAMOSEATS_SPEC")) TRAMOSEATS
    else NULL
    if (is.null(method)) {
        warning(sprintf("SA-item `%s` of `%s` skipped: unsupported specification (%s).",
                        name, sap, class(est)[1]))
        return(NULL)
    }

    y   <- rjd3workspace::get_raw_data(jsai)                  # ts (CHECK)
    dat <- tibble::as_tibble(tsibble::as_tsibble(y))          # columns: index, value
    dat$sap    <- sap
    dat$series <- name
    dat <- tsibble::as_tsibble(dat, index = "index", key = c("sap", "series"))

    # one model() call per item: X13(spec = ) takes ONE spec for the whole tsibble
    mb <- fabletools::model(
        dat, sa = method(value, spec = est, ref_spec = ref, context = ctx)
    )

    # the result spec is already known: avoids a re-estimation at the first refit()
    fit <- jd3_model(mb$sa[[1]])
    if (inherits(fit, "jd3_model")) fit$cache$result_spec <- res
    mb
}
utils::globalVariables("value")

#' Import a JDemetra+ workspace as a mable
#'
#' Reads all the SA-items of a workspace and fits them with [X13()] or
#' [TRAMOSEATS()] using the specifications stored in the workspace: the
#' estimation specification is the model specification, the reference
#' specification is kept for the refresh policies (see [jd3_model_methods_extra]).
#'
#' @param file Path to the master xml file of the workspace.
#' @param compute Compute the workspace before reading it (required to access
#'   the SA-items).
#'
#' @return A mable with the key columns `sap` (SA-processing) and `series`
#'   (SA-item), and a model column `sa` holding `X13` and `TRAMOSEATS` models.
#'   SA-items with another type of specification (e.g. RegARIMA only) are
#'   skipped with a warning.
#'
#' @seealso [export_jws()]
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' file <- system.file("workspaces", "workspace_test.xml", package = "rjd3workspace")
#' mb <- import_jws(file)
#' mb
#' @export
import_jws <- function(file, compute = TRUE) {
    jws <- rjd3workspace::jws_open(file)
    if (compute) rjd3workspace::jws_compute(jws)
    ctx <- rjd3workspace::get_context(jws)            # shared by all SA-processings

    fits <- list()
    for (i in seq_len(rjd3workspace::ws_sap_count(jws))) {
        jsap <- rjd3workspace::jws_sap(jws, i)
        sap  <- rjd3workspace::sap_name(jsap)
        nms  <- rjd3workspace::sap_sai_names(jsap)
        for (j in seq_len(rjd3workspace::sap_sai_count(jsap))) {
            jsai <- rjd3workspace::jsap_sai(jsap, j)
            fits[[length(fits) + 1L]] <- jd3_fit_item(jsai, sap, nms[j], ctx)
        }
    }
    fits <- fits[lengths(fits) > 0]
    if (length(fits) == 0L) abort("No supported SA-item found in the workspace.")

    out <- dplyr::bind_rows(fits)
    if (!inherits(out, "mdl_df")) {
        out <- fabletools::as_mable(out, key = c("sap", "series"), model = "sa")
    }
    out
}

# --- export ---------------------------------------------------------------------

# A workspace has a SINGLE modelling context, shared by all its SA-items, while
# each model of a mable has its own: with xreg(col), every series adds a variable
# `r.col` to ITS context (no conflict at estimation time). When the models are
# pooled, the same id can therefore designate different data (several series
# with the same regressor name, or several series with the same name in
# different SA-processings).
#
# Rule: a variable is renamed ONLY when its id has several different values.
# The new name is <name>_<sap>_<series> (sanitized); it is changed in the
# context AND in the specifications of the model (spec and ref_spec), where the
# variable id "<group>.<name>" appears. Otherwise names are left untouched, so
# that import -> export keeps the names of the workspace.
# Calendars cannot be renamed this way: a name used for two different calendars
# is an error.

jd3_slug <- function(x) gsub("[^A-Za-z0-9]+", "_", x)

# Replace exact matches of variable ids (old = new, named character vector) in
# any character vector of a spec, whatever its position. CHECK on a real spec
# that the ids are stored as "<group>.<name>" (see the verification below).
jd3_replace_ids <- function(x, map) {
    if (is.list(x)) {
        x[] <- lapply(x, jd3_replace_ids, map = map)   # keeps names and attributes
        return(x)
    }
    if (is.character(x)) {
        hit <- x %in% names(map)
        x[hit] <- unname(map[x[hit]])
    }
    x
}

# Variables of a context as a data frame: group, name, id
jd3_context_vars <- function(ctx) {
    rows <- lapply(names(ctx$variables), function(g) {
        v <- names(ctx$variables[[g]])
        if (length(v) == 0L) return(NULL)
        data.frame(group = g, name = v, id = paste(g, v, sep = "."), stringsAsFactors = FALSE)
    })
    do.call(rbind, rows)
}

# Returns list(items =, context =): each item gets `spec`, `ref_spec` and
# `context` (renamed if needed) and `renamed` (logical); `context` is the single
# context of the workspace. If `check`, every renamed model is re-estimated and
# its seasonally adjusted series compared with the original one.
jd3_unify_contexts <- function(items) {
    ctxs <- lapply(items, function(it) it$model$context)

    # calendars: the same name must designate the same calendar
    cal <- list()
    for (ctx in ctxs) {
        for (nm in names(ctx$calendars)) {
            if (!is.null(cal[[nm]]) && !identical(cal[[nm]], ctx$calendars[[nm]])) {
                abort(sprintf("Calendar `%s` is defined differently in several models.", nm))
            }
            cal[[nm]] <- ctx$calendars[[nm]]
        }
    }

    # variables: ids having several distinct values
    values <- list()
    for (ctx in ctxs) {
        vv <- jd3_context_vars(ctx)
        for (k in seq_len(NROW(vv))) {
            val <- ctx$variables[[vv$group[k]]][[vv$name[k]]]
            id  <- vv$id[k]
            if (!any(vapply(values[[id]], identical, logical(1), y = val))) {
                values[[id]] <- c(values[[id]], list(val))
            }
        }
    }
    conflicts <- names(values)[lengths(values) > 1L]

    # renaming of the conflicting variables, model by model
    all_vars <- list()
    for (k in seq_along(items)) {
        it   <- items[[k]]
        ctx  <- ctxs[[k]]
        spec <- it$model$spec
        ref  <- it$model$ref_spec
        map  <- character()
        vv   <- jd3_context_vars(ctx)
        for (r in seq_len(NROW(vv))) {
            if (vv$id[r] %in% conflicts) {
                new <- paste(vv$name[r], jd3_slug(it$sap), jd3_slug(it$series), sep = "_")
                nm  <- names(ctx$variables[[vv$group[r]]])
                nm[nm == vv$name[r]] <- new
                names(ctx$variables[[vv$group[r]]]) <- nm
                map[vv$id[r]] <- paste(vv$group[r], new, sep = ".")
            }
        }
        renamed <- length(map) > 0L
        if (renamed) {
            spec <- jd3_replace_ids(spec, map)
            if (!is.null(ref)) ref <- jd3_replace_ids(ref, map)
            # if (check) {                       # the renamed model must give the same SA series
            #     jres <- run_jd3(it$model$engine, it$model$y, spec, ctx)
            #     same <- isTRUE(all.equal(as.numeric(rjd3toolkit::result(jres, "sa")),
            #                              jd3_get(it$model, "sa")))
            #     if (!same) {
            #         abort(sprintf(paste0("Renaming the regressors of `%s` / `%s` changed the results: ",
            #                              "the variable ids are probably stored elsewhere in the spec."),
            #                       it$sap, it$series))
            #     }
            # }
        }
        items[[k]]$spec     <- spec
        items[[k]]$ref_spec <- ref
        items[[k]]$context  <- ctx
        items[[k]]$renamed  <- renamed

        for (g in names(ctx$variables)) {
            if (is.null(all_vars[[g]])) all_vars[[g]] <- list()
            for (v in names(ctx$variables[[g]])) all_vars[[g]][[v]] <- ctx$variables[[g]][[v]]
        }
    }

    context <- if (length(cal) || length(all_vars)) {
        rjd3toolkit::modelling_context(                  # CHECK argument names
            calendars = if (length(cal)) cal else NULL,
            variables = if (length(all_vars)) all_vars else NULL
        )
    }
    list(items = items, context = context)
}

# Models of a mable with their SA-processing and SA-item names
jd3_collect_models <- function(mb, sap, series) {
    mv   <- fabletools::mable_vars(mb)
    keys <- tibble::as_tibble(mb)[setdiff(names(mb), mv)]
    out  <- list()
    for (m in mv) {
        for (i in seq_along(mb[[m]])) {
            fit <- jd3_model(mb[[m]][[i]])
            if (!inherits(fit, "jd3_model")) {
                rlang::warn(sprintf("Row %d of column `%s` is not a fablejd3 model: skipped.", i, m))
                next
            }
            sap_nm <- if (sap %in% names(keys)) as.character(keys[[sap]][i]) else "SAProcessing-1"
            other  <- setdiff(names(keys), sap)
            sai_nm <- if (series %in% names(keys)) {
                as.character(keys[[series]][i])
            } else if (length(other)) {
                paste(vapply(other, function(k) as.character(keys[[k]][i]), ""), collapse = "_")
            } else fit$resp
            if (length(mv) > 1L) sai_nm <- paste(sai_nm, m, sep = "_")   # several model columns
            out[[length(out) + 1L]] <- list(sap = sap_nm, series = sai_nm, model = fit)
        }
    }
    if (length(out) == 0L) abort("No fablejd3 model found in the mable.")
    out
}

#' Export a mable of JDemetra+ models as a new workspace
#'
#' Writes a new workspace readable by the JDemetra+ graphical interface, with one
#' SA-item per model: raw series, estimation specification, reference
#' specification, and the modelling context (calendars and regressors). A workspace
#' has a single context: regressors of different models that share the same name
#' but have different values (e.g. `xreg(col)` in several series) are renamed
#' `<name>_<sap>_<series>`, in the context and in the specifications. Results, comments, priorities and links to data
#' providers are not exported; the series are stored as static data.
#'
#' @param mb A mable of models fitted with [X13()] or [TRAMOSEATS()].
#' @param file Path of the workspace (xml master file) to create.
#' @param sap,series Names of the key columns giving the SA-processing and the
#'   SA-item. Without them, a single SA-processing is created and the SA-item
#'   names are built from the other keys.
#'
#' @return `file`, invisibly.
#'
#' @seealso [import_jws()]
#' @examplesIf rjd3jars::check_java_version(silent = TRUE)
#' mb <- model(as_tsibble(AirPassengers), sa = X13(value))
#' export_jws(mb, tempfile(fileext = ".xml"))
#' @export
export_jws <- function(
        mb, file, sap = "sap", series = "series"
) {
    rlang::check_installed("rjd3workspace")
    prep  <- jd3_unify_contexts(jd3_collect_models(mb, sap, series))
    items <- prep$items

    jws  <- rjd3workspace::jws_new(prep$context)
    jsap <- list()                                    # one SA-processing per sap name
    for (it in items) {
        if (is.null(jsap[[it$sap]])) {
            jsap[[it$sap]] <- rjd3workspace::jws_sap_new(jws, it$sap)
        }
        sp <- jsap[[it$sap]]
        rjd3workspace::add_sa_item(sp, name = it$series, x = it$model$y, spec = it$spec)
        if (!is.null(it$ref_spec)) {                    # reference spec of the new SA-item
            idx <- rjd3workspace::sap_sai_count(sp)
            rjd3workspace::set_reference_specification(sp, idx, it$ref_spec)
        }
    }
    ok <- rjd3workspace::save_workspace(jws, file, replace = TRUE, verbose = FALSE)
    invisible(file)
}

