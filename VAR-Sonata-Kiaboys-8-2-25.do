clear

//make sure to set the working directory

cd "PATH TO YOUR WORKING DIRECTORY HERE"

import delimited "data/weekly_sonata_logistic-10-4-24.csv"

tsset seq

//unit root analyses; if p < 0.05 then time series are stationary

dfuller theft if seq>230, regress //with constant, no trend, no drift, no lags
pperron theft if seq>230, regress

dfuller kia_boys if seq>230, regress
pperron kia_boys if seq>230, regress

dfuller kia_boys_la if seq>230, regress
pperron kia_boys_la if seq>230, regress



//VAR model for sonata thefts vs. kiaboys_us

var theft kia_boys if seq>230, lags(1/3) //lags(1/2) includes lags at 1 and 2 (units of time =) weeks
//var sonata kiaboys_us if seq>230, lags(1/3) //lags(1/2) includes lags at 1 and 2 (units of time =) weeks

varsoc //helps decide how many lags to use in the model

varstable //the modulus lies inside the unit circle and therfore the VAR satisfies stability condition.

varlmar //null hyp is no autocorrelation at the selected lag, with p > 0.05 there is no autocorrelation at the selected lags

vargranger //whether sonata predicts kiaboys_us @ 0.05 level and kiaboys_us predicts sonata @ the 0.05 level


//VAR model for sonata thefts vs. kiaboys_la

var theft kia_boys_la if seq>230, lags(1/3) //lags(1/3) includes lags at 1, 2 and 3 (units of time =) weeks

varsoc //helps decide how many lags to use in the model, here 3 lags suggested by AIC etc. criteria

varstable //the modulus lies inside the unit circle and therfore the VAR satisfies stability condition.

varlmar //null hyp is no autocorrelation at the selected lag, with p > 0.05 there is no autocorrelation at the selected lags

vargranger //whether sonata predicts kiaboys_us @ 0.05 level and kiaboys_us predicts sonata @ the 0.05 level

