# Import a JDemetra+ workspace as a mable

Reads all the SA-items of a workspace and fits them with
[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md) or
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md)
using the specifications stored in the workspace: the estimation
specification is the model specification, the reference specification is
kept for the refresh policies (see
[jd3_model_methods_extra](https://aqlt.github.io/fable.rjd3/reference/jd3_model_methods_extra.md)).

## Usage

``` r
import_jws(file, compute = TRUE)
```

## Arguments

- file:

  Path to the master xml file of the workspace.

- compute:

  Compute the workspace before reading it (required to access the
  SA-items).

## Value

A mable with the key columns `sap` (SA-processing) and `series`
(SA-item), and a model column `sa` holding `X13` and `TRAMOSEATS`
models. SA-items with another type of specification (e.g. RegARIMA only)
are skipped with a warning.

## See also

[`export_jws()`](https://aqlt.github.io/fable.rjd3/reference/export_jws.md)

## Examples

``` r
file <- system.file("workspaces", "workspace_test.xml", package = "rjd3workspace")
mb <- import_jws(file)
mb
#> # A mable: 9 x 3
#> # Key:     sap, series [9]
#>   sap            series                                 sa
#>   <chr>          <chr>                             <model>
#> 1 SAProcessing-1 RF0812   <X-13ARIMA, ARIMA(2,1,1)(0,1,1)>
#> 2 SAProcessing-1 RF0893   <X-13ARIMA, ARIMA(0,1,1)(0,1,1)>
#> 3 SAProcessing-1 RF0899   <X-13ARIMA, ARIMA(0,1,1)(0,1,1)>
#> 4 SAProcessing-1 RF1011   <X-13ARIMA, ARIMA(2,1,0)(0,1,1)>
#> 5 SAProcessing-1 RF1012   <X-13ARIMA, ARIMA(1,1,1)(0,1,1)>
#> 6 SAProcessing-2 RF0893 <TRAMO-SEATS, ARIMA(1,1,1)(0,1,1)>
#> 7 SAProcessing-2 RF0899 <TRAMO-SEATS, ARIMA(0,1,1)(0,1,1)>
#> 8 SAProcessing-2 RF1011   <X-13ARIMA, ARIMA(0,1,2)(0,1,1)>
#> 9 SAProcessing-2 RF1012 <TRAMO-SEATS, ARIMA(1,1,1)(0,1,1)>
```
