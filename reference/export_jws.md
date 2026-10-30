# Export a mable of JDemetra+ models as a new workspace

Writes a new workspace readable by the JDemetra+ graphical interface,
with one SA-item per model: raw series, estimation specification,
reference specification, and the modelling context (calendars and
regressors). A workspace has a single context: regressors of different
models that share the same name but have different values (e.g.
`xreg(col)` in several series) are renamed `<name>_<sap>_<series>`, in
the context and in the specifications. Results, comments, priorities and
links to data providers are not exported; the series are stored as
static data.

## Usage

``` r
export_jws(mb, file, replace = FALSE, sap = "sap", series = "series")
```

## Arguments

- mb:

  A mable of models fitted with
  [`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md) or
  [`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md).

- file:

  Path of the workspace (xml master file) to create.

- replace:

  Replace the workspace if `file` already exists. By default an existing
  file is never overwritten.

- sap, series:

  Names of the key columns giving the SA-processing and the SA-item.
  Without them, a single SA-processing is created and the SA-item names
  are built from the other keys.

## Value

`file`, invisibly.

## See also

[`import_jws()`](https://aqlt.github.io/fable.rjd3/reference/import_jws.md)

## Examples

``` r
mb <- model(as_tsibble(AirPassengers), sa = X13(value))
export_jws(mb, tempfile(fileext = ".xml"))
```
