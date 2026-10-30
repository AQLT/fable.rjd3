# Forecast of the raw series

Forecasts the raw series from the pre-adjustment model (RegARIMA /
TRAMO) of a model fitted with
[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
[`REGARIMA()`](https://aqlt.github.io/fable.rjd3/reference/REGARIMA.md)
or [`TRAMO()`](https://aqlt.github.io/fable.rjd3/reference/TRAMO.md).
The values are read from the stored JDemetra+ result, so the seasonal
adjustment itself is not affected. For the past, see
[`backcast()`](https://aqlt.github.io/fable.rjd3/reference/backcast.md).

## Usage

``` r
# S3 method for class 'jd3_model'
forecast(object, new_data = NULL, ...)
```

## Arguments

- object:

  A fitted `jd3_model` (usually a column of a mable).

- new_data:

  A tsibble of future dates, built by fabletools from the horizon `h`.
  It must start right after the end of the series.

- ...:

  Other arguments passed by
  [`forecast()`](https://generics.r-lib.org/reference/forecast.html)
  (e.g. `times`), ignored.

## Value

A distribution vector (see distributional) with one element per row of
`new_data`: log-normal if the series is log-transformed, normal
otherwise. Called through
[`forecast()`](https://generics.r-lib.org/reference/forecast.html) on a
mable, the result is a fable.

## Distribution

For log-transformed series, the forecast distribution is log-normal,
with a median equal to JDemetra+'s forecast (a plain back-transformation
of the forecast of the log). Its mean is therefore the bias-corrected
forecast, and the difference grows with the horizon. For other series,
the distribution is normal and its mean equals the median.

The default point forecast `.mean` of the resulting fable is the mean of
the distribution. Use the `point_forecast` argument of
[`forecast()`](https://generics.r-lib.org/reference/forecast.html) to
choose another summary, e.g. `point_forecast = list(.median = median)`
to obtain JDemetra+'s forecast.

## See also

[`backcast()`](https://aqlt.github.io/fable.rjd3/reference/backcast.md),
[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
[`jd3_indicator()`](https://aqlt.github.io/fable.rjd3/reference/jd3_indicator.md)
to extract the raw indicators (`y_f`, `y_ef`...).

## Examples

``` r
y  <- tsibble::as_tsibble(AirPassengers)
mb <- model(y, x13 = X13(value))

# The mean is the bias-corrected forecast
forecast(mb, h = 12)
#> # A fable: 12 x 4 [1M]
#> # Key:     .model [1]
#>    .model    index
#>    <chr>     <mth>
#>  1 x13    1961 Jan
#>  2 x13    1961 Feb
#>  3 x13    1961 Mar
#>  4 x13    1961 Apr
#>  5 x13    1961 May
#>  6 x13    1961 Jun
#>  7 x13    1961 Jul
#>  8 x13    1961 Aug
#>  9 x13    1961 Sep
#> 10 x13    1961 Oct
#> 11 x13    1961 Nov
#> 12 x13    1961 Dec
#> # ℹ 2 more variables: value <dist>, .mean <dbl>

# JDemetra+'s own forecast (median of the distribution)
forecast(mb, h = 12, point_forecast = list(.median = median))
#> # A fable: 12 x 4 [1M]
#> # Key:     .model [1]
#>    .model    index
#>    <chr>     <mth>
#>  1 x13    1961 Jan
#>  2 x13    1961 Feb
#>  3 x13    1961 Mar
#>  4 x13    1961 Apr
#>  5 x13    1961 May
#>  6 x13    1961 Jun
#>  7 x13    1961 Jul
#>  8 x13    1961 Aug
#>  9 x13    1961 Sep
#> 10 x13    1961 Oct
#> 11 x13    1961 Nov
#> 12 x13    1961 Dec
#> # ℹ 2 more variables: value <dist>, .median <dbl>
```
