# TRAMO Model

Defines a TRAMO model (the pre-adjustment model used in TRAMO-SEATS),
without seasonal adjustment, to be used inside
[`fabletools::model()`](https://fabletools.tidyverts.org/reference/model.html).
The model is estimated with
[`rjd3tramoseats::jtramo()`](https://rjdverse.github.io/rjd3tramoseats/reference/tramo.html)
and the Java result is kept in the fitted model. Arguments and specials
are the same as for
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
except [`x11()`](https://rdrr.io/r/grDevices/x11.html), `seats()` and
`benchmarking()`, which do not apply and are ignored with a warning.

## Usage

``` r
TRAMO(
  formula,
  spec = c("trfull", "tr0", "tr1", "tr2", "tr3", "tr4", "tr5"),
  context = NULL,
  ref_spec = spec,
  ...
)
```

## Arguments

- formula:

  Model formula: the name of the variable to adjust (`y`), or
  `y ~ specials` (see
  [jd3_specials](https://aqlt.github.io/fable.rjd3/reference/jd3_specials.md)).

- spec:

  Base specification: a character name (see
  [`rjd3tramoseats::tramo_spec()`](https://rjdverse.github.io/rjd3tramoseats/reference/tramoseats_spec.html)
  for the available names; the default is the first one) or a
  specification object from
  [`rjd3tramoseats::tramo_spec()`](https://rjdverse.github.io/rjd3tramoseats/reference/tramoseats_spec.html).

- context:

  A modelling context created with
  [`rjd3toolkit::modelling_context()`](https://rjdverse.github.io/rjd3toolkit/reference/modelling_context.html)
  (e.g. for custom calendars), or `NULL`.

- ref_spec:

  Reference specification stored in the model: it is the reference of
  the refresh policies used by
  [`refit()`](https://generics.r-lib.org/reference/refit.html) and
  [`stream()`](https://fabletools.tidyverts.org/reference/stream.html).
  Defaults to `spec`, that is the specification before its modification
  by the specials.

- ...:

  Currently unused.

## Value

A model definition that can be passed to
[`fabletools::model()`](https://fabletools.tidyverts.org/reference/model.html).
Once fitted, the mable column contains a `jd3_model` object.

## Details

There is no decomposition, so
[`components()`](https://generics.r-lib.org/reference/components.html)
is not available. The other methods are:
[`fitted()`](https://rdrr.io/r/stats/fitted.values.html),
[`residuals()`](https://rdrr.io/r/stats/residuals.html),
[`forecast()`](https://generics.r-lib.org/reference/forecast.html),
[`backcast()`](https://aqlt.github.io/fable.rjd3/reference/backcast.md),
[`outliers()`](https://fabletools.tidyverts.org/reference/outliers.html),
[`tidy()`](https://generics.r-lib.org/reference/tidy.html),
[`glance()`](https://generics.r-lib.org/reference/glance.html) and
[`report()`](https://fabletools.tidyverts.org/reference/report.html).

## See also

[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
[`REGARIMA()`](https://aqlt.github.io/fable.rjd3/reference/REGARIMA.md),
[jd3_specials](https://aqlt.github.io/fable.rjd3/reference/jd3_specials.md),
[jd3_model_methods](https://aqlt.github.io/fable.rjd3/reference/jd3_model_methods.md)

## Examples

``` r
y <- tsibble::as_tsibble(AirPassengers)
mb <- model(y, tramo = TRAMO(value))
tidy(mb)
#> # A tibble: 6 × 6
#>   .model term         estimate std.error statistic  p.value
#>   <chr>  <chr>           <dbl>     <dbl>     <dbl>    <dbl>
#> 1 tramo  btheta(1)    -0.498    0.0710       -7.01 1.34e-10
#> 2 tramo  td2          -0.00298  0.000475     -6.28 5.28e- 9
#> 3 tramo  Leap year     0.0409   0.0116        3.52 5.96e- 4
#> 4 tramo  easter [6]    0.0198   0.00692       2.87 4.85e- 3
#> 5 tramo  AO (1951-05)  0.101    0.0189        5.36 3.97e- 7
#> 6 tramo  AO (1954-02) -0.0698   0.0186       -3.74 2.76e- 4
report(mb)
#> Series: value 
#> Model: TRAMO, ARIMA(0,1,0)(0,1,1) 
#> Transformation: Log; N obs.: 144 
#> 
#> 
#> Coefficients
#>                Estimate Std. Error t value Pr(>|t|)    
#> btheta(1)    -0.4981058  0.0710399  -7.012 1.34e-10 ***
#> td2          -0.0029813  0.0004749  -6.278 5.28e-09 ***
#> Leap year     0.0408796  0.0116009   3.524 0.000596 ***
#> easter [6]    0.0198358  0.0069154   2.868 0.004851 ** 
#> AO (1951-05)  0.1014823  0.0189455   5.357 3.97e-07 ***
#> AO (1954-02) -0.0697738  0.0186375  -3.744 0.000276 ***
#> ---
#> Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
#> 
#> Tests on residuals: Independence (Ljung-Box: Good, 0.128); Normality (Doornik-Hansen: Good, 0.659)

# Forecasts of the raw series
forecast(mb, h = 12)
#> # A fable: 12 x 4 [1M]
#> # Key:     .model [1]
#>    .model    index
#>    <chr>     <mth>
#>  1 tramo  1961 Jan
#>  2 tramo  1961 Feb
#>  3 tramo  1961 Mar
#>  4 tramo  1961 Apr
#>  5 tramo  1961 May
#>  6 tramo  1961 Jun
#>  7 tramo  1961 Jul
#>  8 tramo  1961 Aug
#>  9 tramo  1961 Sep
#> 10 tramo  1961 Oct
#> 11 tramo  1961 Nov
#> 12 tramo  1961 Dec
#> # ℹ 2 more variables: value <dist>, .mean <dbl>
```
