wfclose(noerr) .\data_for_application3.wf1
wfopen .\data_for_application3.wf1

pageselect monthly

%eonia_first = eonia.@first
%eonia_last = eonia.@last

smpl {%eonia_first} {%eonia_last}
graph fg_eonia_level.line eonia mrr
fg_eonia_level.addtext(t,sb) Level
graph fg_eonia_spread.line eonia-mrr
fg_eonia_spread.addtext(t,sb) Spread
graph fg_eonia.merge fg_eonia_level fg_eonia_spread
fg_eonia.align(2,1,1)

smpl @all
equation eq_eonia_static.ls eonia c mrr

eq_eonia_static.speceval(nodialog,exec_list="short")
eq_eonia_static.speceval(nodialog,trans="spread",graph_bench="mrr")

smpl @all
equation eq_eonia_arma.ls eonia c mrr ar(1)

eq_eonia_arma.speceval(nodialog) 
eq_eonia_arma.speceval(trans="spread",graph_bench="mrr")

eq_eonia_static.speceval(trans="spread",graph_bench="mrr",graph_add_backtest="mrr-dr[R]")
eq_eonia_static.speceval(trans="spread",graph_bench="mrr",graph_add_backtest="log(er)[R]")

smpl @all
equation eq_eonia_structural.ls eonia-(mrr*(1-dum_er)) c dr*dum_er log(er)*dum_er

eq_eonia_structural.speceval(trans="spread",graph_bench="mrr")
eq_eonia_structural.speceval(trans="spread",graph_bench="mrr",oos="f")


%euribor_first = euribor.@first
%euribor_last = euribor.@last

smpl {%euribor_first} {%euribor_last}
graph fg_euribor_level.line euribor eonia mrr
fg_euribor_level.addtext(t,sb) Level
graph fg_euribor_spread.line euribor-mrr euribor-eonia eonia-mrr 
fg_euribor_spread.addtext(t,sb) Spread
graph fg_euribor.merge fg_euribor_level fg_euribor_spread
fg_euribor.align(2,1,1)

smpl @all
equation eq_euribor_static.ls euribor c eonia

eq_euribor_static.speceval(trans="spread",graph_bench="eonia")

smpl {%euribor_first} {%euribor_last}
graph fg_spreads.line euribor-eonia libor-ffr


smpl @all
equation eq_spread_level.ls euribor-eonia c libor-ffr
equation eq_spread_diff.ls d(euribor-eonia) d(libor-ffr)

 eq_spread_level.speceval(trans="spread",graph_bench="eonia")
 eq_spread_diff.speceval(trans="spread",graph_bench="eonia")

 eq_spread_level.speceval(trans="spread",graph_bench="eonia",subsamples="2008M09-2009M09,2011M10-2012M06")
 eq_spread_diff.speceval(trans="spread",graph_bench="eonia",subsamples="2008M09-2009M09,2011M10-2012M06")

pageselect quarterly

smpl @all
equation eq_spread_ecm.ls  d(euribor-eonia) = c(1)*(euribor(-1)-eonia(-1)-c(2)) + c(3)*d(libor-ffr)

eq_spread_ecm.speceval(trans="spread",graph_bench="eonia",scenarios="bl s0 s4")


series libor_spread_bl = libor_bl-ffr_bl
series libor_spread_s4 = libor_s4-ffr_s4

eq_spread_ecm.speceval(exec_list="short scenarios_individual",trans="spread",graph_bench="eonia",scenarios="bl s0 s4",graph_add_scenarios="libor_spread",include_baseline="t",include_original="f")


