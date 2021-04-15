
wfclose(noerr) .\data_for_application1.wf1
wfopen .\data_for_application1.wf1

%ip_first = ip.@first
%ip_last = ip.@last


smpl {%ip_first} {%ip_last}
graph fg_ip.line ip
fg_ip.addtext(t)

smpl @all
freeze(sp_ip_arma) ip.autoarma(tform=log, diff=1, select=sic,agraph, atable, etable, eqname=eq_ip_arma) ip_f c
equation  eq_ip_arma.LS(ARMA=ML, ARMAOPT=KA) DLOG(IP) C MA(1) MA(2)

eq_ip_arma.speceval(noprompt)

smpl @all
equation eq_ip_arma2.LS(ARMA=ML, ARMAOPT=KA) DLOG(IP) C AR(1)

smpl @all
freeze(sp_ip_arma3) ip.autoarma(tform=log, diff=1, select=aic,agraph, atable, etable, eqname=eq_ip_arma3) ip_f c
equation eq_ip_arma3.LS(ARMA=ML, ARMAOPT=KA) DLOG(IP) C AR(1) AR(2) AR(3) AR(4) MA(1) MA(2) MA(3) MA(4)

eq_ip_arma.speceval(spec_list="eq_ip_arma*")

smpl @all
equation eq_ip_static.ls dlog(ip) c dlog(gdp)

eq_ip_static.speceval(spec_list="eq_ip_arma",use_names="t",graph_add_backtest="gdp[r]")

eq_ip_static.speceval(exec_list="normal stability")
eq_ip_static.speceval(spec_list="eq_ip_arma",use_names="t",graph_add_backtest="gdp[r]",keep_info="t",tfirst_test="2000q1")
eq_ip_static.speceval(spec_list="eq_ip_arma",use_names="t",graph_add_backtest="gdp[r]",keep_info="t",oos="f")

smpl @all
equation eq_ip_static2.ls dlog(ip) dlog(gdp)
eq_ip_static.speceval(spec_list="eq_ip_static*",horizons_forecast="1 2 4 8 16 40 80",horizons_graph="4 8 40",alias_list="with without")

smpl @all
equation eq_ip_static_dummy.ls dlog(ip) c dlog(gdp) dum_recess*dlog(gdp)

eq_ip_static.speceval(spec_list="eq_ip_static_dummy",horizons_forecast="1 2 4 8",subsamples="2008q3-2009q4,2011q3-2013q2",oos="t",alias="normal dummy")

smpl @all
equation eq_ip_static_exports.ls dlog(ip) c dlog(gdp) dum_recess*dlog(gdp) dlog(ex)

eq_ip_static.speceval(spec_list="eq_ip_static_dummy eq_ip_static_exports",horizons_forecast="1 2 4 8",subsamples="2008q3-2009q4,2011q3-2013q2",oos="f",alias_list="normal dummy exports",keep_forecasts="t")

eq_ip_static_exports.speceval(exec_list="normal decomposition",subsamples="2008q3-2009q4,2011q3-2013q2",oos="f")


eq_ip_static_dummy.speceval(scenarios="bl su sd")

eq_ip_static_dummy.speceval(exec_list="normal scenarios_individual",scenarios="bl su sd",tfirst_sgraph="2006q1", tlast_scenarios="2025q4",graph_add_scenarios="gdp[r]",trans="deviation")

smpl @all
equation eq_ip_static_dummy2.ls dlog(ip) c dlog(gdp) (@movav(dum_recess,4)>0)*dlog(gdp)

eq_ip_static_dummy.speceval(spec_list="eq_ip_static_dummy2",exec_list="normal scenarios_individual",oos="f",scenarios="bl su sd",tfirst_sgraph="2006q1", tlast_scenarios="2025q4",graph_add_scenarios="gdp[r]",trans="deviation",alias_list="short_dummy long_dummy")


