# Extract the model object from a fitted mable cell

Returns the `jd3_model` object stored in a fitted model. It is mostly
useful for programming;
[`jd3_indicator()`](https://aqlt.github.io/fable.rjd3/reference/jd3_indicator.md)
and
[`jd3_dictionary()`](https://aqlt.github.io/fable.rjd3/reference/jd3_dictionary.md)
call it internally.

## Usage

``` r
jd3_model(x)
```

## Arguments

- x:

  A `mdl_ts` (e.g. `mb$x13[[1]]`) or a `jd3_model`.

## Value

A `jd3_model` object: a list holding the data (a tsibble), the series
(`ts`), the final specification (`spec`), the reference specification
(`ref_spec`), the modelling context, the engine, the name of the
response and a cache for the Java result.

## Examples

``` r
mb <- model(tsibble::as_tsibble(AirPassengers), x13 = X13(value))
m <- jd3_model(mb$x13[[1]])
class(m)
#> [1] "X13"          "jd3_model"    "jd3_sa_model"
```
