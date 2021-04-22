# SpecEval
Eviews add-in that performs evaluation of (forecasting properties of) equation/VAR/identity object(s) and prepares report summarizing the results.

See Specification_evalauation.pdf for full documentation of the add-in.

Current development list - roughly in order of priority - is following:

•	Regressor response – random shock

•	Allow for skips in forecast summary graphs

•	Scenario graphs – allow for transformation (use @depends for group)

•	Fix reg output to properly identify rows in complex output tables like break and in VARs

•	Add zero line to coefficient stability where zero is crossed.

•	Automatic ARDL as benchmark option 

•	Forecast error scatter plots – level forecast period (not start) of series against error, or change in series  from start to forecast period against error.

•	Multiple specification subsample graphs

•	Allow for using dependent varaible rather than base variable

•	Scenario graphs – add check for trending of additional series

•	Mixed in-sample out-of-sample option

•	Restricted estimation sample for auto select option

•	Allow break in sample for backtesting graphs by allowing for multiple starts and ends

