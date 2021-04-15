wfclose(noerr) .\data_for_application2.wf1
wfopen .\data_for_application2.wf1

%cpi_first = cpi.@first
%cpi_last = cpi.@last

smpl {%cpi_first} {%cpi_last}
graph fg_cpi_level.line cpi
fg_cpi_level.addtext(t,sb) Level
graph fg_cpi_growth.line @pca(cpi) @pcy(cpi)
fg_cpi_growth.addtext(t,sb) Growth
fg_cpi_growth.setelem(1) legend(Month-on-month) 
fg_cpi_growth.setelem(2) legend(Year-on-year) 
graph fg_cpi.merge fg_cpi_level fg_cpi_growth
fg_cpi.align(2,1,1)


smpl @all
series s_cpi_growth = @pca(cpi)
freeze(sp_cpi_arma) s_cpi_growth.autoarma(tform=none, diff=0, maxar=4,maxma=4,select=aic,agraph, atable, etable, eqname=eq_cpi_arma) s_cpi_growth_f c
equation  eq_cpi_arma.LS @pca(CPI) C AR(1 to 3) MA(1 to 4)

eq_cpi_arma.setattr("selection_info") maxar=4,maxma=4,info=aic

eq_cpi_arma.speceval(auto_select="t",exec_list="normal stability")
copy sp_spec_evaluation sp_spec_evaluation_stability

eq_cpi_arma.speceval(auto_select="t",trans="growth",tfirst_graph="2009Q1")


