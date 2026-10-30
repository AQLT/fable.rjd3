# Identify the outliers of a JDemetra+ model

Returns the outlying observations detected (or specified) in the
pre-adjustment model of a model fitted with
[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
[`REGARIMA()`](https://aqlt.github.io/fable.rjd3/reference/REGARIMA.md)
or [`TRAMO()`](https://aqlt.github.io/fable.rjd3/reference/TRAMO.md):
additive outliers (AO), level shifts (LS), transitory changes (TC) and
seasonal outliers (SO). An outlier is dated at one observation, even
when its effect (e.g. a level shift) lasts longer.

## Usage

``` r
# S3 method for class 'jd3_model'
outliers(object, type = NULL, ...)
```

## Arguments

- object:

  A fitted `jd3_model` (usually a column of a mable).

- type:

  Optional character vector of outlier types to keep, e.g.
  `c("AO", "LS")`. `NULL` (default) keeps all of them.

- ...:

  Currently unused.

## Value

For a `jd3_model`, an integer vector with the row positions of the
outliers in the data of the model (the contract of
[`fabletools::outliers()`](https://fabletools.tidyverts.org/reference/outliers.html)).
Called on a mable,
[`outliers()`](https://fabletools.tidyverts.org/reference/outliers.html)
returns the corresponding rows of the data, with the key columns and
`.model`. The type, estimate and test statistics of the outliers are
available in
[tidy()](https://aqlt.github.io/fable.rjd3/reference/jd3_model_methods.md).

## See also

[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
[jd3_model_methods](https://aqlt.github.io/fable.rjd3/reference/jd3_model_methods.md)

## Examples

``` r
mb <- model(tsibble::as_tsibble(AirPassengers), x13 = X13(value))

# Rows of the data that are outliers
outliers(mb)
#> # A tsibble: 1 x 3 [1M]
#> # Key:       .model [1]
#>   .model    index value
#>   <chr>     <mth> <dbl>
#> 1 x13    1951 May   172

# Additive outliers only
outliers(mb, type = "AO")
#> # A tsibble: 1 x 3 [1M]
#> # Key:       .model [1]
#>   .model    index value
#>   <chr>     <mth> <dbl>
#> 1 x13    1951 May   172
```
