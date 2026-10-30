# Methods for fitted JDemetra+ models

Standard `fabletools` / `generics` verbs for models fitted with
[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
[`REGARIMA()`](https://aqlt.github.io/fable.rjd3/reference/REGARIMA.md)
and [`TRAMO()`](https://aqlt.github.io/fable.rjd3/reference/TRAMO.md).
They can be applied directly on a mable.
[`components()`](https://generics.r-lib.org/reference/components.html)
is only available for the seasonal adjustment models
([`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md) and
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md)).

## Usage

``` r
# S3 method for class 'jd3_model'
glance(x, ids = NULL, ...)

# S3 method for class 'jd3_sa_model'
components(object, ...)

# S3 method for class 'jd3_model'
model_sum(x)

# S3 method for class 'jd3_model'
tidy(x, ...)

# S3 method for class 'jd3_model'
report(
  object,
  digits = max(3L, getOption("digits") - 3L),
  signif.stars = getOption("show.signif.stars"),
  thresholds_pval = getOption("fable.rjd3.thresholds_pval"),
  ...
)
```

## Arguments

- ids:

  For [`glance()`](https://generics.r-lib.org/reference/glance.html):
  named or unnamed character vector of indicator ids (see
  [`jd3_dictionary()`](https://aqlt.github.io/fable.rjd3/reference/jd3_dictionary.md));
  the names become the column names. Numbers and strings give one
  column; tests give two columns, `<name>_stat` and `<name>_pvalue`;
  other indicators give `NA`. If `NULL`, the default set of the method
  is used (information criteria, number of observations, tests on the
  residuals and on the seasonally adjusted series, M and Q statistics
  for X-13, SEATS tests for TRAMO-SEATS).

- ...:

  Currently unused.

- object, x:

  A `jd3_model` (usually accessed through a mable).

- digits:

  minimum number of significant digits to be used for most numbers.

- signif.stars:

  logical; if `TRUE`, P-values are additionally encoded visually as
  ‘significance stars’ in order to help scanning of long coefficient
  tables. It defaults to the `show.signif.stars` slot of
  [`options`](https://rdrr.io/r/base/options.html).

- thresholds_pval:

  Threshold used to interpret p-values statistic test. By default
  `c(Severe = 0.001, Bad = 0.01, Uncertain = 0.05, Good = Inf)`.

## Value

- [`components()`](https://generics.r-lib.org/reference/components.html):
  a `dable` with the response and the columns `trend`, `seasonal`,
  `irregular` and `season_adjust`.

- [`glance()`](https://generics.r-lib.org/reference/glance.html): a
  one-row tibble of diagnostics.

- [`tidy()`](https://generics.r-lib.org/reference/tidy.html): a tibble
  with one row per coefficient (ARIMA parameters, regression variables,
  outliers, calendar effects) and the columns `term`, `estimate`,
  `std.error`, `statistic` and `p.value`. Coefficients fixed in the
  specification are included, with missing standard errors and tests.

- [`report()`](https://fabletools.tidyverts.org/reference/report.html):
  invisibly, the model; prints the decomposition mode or the
  transformation, the number of observations, the coefficients, the
  tests on the residuals and, for seasonal adjustment models, the
  quality diagnostics (M and Q statistics, residual seasonality tests on
  the adjusted series).

- [`model_sum()`](https://fabletools.tidyverts.org/reference/model_sum.html):
  a short string describing the model.

## Examples

``` r
mb <- model(tsibble::as_tsibble(AirPassengers), x13 = X13(value))
components(mb)
#> # A dable: 144 x 7 [1M]
#> # Key:     .model [1]
#> # :        value = trend * seasonal * irregular
#>    .model    index value trend seasonal irregular season_adjust
#>    <chr>     <mth> <dbl> <dbl>    <dbl>     <dbl>         <dbl>
#>  1 x13    1949 Jan   112  122.    0.920     0.996          122.
#>  2 x13    1949 Feb   118  124.    0.948     1.00           125.
#>  3 x13    1949 Mar   132  126.    1.05      0.994          125.
#>  4 x13    1949 Apr   129  128.    1.00      1.01           129.
#>  5 x13    1949 May   121  128.    0.939     1.01           129.
#>  6 x13    1949 Jun   135  127.    1.07      0.998          127.
#>  7 x13    1949 Jul   148  126.    1.19      0.988          125.
#>  8 x13    1949 Aug   148  126.    1.17      0.999          126.
#>  9 x13    1949 Sep   136  127.    1.07      1.00           128.
#> 10 x13    1949 Oct   119  128.    0.925     1.00           129.
#> # ℹ 134 more rows
glance(mb)
#> # A tibble: 1 × 19
#>   .model  aicc  nobs nparams  nout lb_stat lb_pvalue normality_stat
#>   <chr>  <dbl> <dbl>   <dbl> <dbl>   <dbl>     <dbl>          <dbl>
#> 1 x13     947.   144       6     1    23.9     0.354          0.763
#> # ℹ 11 more variables: normality_pvalue <dbl>, ftest_sa_stat <dbl>,
#> #   ftest_sa_pvalue <dbl>, qs_test_sa_stat <dbl>, qs_test_sa_pvalue <dbl>,
#> #   combined_test_sa <chr>, combined_test_sa_lastyears <chr>,
#> #   td_on_sa_stat <dbl>, td_on_sa_pvalue <dbl>, Q <dbl>, Q_M2 <dbl>
tidy(mb)
#> # A tibble: 5 × 6
#>   .model term         estimate std.error statistic  p.value
#>   <chr>  <chr>           <dbl>     <dbl>     <dbl>    <dbl>
#> 1 x13    theta(1)     -0.116    0.109        -1.06 2.89e- 1
#> 2 x13    btheta(1)    -0.497    0.0723       -6.88 2.55e-10
#> 3 x13    td2          -0.00295  0.000533     -5.53 1.79e- 7
#> 4 x13    easter [1]    0.0178   0.00730       2.43 1.63e- 2
#> 5 x13    AO (1951-05)  0.100    0.0208        4.81 4.33e- 6
report(mb)
#> Series: value 
#> Model: X-13ARIMA, ARIMA(0,1,1)(0,1,1) 
#> Mode: Multiplicative; N obs.: 144 
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
#> Filters: S3X3, H-9; M-Statistics: q (Good, 0.198); q-m2 (Good, 0.219)
#> Tests on SA: QS (Good, 1.000); F-test (Good, 0.959)
#> Combined test on SA: None (last years: None)
#> Residual trading days on SA (F-test): Good (0.223)
```
