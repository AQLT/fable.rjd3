# List the indicators available in a fitted model

Wraps
[`rjd3toolkit::dictionary()`](https://rjdverse.github.io/rjd3toolkit/reference/dictionary.html)
on the Java result of the model. The returned ids can be passed to
[`jd3_indicator()`](https://aqlt.github.io/fable.rjd3/reference/jd3_indicator.md).

## Usage

``` r
jd3_dictionary(object, ...)

# S3 method for class 'jd3_model'
jd3_dictionary(object, ...)

# S3 method for class 'mdl_ts'
jd3_dictionary(object, ...)

# S3 method for class 'mdl_df'
jd3_dictionary(object, ...)
```

## Arguments

- object:

  A fitted mable (`mdl_df`), a `mdl_ts` or a `jd3_model`.

- ...:

  Currently unused.

## Value

A data frame (class `JD3_FULL_DICTIONARY`) with one row per indicator:
its id (`name`), description and output type. For a mable, the
dictionary of the first model is returned.

## See also

[`jd3_indicator()`](https://aqlt.github.io/fable.rjd3/reference/jd3_indicator.md)

## Examples

``` r

mb <- model(tsibble::as_tsibble(AirPassengers), x13 = X13(value))
head(jd3_dictionary(mb))
#> [1] "out_i"      "out_i_f(?)" "out_i_b(?)" "out_t"      "out_t_f(?)"
#> [6] "out_t_b(?)"
```
