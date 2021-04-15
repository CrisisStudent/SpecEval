wfclose(noerr) .\data_for_application8.wf1
wfopen .\data_for_application8.wf1

pageselect monthly

smpl @all
equation eq_eonia.ls eonia c dr ar(1)

eq_eonia.setattr("selection_info") maxar=4,maxma=4,info=SIC
eq_eonia.speceval(auto_select="t",tfirst_test="2005m01",exec_list="forecasts stability",keep_eqs="t",keep_info="t")

%sub_horizons = "6 12 24"
!max_horizon = @val(@word(%sub_horizons,@wcount(%sub_horizons)))

matrix(sc_forecastp_n,@wcount(%sub_horizons)) m_irf 

%fqs = ""

for !fp = 1  to sc_forecastp_n		

	%fq = tb_forecast_numbers(1+!fp,2) 

	eq_eonia_reest{%fq}.arma(type=imp,imp=1,hrz={!max_horizon},save=v_irf_{!fp})
	close eq_eonia_reest{%fq}

	for !h = 1 to @wcount(%sub_horizons)	
		%h = @word(%sub_horizons,!h)		
		m_irf(!fp,!h) = v_irf_{!fp}({%h})	
	next

	%fqs  = %fqs +%fq+ " "
next

			
smpl {st_tfirst_backtest} {st_tlast_backtest}
freeze(gp_irf) m_irf.line
gp_irf.setobslabels {%fqs}

for !h = 1 to @wcount(%sub_horizons)	
	%h = @word(%sub_horizons,!h)	
	gp_irf.setelem(!h) legend({%h}-th period impulse response)	
next


