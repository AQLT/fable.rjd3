# Reg-ARIMA Model

Defines a Reg-ARIMA model (the pre-adjustment model used in X-13),
without seasonal adjustment, to be used inside
[`fabletools::model()`](https://fabletools.tidyverts.org/reference/model.html).
The model is estimated with
[`rjd3x13::jregarima()`](https://rjdverse.github.io/rjd3x13/reference/regarima.html)
and the Java result is kept in the fitted model. Arguments and specials
are the same as for
[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md), except
[`x11()`](https://rdrr.io/r/grDevices/x11.html), `seats()` and
`benchmarking()`, which do not apply and are ignored with a warning.

## Usage

``` r
REGARIMA(
  formula,
  spec = c("rg4", "rg0", "rg1", "rg2c", "rg3", "rg5c"),
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
  [`rjd3x13::regarima_spec()`](https://rjdverse.github.io/rjd3x13/reference/x13_spec.html)
  for the available names; the default is the first one) or a
  specification object from
  [`rjd3x13::regarima_spec()`](https://rjdverse.github.io/rjd3x13/reference/x13_spec.html).

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

[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
[`TRAMO()`](https://aqlt.github.io/fable.rjd3/reference/TRAMO.md),
[jd3_specials](https://aqlt.github.io/fable.rjd3/reference/jd3_specials.md),
[jd3_model_methods](https://aqlt.github.io/fable.rjd3/reference/jd3_model_methods.md)

## Examples

``` r
y <- tsibble::as_tsibble(AirPassengers)
mb <- model(y, regarima = REGARIMA(value))
tidy(mb)
#> # A tibble: 5 × 6
#>   .model   term         estimate std.error statistic  p.value
#>   <chr>    <chr>           <dbl>     <dbl>     <dbl>    <dbl>
#> 1 regarima theta(1)     -0.116    0.109        -1.06 2.89e- 1
#> 2 regarima btheta(1)    -0.497    0.0723       -6.88 2.55e-10
#> 3 regarima td2          -0.00295  0.000533     -5.53 1.79e- 7
#> 4 regarima easter [1]    0.0178   0.00730       2.43 1.63e- 2
#> 5 regarima AO (1951-05)  0.100    0.0208        4.81 4.33e- 6
report(mb)
#> Series: value 
#> Model: REGARIMA, ARIMA(0,1,1)(0,1,1) 
#> Transformation: Log; N obs.: 144 
#> 
#> 
#> Coefficients
#>                Estimate Std. Error t value Pr(>|t|)    
#> theta(1)     -0.1155344  0.1085487  -1.064   0.2892    
#> btheta(1)    -0.4974142  0.0722919  -6.881 2.55e-10 ***
#> td2          -0.0029497  0.0005334  -5.530 1.79e-07 ***
#> easter [1]    0.0177674  0.0072985   2.434   0.0163 *  
#> AO (1951-05)  0.1001562  0.0208399   4.806 4.33e-06 ***
#> ---
#> Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
#> 
#> Tests on residuals: Independence (Ljung-Box: Good, 0.354); Normality (Doornik-Hansen: Good, 0.683)

# Forecasts of the raw series
forecast(mb, h = 12)
#> # A fable: 12 x 4 [1M]
#> # Key:     .model [1]
#>    .model      index
#>    <chr>       <mth>
#>  1 regarima 1961 Jan
#>  2 regarima 1961 Feb
#>  3 regarima 1961 Mar
#>  4 regarima 1961 Apr
#>  5 regarima 1961 May
#>  6 regarima 1961 Jun
#>  7 regarima 1961 Jul
#>  8 regarima 1961 Aug
#>  9 regarima 1961 Sep
#> 10 regarima 1961 Oct
#> 11 regarima 1961 Nov
#> 12 regarima 1961 Dec
#> # ℹ 2 more variables: value <dist>, .mean <dbl>
```
