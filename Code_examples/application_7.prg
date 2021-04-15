wfclose(noerr) .\data_for_application7.wf1
wfopen .\data_for_application7.wf1

pageselect monthly

smpl @all
equation eq_eonia.ls eonia c mrr dr ar(1) ma(1)

eq_eonia.speceval(custom_reest="t",trans="spread",graph_bench="mrr",tfirst_test="2005M01")

eq_eonia.speceval(custom_reest="f",trans="spread",graph_bench="mrr",tfirst_test="2005M01")


