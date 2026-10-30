# Specials available in the model formula

Specials are used on the right-hand side of the formula of
[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
[`REGARIMA()`](https://aqlt.github.io/fable.rjd3/reference/REGARIMA.md)
or [`TRAMO()`](https://aqlt.github.io/fable.rjd3/reference/TRAMO.md),
e.g. `X13(y ~ transform(fun = "Log") + xreg(strike))`. Each one records
a call to a function of rjd3toolkit that is applied to the base
specification (the `spec` argument).

## Specials

- `spec(x)`: base specification (name or specification object);
  equivalent to the `spec` argument of
  [`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
  [`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md),
  [`REGARIMA()`](https://aqlt.github.io/fable.rjd3/reference/REGARIMA.md)
  or [`TRAMO()`](https://aqlt.github.io/fable.rjd3/reference/TRAMO.md).

- `basic(...)`: arguments passed to
  [`rjd3toolkit::set_basic()`](https://rjdverse.github.io/rjd3toolkit/reference/set_basic.html).

- `transform(...)`: arguments passed to
  [`rjd3toolkit::set_transform()`](https://rjdverse.github.io/rjd3toolkit/reference/set_transform.html).

- `estimate(...)`: arguments passed to
  [`rjd3toolkit::set_estimate()`](https://rjdverse.github.io/rjd3toolkit/reference/set_estimate.html).

- `automodel(...)`: arguments passed to
  [`rjd3toolkit::set_automodel()`](https://rjdverse.github.io/rjd3toolkit/reference/set_automodel.html).

- `outlier(...)`: arguments passed to
  [`rjd3toolkit::set_outlier()`](https://rjdverse.github.io/rjd3toolkit/reference/set_outlier.html).

- `add_outlier(...)`: arguments passed to
  [`rjd3toolkit::add_outlier()`](https://rjdverse.github.io/rjd3toolkit/reference/add_outlier.html)
  (e.g. `type = "AO", date = "2020-04-01"`).

- `easter(...)`: arguments passed to
  [`rjd3toolkit::set_easter()`](https://rjdverse.github.io/rjd3toolkit/reference/set_easter.html).

- `tradingdays(...)`: arguments passed to
  [`rjd3toolkit::set_tradingdays()`](https://rjdverse.github.io/rjd3toolkit/reference/set_tradingdays.html).

- `arima(...)`: arguments passed to
  [`rjd3toolkit::set_arima()`](https://rjdverse.github.io/rjd3toolkit/reference/set_arima.html).

- `ramp(...)`: arguments passed to
  [`rjd3toolkit::add_ramp()`](https://rjdverse.github.io/rjd3toolkit/reference/add_outlier.html).

- `usrdefvar(...)`: arguments passed to
  [`rjd3toolkit::add_usrdefvar()`](https://rjdverse.github.io/rjd3toolkit/reference/add_usrdefvar.html).

- `x11(...)`: arguments passed to
  [`rjd3x13::set_x11()`](https://rjdverse.github.io/rjd3x13/reference/x11_spec.html)
  (X-11 decomposition parameters; use with
  [`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md) only).

- `seats(...)`: arguments passed to
  [`rjd3tramoseats::set_seats()`](https://rjdverse.github.io/rjd3tramoseats/reference/set_seats.html)
  (SEATS decomposition parameters; use with
  [`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md)
  only).

- `benchmarking(...)`: arguments passed to
  [`rjd3toolkit::set_benchmarking()`](https://rjdverse.github.io/rjd3toolkit/reference/set_benchmarking.html)
  (use with
  [`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md) or
  [`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md)
  only).

- `xreg(..., regeffect = NULL, group = "r", lag = 0, coef = NULL)`:
  user-defined regressors taken from columns of the tsibble and added to
  the context. By default (`regeffect = NULL`), the regressors are only
  added to the context (with the `group="r"`). If `regeffect` is equals
  to `"Undefined"`, `"Trend"`, `"Seasonal"`, `"Irregular"`, `"Series"`
  or `"SeasonallyAdjusted"` then variable is also added to the
  specification using the
  [`rjd3toolkit::add_usrdefvar()`](https://rjdverse.github.io/rjd3toolkit/reference/add_usrdefvar.html)
  function with the parameters `lag` and `coeff`. If
  `regeffect = "Calendar"`, then the variable is added to the
  specification using the
  [`rjd3toolkit::set_tradingdays()`](https://rjdverse.github.io/rjd3toolkit/reference/set_tradingdays.html)
  function.

## Precedence

The base `spec` is applied first, then the specials in a fixed order
(basic, transform, estimate, automodel, outlier, add_outlier, easter,
tradingdays, arima, ramp, usrdefvar, benchmarking, x11, seats), then
`xreg()`. Later settings override earlier ones. A special that does not
apply to the method (e.g.
[`x11()`](https://rdrr.io/r/grDevices/x11.html) in
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md))
is ignored with a warning.

## See also

[`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md),
[`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md)
