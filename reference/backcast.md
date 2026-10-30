# Backcast of the raw series

Backcasts the raw series, i.e. predicts the periods preceding its start,
from the pre-adjustment model of a model fitted with
[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
[`REGARIMA()`](https://aqlt.github.io/fable.rjd3/reference/REGARIMA.md)
or [`TRAMO()`](https://aqlt.github.io/fable.rjd3/reference/TRAMO.md).
fabletools has no backcast generic, so this function plays the role of
[forecast()](https://aqlt.github.io/fable.rjd3/reference/forecast.jd3_model.md)
for the past. The distribution is built as for forecasts (log-normal for
log-transformed series, normal otherwise; see the *Distribution* section
of
[forecast.jd3_model](https://aqlt.github.io/fable.rjd3/reference/forecast.jd3_model.md)).

## Usage

``` r
backcast(object, h, ...)

# S3 method for class 'jd3_model'
backcast(object, h, ...)

# S3 method for class 'mdl_ts'
backcast(object, h, ...)

# S3 method for class 'mdl_df'
backcast(object, h, ...)
```

## Arguments

- object:

  A fitted `jd3_model` (usually a column of a mable).

- h:

  Number of periods to backcast, immediately before the start of the
  series.

- ...:

  Other arguments passed by
  [`forecast()`](https://generics.r-lib.org/reference/forecast.html)
  (e.g. `times`), ignored.

## Value

For a `jd3_model` or a `mdl_ts`, a tsibble with the `h` dates preceding
the series and a distribution column `dist` (see distributional). For a
mable, a tibble with the key columns, `.model`, the dates and `dist`,
one block per model. Use [`mean()`](https://rdrr.io/r/base/mean.html) or
[`median()`](https://rdrr.io/r/stats/median.html) on `dist` to get a
point backcast; the median equals JDemetra+'s backcast.

## See also

[forecast.jd3_model](https://aqlt.github.io/fable.rjd3/reference/forecast.jd3_model.md),
[`jd3_indicator()`](https://aqlt.github.io/fable.rjd3/reference/jd3_indicator.md)
for the raw indicators (`y_b`, `y_eb`...).

## Examples

``` r
y  <- tsibble::as_tsibble(AirPassengers)
mb <- model(y, x13 = X13(value))

bc <- backcast(mb, h = 12)
bc
#> # A tibble: 12 × 3
#>    .model    index
#>    <chr>     <mth>
#>  1 x13    1948 Jan
#>  2 x13    1948 Feb
#>  3 x13    1948 Mar
#>  4 x13    1948 Apr
#>  5 x13    1948 May
#>  6 x13    1948 Jun
#>  7 x13    1948 Jul
#>  8 x13    1948 Aug
#>  9 x13    1948 Sep
#> 10 x13    1948 Oct
#> 11 x13    1948 Nov
#> 12 x13    1948 Dec
#> # ℹ 1 more variable: dist <dist>

# A single model
bc1 <- backcast(mb$x13[[1]], h = 12)
median(bc1$dist)
#>  [1] 102.01134 109.21372 122.48921 115.92638 109.30768 127.82206 138.17197
#>  [8] 138.91709 130.22180 108.52204  96.88531 113.92835
```
