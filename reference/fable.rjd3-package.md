# fable.rjd3: 'fabletools' Interface to JDemetra+ v3 Seasonal Adjustment

Seasonal adjustment of `tsibble` series with X-13ARIMA
([`X13()`](https://aqlt.github.io/fable.rjd3/reference/X13.md)) and
TRAMO-SEATS
([`TRAMOSEATS()`](https://aqlt.github.io/fable.rjd3/reference/TRAMOSEATS.md)),
and their pre-adjustment models Reg-ARIMA
([`REGARIMA()`](https://aqlt.github.io/fable.rjd3/reference/REGARIMA.md))
and TRAMO
([`TRAMO()`](https://aqlt.github.io/fable.rjd3/reference/TRAMO.md)),
using the JDemetra+ v3 R packages rjd3x13 and rjd3tramoseats. JDemetra+
workspaces can be imported and exported with
[`import_jws()`](https://aqlt.github.io/fable.rjd3/reference/import_jws.md)
and
[`export_jws()`](https://aqlt.github.io/fable.rjd3/reference/export_jws.md).

## Details

Models store the underlying Java object, so any indicator available in
JDemetra+ can be extracted with
[`jd3_indicator()`](https://aqlt.github.io/fable.rjd3/reference/jd3_indicator.md)
and listed with
[`jd3_dictionary()`](https://aqlt.github.io/fable.rjd3/reference/jd3_dictionary.md).
The usual `fabletools` verbs work on the fitted mable:
[components()](https://aqlt.github.io/fable.rjd3/reference/jd3_model_methods.md),
[glance()](https://aqlt.github.io/fable.rjd3/reference/jd3_model_methods.md),
[tidy()](https://aqlt.github.io/fable.rjd3/reference/jd3_model_methods.md)
and
[report()](https://aqlt.github.io/fable.rjd3/reference/jd3_model_methods.md),
as well as
[forecast()](https://aqlt.github.io/fable.rjd3/reference/forecast.jd3_model.md),
[`backcast()`](https://aqlt.github.io/fable.rjd3/reference/backcast.md)
and
[outliers()](https://aqlt.github.io/fable.rjd3/reference/outliers.jd3_model.md).

## See also

Useful links:

- <https://aqlt.github.io/fable.rjd3/>

- <https://github.com/AQLT/fable.rjd3>

- Report bugs at <https://github.com/AQLT/fable.rjd3/issues>

## Author

**Maintainer**: Alain Quartier-la-Tente <alain.quartier@yahoo.fr>
([ORCID](https://orcid.org/0000-0001-7890-3857)) \[copyright holder\]

Authors:

- Alain Quartier-la-Tente <alain.quartier@yahoo.fr>
  ([ORCID](https://orcid.org/0000-0001-7890-3857)) \[copyright holder\]
