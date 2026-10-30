# Extract any JDemetra+ indicator from a fitted model

Wraps
[`rjd3toolkit::result()`](https://rjdverse.github.io/rjd3toolkit/reference/dictionary.html)
on the Java result of the model. If the Java pointer is no longer valid
(e.g. after
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html)/[`readRDS()`](https://rdrr.io/r/base/readRDS.html)),
the model is transparently re-estimated (once per loaded object). The
ids available are listed by
[`jd3_dictionary()`](https://aqlt.github.io/fable.rjd3/reference/jd3_dictionary.md).

## Usage

``` r
jd3_indicator(object, id, ...)

# S3 method for class 'jd3_model'
jd3_indicator(object, id, drop = TRUE, ...)

# S3 method for class 'mdl_ts'
jd3_indicator(object, id, drop = TRUE, ...)

# S3 method for class 'mdl_df'
jd3_indicator(object, id, simplify = TRUE, drop = TRUE, ...)
```

## Arguments

- object:

  A fitted mable (`mdl_df`), a `mdl_ts` or a `jd3_model`.

- id:

  Indicator id (see
  [`jd3_dictionary()`](https://aqlt.github.io/fable.rjd3/reference/jd3_dictionary.md)).

- ...:

  Currently unused.

- drop:

  If `TRUE` (default) and a single `id` is given, the indicator itself
  is returned instead of a list of length one. Several ids always give a
  named list.

- simplify:

  For a mable only: simplify the result according to the type of the
  indicator (see *Value*). `FALSE` always returns a list-column.

## Value

For a `mdl_ts` or `jd3_model`, the indicator as returned by
[`rjd3toolkit::result()`](https://rjdverse.github.io/rjd3toolkit/reference/dictionary.html):
a number, a string, a `ts`, a matrix, a `JD3_TEST`...

For a mable, a tibble with the key columns, `.model`, `id` and:

- numbers or strings: a column `value`;

- `ts` series: one row per date, with columns `index` and `value`;

- tests: columns `statistic`, `p.value` and `distribution`;

- anything else (or `simplify = FALSE`): a list-column `value` with one
  element per model. With several ids (or `drop = FALSE`), a named list
  of such tibbles, one per id.

## See also

[`jd3_dictionary()`](https://aqlt.github.io/fable.rjd3/reference/jd3_dictionary.md)

## Examples

``` r
# \donttest{
mb <- model(as_tsibble(AirPassengers), x13 = X13(value), ts = TRAMOSEATS(value))

jd3_indicator(mb, "likelihood.aic")      # one number per model
#> # A tibble: 2 × 3
#>   .model id             value
#>   <chr>  <chr>          <dbl>
#> 1 x13    likelihood.aic  947.
#> 2 ts     likelihood.aic  935.
jd3_indicator(mb, "sa")                  # seasonally adjusted series, long format
#> # A tibble: 288 × 4
#>    .model id       index value
#>    <chr>  <chr>    <mth> <dbl>
#>  1 x13    sa    1949 Jan  122.
#>  2 x13    sa    1949 Feb  125.
#>  3 x13    sa    1949 Mar  125.
#>  4 x13    sa    1949 Apr  129.
#>  5 x13    sa    1949 May  129.
#>  6 x13    sa    1949 Jun  127.
#>  7 x13    sa    1949 Jul  125.
#>  8 x13    sa    1949 Aug  126.
#>  9 x13    sa    1949 Sep  128.
#> 10 x13    sa    1949 Oct  129.
#> # ℹ 278 more rows
jd3_indicator(mb, "residuals.kurtosis")  # test: statistic and p-value
#> # A tibble: 2 × 5
#>   .model id                 statistic p.value distribution                      
#>   <chr>  <chr>                  <dbl>   <dbl> <chr>                             
#> 1 x13    residuals.kurtosis      3.10   0.806 Normal with Mean = 3.0 and Stdev …
#> 2 ts     residuals.kurtosis      2.90   0.817 Normal with Mean = 3.0 and Stdev …

# The raw object of a single model
jd3_indicator(mb$x13[[1]], "sa")
#>           Jan      Feb      Mar      Apr      May      Jun      Jul      Aug
#> 1949 121.7202 124.5235 125.3989 128.9076 128.8437 126.7308 124.6712 126.0850
#> 1950 125.6865 133.5459 134.2574 133.9260 134.1034 139.5782 142.8219 144.5915
#> 1951 159.3326 160.9571 165.6360 166.9271 182.7617 164.6639 168.0976 168.7858
#> 1952 187.9674 190.2420 182.7310 185.1004 190.0056 200.1497 194.4352 200.1589
#> 1953 214.4421 218.5414 228.2417 240.8908 232.6058 223.6963 219.9353 224.3191
#> 1954 221.9589 213.4096 233.3723 233.2509 236.7465 239.9818 244.8226 242.7448
#> 1955 263.1890 268.4385 269.4705 274.0846 275.9289 283.4864 288.3001 287.9976
#> 1956 311.1830 312.5324 316.4456 325.7445 328.9640 330.2841 327.3915 331.8471
#> 1957 348.6708 353.5923 361.8524 361.0335 367.4152 368.1771 369.5130 374.1977
#> 1958 377.6052 376.3330 371.2029 361.4526 371.8343 383.5362 387.0679 396.5770
#> 1959 397.4726 407.0105 415.3590 418.4369 424.0706 421.5136 430.2867 436.1496
#> 1960 457.3264 452.8993 442.8725 472.5261 479.7372 477.7933 477.9935 481.1243
#>           Sep      Oct      Nov      Dec
#> 1949 127.6503 128.6635 128.4876 129.6968
#> 1950 147.4894 144.6289 140.7914 152.3225
#> 1951 171.1440 176.4124 180.4229 180.5127
#> 1952 199.2426 207.0293 208.8580 215.1385
#> 1953 225.4261 226.5113 221.8871 223.1003
#> 1954 245.5116 245.0260 253.6693 255.4452
#> 1955 294.8441 294.1301 297.0567 308.8018
#> 1956 329.1515 334.5141 340.1138 339.5918
#> 1957 378.4526 377.6560 379.6653 379.2973
#> 1958 383.1635 389.1312 382.3159 386.9628
#> 1959 439.2162 436.7974 450.9071 465.6466
#> 1960 482.6658 489.4866 490.6654 491.8786
# }
```
