# Fitted values, residuals, interpolation and updating of JDemetra+ models

Methods for models fitted with
[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
[`REGARIMA()`](https://aqlt.github.io/fable.rjd3/reference/REGARIMA.md)
or [`TRAMO()`](https://aqlt.github.io/fable.rjd3/reference/TRAMO.md).
They can be applied directly on a mable.

## Usage

``` r
# S3 method for class 'jd3_model'
fitted(object, ...)

# S3 method for class 'jd3_model'
residuals(object, type = c("innovation", "regression"), ...)

# S3 method for class 'jd3_model'
interpolate(object, new_data = NULL, specials = NULL, ...)

# S3 method for class 'jd3_model'
refit(
  object,
  new_data,
  specials = NULL,
  policy = c("Fixed", "FreeParameters", "Complete", "Outliers_StochasticComponent",
    "Outliers", "FixedParameters", "FixedAutoRegressiveParameters", "Current"),
  period = 0,
  start = NULL,
  end = NULL,
  ...
)

# S3 method for class 'jd3_model'
stream(
  object,
  new_data,
  specials = NULL,
  policy = c("Fixed", "FreeParameters", "Complete", "Outliers_StochasticComponent",
    "Outliers", "FixedParameters", "FixedAutoRegressiveParameters", "Current"),
  period = 0,
  start = NULL,
  end = NULL,
  ...
)
```

## Arguments

- object:

  A fitted `jd3_model` (usually a column of a mable).

- ...:

  Currently unused.

- type:

  Residual type: `"innovation"` (default) or `"regression"`.

- new_data:

  A tsibble. For
  [`interpolate()`](https://generics.r-lib.org/reference/interpolate.html),
  the data with missing values (same dates as the data of the model).
  For [`refit()`](https://generics.r-lib.org/reference/refit.html), the
  new full data. For
  [`stream()`](https://fabletools.tidyverts.org/reference/stream.html),
  the new observations only.

- specials:

  Currently unused.

- policy:

  Refresh policy, a character string (see the functions above for the
  available policies; default `"Fixed"`: the estimated parameters are
  kept).

- period, start, end:

  additional parameters used to specify the span when
  `policy = "Current"` or `policy = "Outliers"` or
  `policy = "Outliers_StochasticComponent"` `period`: numeric, number of
  observations in a year (12, 4...), compulsory, if false or missing,
  re-estimation with refreshed specification won't work. When
  `policy = "Outliers"` or `policy = "Outliers_StochasticComponent"`
  `start` has to be specified as the date from which outliers will be
  re-identified `end` is not used, if specified it will be ignored. When
  `policy = "Current"` `start` and `end` have to be both specified and
  indicate the span on which additive outliers (AO) will be added. Span
  definition: `start` and `end`: defined as arrays of two elements: year
  and first period (for example, `period = 12` and `start=c(1980, 1)`
  stands for January 1980)

## Value

- [`fitted()`](https://rdrr.io/r/stats/fitted.values.html),
  [`residuals()`](https://rdrr.io/r/stats/residuals.html): a numeric
  vector with one value per observation (`NA` where undefined). Called
  on a mable, a tibble with the index and the `.fitted` or `.resid`
  column.

- [`interpolate()`](https://generics.r-lib.org/reference/interpolate.html):
  `new_data` with the missing values filled in.

- [`refit()`](https://generics.r-lib.org/reference/refit.html),
  [`stream()`](https://fabletools.tidyverts.org/reference/stream.html):
  a `jd3_model` fitted on the new data. Called on a mable, a mable.

## Details

- [`fitted()`](https://rdrr.io/r/stats/fitted.values.html) returns the
  one-step-ahead fitted values of the pre-adjustment model, on the scale
  of the series. Together with
  [`residuals()`](https://rdrr.io/r/stats/residuals.html), it makes
  [`augment()`](https://generics.r-lib.org/reference/augment.html) and
  [`accuracy()`](https://generics.r-lib.org/reference/accuracy.html)
  work.

- [`residuals()`](https://rdrr.io/r/stats/residuals.html) returns the
  innovation residuals of the pre-adjustment model
  (`type = "innovation"`) or the linearized series the ARIMA part is
  applied to (`type = "regression"`). Dates for which a residual is not
  defined (e.g. lost to differencing) are `NA`.

- [`interpolate()`](https://generics.r-lib.org/reference/interpolate.html)
  replaces the missing values of the series by the estimates of the
  model. `new_data` must cover the same dates as the data used to fit
  the model.

- [`refit()`](https://generics.r-lib.org/reference/refit.html) applies
  the model to new data, using a JDemetra+ refresh policy (see
  [`rjd3x13::x13_refresh()`](https://rjdverse.github.io/rjd3x13/reference/refresh.html)
  and
  [`rjd3tramoseats::tramoseats_refresh()`](https://rjdverse.github.io/rjd3tramoseats/reference/refresh.html)):
  the specification is refreshed from the estimated model and the
  reference specification stored in the model (see the `ref_spec`
  argument of
  [`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md)).

- [`stream()`](https://fabletools.tidyverts.org/reference/stream.html)
  appends new observations to the data of the model and refreshes it in
  the same way. `new_data` contains the new observations only.

## See also

[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
[`forecast.jd3_model()`](https://aqlt.github.io/fable.rjd3/reference/forecast.jd3_model.md),
[jd3_model_methods](https://aqlt.github.io/fable.rjd3/reference/jd3_model_methods.md)

## Examples

``` r
y  <- as_tsibble(AirPassengers)
mb <- model(y, x13 = X13(value))

# Fitted values and residuals (also used by augment() and accuracy())
fitted(mb)
#> # A tsibble: 144 x 3 [1M]
#> # Key:       .model [1]
#>    .model    index .fitted
#>    <chr>     <mth>   <dbl>
#>  1 x13    1949 Jan      NA
#>  2 x13    1949 Feb      NA
#>  3 x13    1949 Mar      NA
#>  4 x13    1949 Apr      NA
#>  5 x13    1949 May      NA
#>  6 x13    1949 Jun      NA
#>  7 x13    1949 Jul      NA
#>  8 x13    1949 Aug      NA
#>  9 x13    1949 Sep      NA
#> 10 x13    1949 Oct      NA
#> # ℹ 134 more rows
residuals(mb)                         # innovation residuals
#> # A tsibble: 144 x 3 [1M]
#> # Key:       .model [1]
#>    .model    index .resid
#>    <chr>     <mth>  <dbl>
#>  1 x13    1949 Jan     NA
#>  2 x13    1949 Feb     NA
#>  3 x13    1949 Mar     NA
#>  4 x13    1949 Apr     NA
#>  5 x13    1949 May     NA
#>  6 x13    1949 Jun     NA
#>  7 x13    1949 Jul     NA
#>  8 x13    1949 Aug     NA
#>  9 x13    1949 Sep     NA
#> 10 x13    1949 Oct     NA
#> # ℹ 134 more rows
residuals(mb, type = "regression")    # linearized series
#> # A tsibble: 144 x 3 [1M]
#> # Key:       .model [1]
#>    .model    index .resid
#>    <chr>     <mth>  <dbl>
#>  1 x13    1949 Jan   4.71
#>  2 x13    1949 Feb   4.78
#>  3 x13    1949 Mar   4.90
#>  4 x13    1949 Apr   4.85
#>  5 x13    1949 May   4.79
#>  6 x13    1949 Jun   4.91
#>  7 x13    1949 Jul   4.99
#>  8 x13    1949 Aug   5.01
#>  9 x13    1949 Sep   4.92
#> 10 x13    1949 Oct   4.77
#> # ℹ 134 more rows
augment(mb)
#> # A tsibble: 144 x 6 [1M]
#> # Key:       .model [1]
#>    .model    index value .fitted .resid .innov
#>    <chr>     <mth> <dbl>   <dbl>  <dbl>  <dbl>
#>  1 x13    1949 Jan   112      NA     NA     NA
#>  2 x13    1949 Feb   118      NA     NA     NA
#>  3 x13    1949 Mar   132      NA     NA     NA
#>  4 x13    1949 Apr   129      NA     NA     NA
#>  5 x13    1949 May   121      NA     NA     NA
#>  6 x13    1949 Jun   135      NA     NA     NA
#>  7 x13    1949 Jul   148      NA     NA     NA
#>  8 x13    1949 Aug   148      NA     NA     NA
#>  9 x13    1949 Sep   136      NA     NA     NA
#> 10 x13    1949 Oct   119      NA     NA     NA
#> # ℹ 134 more rows
accuracy(mb)
#> # A tibble: 1 × 10
#>   .model .type         ME  RMSE   MAE     MPE  MAPE  MASE RMSSE   ACF1
#>   <chr>  <chr>      <dbl> <dbl> <dbl>   <dbl> <dbl> <dbl> <dbl>  <dbl>
#> 1 x13    Training -0.0642  8.53  6.75 -0.0109  2.45 0.211 0.235 0.0200

# Interpolation of missing values
y_na <- y
y_na$value[c(20, 21)] <- NA
mb_na <- model(y_na, x13 = X13(value))
interpolate(mb_na, y_na)
#> # A tsibble: 144 x 2 [1M]
#>       index value
#>       <mth> <dbl>
#>  1 1949 Jan   112
#>  2 1949 Feb   118
#>  3 1949 Mar   132
#>  4 1949 Apr   129
#>  5 1949 May   121
#>  6 1949 Jun   135
#>  7 1949 Jul   148
#>  8 1949 Aug   148
#>  9 1949 Sep   136
#> 10 1949 Oct   119
#> # ℹ 134 more rows

# Updating a model when new observations arrive
start_new <- yearmonth("1960 Jan")
y_old  <- y[y$index < start_new, ]
y_new  <- y[y$index >= start_new, ]
mb_old <- model(y_old, x13 = X13(value))

# stream(): append the new observations, estimated parameters kept
mb_ext <- stream(mb_old, y_new)
components(mb_ext)
#> # A dable: 144 x 7 [1M]
#> # Key:     .model [1]
#> # :        value = trend * seasonal * irregular
#>    .model    index value trend seasonal irregular season_adjust
#>    <chr>     <mth> <dbl> <dbl>    <dbl>     <dbl>         <dbl>
#>  1 x13    1949 Jan   112  122.    0.919     0.995          122.
#>  2 x13    1949 Feb   118  125.    0.949     0.998          124.
#>  3 x13    1949 Mar   132  127.    1.05      0.997          126.
#>  4 x13    1949 Apr   129  128.    0.996     1.01           130.
#>  5 x13    1949 May   121  128.    0.943     1.00           128.
#>  6 x13    1949 Jun   135  127.    1.07      0.999          127.
#>  7 x13    1949 Jul   148  126.    1.19      0.989          125.
#>  8 x13    1949 Aug   148  126.    1.17      0.999          126.
#>  9 x13    1949 Sep   136  127.    1.07      1.00           128.
#> 10 x13    1949 Oct   119  128.    0.925     1.01           129.
#> # ℹ 134 more rows

# refit(): apply the model to the full data
refit(mb_old, y)                      # refresh policy "Fixed" (default)
#> # A mable: 1 x 1
#>                                x13
#>                            <model>
#> 1 <X-13ARIMA, ARIMA(0,1,1)(0,1,1)>
```
