wfclose(noerr) .\data_for_application5.wf1
wfopen .\data_for_application5.wf1

pageselect monthly

string id_mrr_rw = "mrr = mrr(-1)"

id_mrr_rw.speceval(nodialog)

id_mrr_rw.speceval(nodialog,keep_forecasts="t")

smpl @all
equation eq_eonia_arma.ls eonia c mrr ar(1)

eq_eonia_arma.speceval(FORECASTED_IVARIABLES="mrr",trans="spread",graph_bench="mrr")


