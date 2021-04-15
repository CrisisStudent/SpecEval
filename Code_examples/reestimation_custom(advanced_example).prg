subroutine cfp_reestimation_custom(string %sub_tfirst_reestimation,string %sub_tlast_reestimation)
		
' 0. Specification info

if @isobject("st_function") then
	%function = st_function 
else
	%function = "nonlinear" 'linear nonlinear
endif

if @isobject("st_method") then
	%method = st_method 
else
	%method = "ols" 'ols tsls fmols ccr dols_sic dols_aic ardl_aic ardl_sic
endif

!er_lag = -1

!positive_coefficient_check = 1
!break_test = 1

%exogenous_variables = ""

if %function="linear" then
	%equation_normal = "iir_normal-mrr c"
	%equation_excess = "iir_excess c dr log(er(" + @str(!er_lag) + "))"
	
	!coef_excess = 3
endif

if %function="nonlinear" then
	%equation_normal = "iir_normal-mrr c"
	%equation_excess = "log(iir_excess-dr) c log(er(" + @str(!er_lag) + "))"	
	
	!coef_excess = 2
endif


%est_command = "ls(cov=hac)"
'%est_command = "cointreg(method=fmols,trend=const,lag=a,infosel=sic) "

if %method = "fmols" then
	%est_command = "cointreg(method=fmols,trend=const,lag=a,infosel=sic) "
	!coef_excess = !coef_excess-1
endif

if %method = "ccr" then
	%est_command = "cointreg(method=ccr,trend=const,lag=a,infosel=sic)  "
	!coef_excess = !coef_excess-1
endif

if %method = "dols_sic" then
	%est_command = "cointreg(method=dols,trend=const,lltype=sic,maxll=4,cov=hac) "
endif

if %method = "dols_aic" then
	%est_command = "cointreg(method=dols,trend=const,lltype=aic,maxll=4,cov=hac) "
endif

if %method = "ardl_sic" then
	%est_command = "ardl(ic=bic,deplags=4, reglags=4,cov=hac) "
	%equation_excess = @replace(@upper(%equation_excess)," C "," ")
endif

if %method = "ardl_aic" then
	%est_command = "ardl(ic=aic,deplags=4, reglags=4,cov=hac) "
	%equation_excess = @replace(@upper(%equation_excess)," C "," ")
endif

		
' 1. Defining considered thresholds
	
smpl {%sub_tfirst_reestimation} {%sub_tlast_reestimation} 
!max_threshold = 100
!min_threshold = 1.01
	
smpl @all if er>=!min_threshold and er<=!max_threshold 

scalar sc_threshold_n = @obssmpl

stom(er,v_thresholds_unsorted)	
vector v_thresholds= @sort(v_thresholds_unsorted,"a")

' 2. Creating table to hold results 
table tb_results
tb_results(1,1) = "Forecast period"
tb_results(1,2) = "Two regimes"
tb_results(1,3) = "Threshold value"

table tb_threshold_results
tb_threshold_results(1,1) = "Threshold"
tb_threshold_results(1,2) = "Threshold value"
tb_threshold_results(1,3) = "RSS"
tb_threshold_results(1,4) = "Two regimes"

'tb_threshold_results.setformat(@all) f.3
tb_threshold_results.setformat(A) f.0

' 3. Estimating all-threshold specifications

for !t=1 to  sc_threshold_n 
	
	' Creating threshold dummy 
	scalar sc_threshold = v_thresholds(!t)
	
	smpl @all
	series dum_er= 0
	dum_er = (er(!er_lag)>sc_threshold)
	
	smpl {%sub_tfirst_reestimation} {%sub_tlast_reestimation} if dum_er =1	
	
	!er_regime_obs_n = @obssmpl
	
	if !er_regime_obs_n >6 then
		!two_regimes = 1
	else
		!two_regimes = 0
	endif
	
	if !two_regimes=1 then
		
		' Creating two regime series
		copy iir iir_normal
		copy iir iir_excess
		
		' Estimating two regime equations
		smpl {%sub_tfirst_reestimation} {%sub_tlast_reestimation} if dum_er =0		
		equation eq_iir_normal.ls(cov=hac) {%equation_normal} {%exogenous_variables}
		
		smpl {%sub_tfirst_reestimation} {%sub_tlast_reestimation} if dum_er =1	
		equation eq_iir_excess.{%est_command} {%equation_excess} {%exogenous_variables}
		
		' Checking for presence of positive coefficient
		if !positive_coefficient_check = 1 then
			!er_coef = eq_iir_excess.@coef(!coef_excess)
			
			!positive_coefficient_detected = 0
			
			if !er_coef>0 then
				!positive_coefficient_detected = 1
				!two_regimes= 0
			endif		
		endif	
		
		'Creating model for forecasting
		model m_fp 
		
		m_fp.merge eq_iir_normal
		m_fp.merge eq_iir_excess
	
		m_fp.append @identity iir = @recode(dum_er=0,iir_normal,iir_excess)
		
		' Forecasting 
		smpl {%sub_tfirst_reestimation} {%sub_tlast_reestimation} 
		m_fp.solve
		
		rename iir_0 iir_fit
		
		' Calculating model fit
		call normalized_r2("0",0,%sub_tfirst_reestimation + " " + %sub_tlast_reestimation)
			
		' Formal break test
		if !two_regimes = 1 and !break_test = 1 then
				
			%equation_string = @replace(@upper(%equation_normal),"_NORMAL","")
				
			smpl {%sub_tfirst_reestimation} {%sub_tlast_reestimation}
			equation eq_iir_nobreak.ls(cov=hac) {%equation_string} {%exogenous_variables}
			
			scalar sc_t = eq_iir_nobreak.@regobs
			scalar sc_rss_nobreak = eq_iir_nobreak.@ssr
			
			scalar sc_fstat = ((sc_rss_nobreak-sc_rss)/3)/(sc_rss/(sc_t-2*3))
			
			scalar sc_pval = @cfdist(sc_fstat,3,sc_t+2*3)
			
			if sc_pval<0.95 then
				!two_regimes = 0
				delete(noerr) m_fp		
			endif				
		endif			
	endif
					
	if  !two_regimes=0 then
		'Estimating simple regime equation
		%equation_string = @replace(@upper(%equation_normal),"_NORMAL","")
		
		smpl {%sub_tfirst_reestimation} {%sub_tlast_reestimation}
		equation eq_iir.ls(cov=hac) {%equation_string} {%exogenous_variables}
		
		scalar sc_rss = eq_iir.@ssr
		
		model m_fp
		m_fp.merge eq_iir
	endif
		
	'Storing results
	tb_threshold_results(!t+1,1) = @str(!t,"f.0")
	tb_threshold_results(!t+1,2) = sc_threshold
	tb_threshold_results(!t+1,3) = sc_rss	
	
	if !two_regimes=1 then
		tb_threshold_results(!t+1,4) = "Y"
	else
		tb_threshold_results(!t+1,4) = "N"
	endif
	
	'Storing objects and cleaning up
	if !two_regimes=1 then
		copy eq_iir_normal eq_iir_normal_t{!t}
		copy eq_iir_excess eq_iir_excess_t{!t}
	else
		copy eq_iir eq_iir_t{!t}
	endif	
	
	copy dum_er dum_er_t{!t}
	'copy iir_fit iir_{!t}
	rename m_fp m_fp_t{!t}
	rename sc_threshold sc_threshold_t{!t}
	
	delete(noerr) iir_fit iir_excess_0 iir_normal_0 iir_0 iir_normal iir_excess
	
next

!last_row = tb_threshold_results.@rows
tb_threshold_results.sort(A2:D{!last_row}) C


' 4. Storing best specification and cleaning up
!best_specification = @val(tb_threshold_results(2,1))

if @upper(tb_threshold_results(2,4))="Y" then
	!two_regimes = 1
else
	!two_regimes = 0
endif

if !two_regimes=1 then
	copy eq_iir_normal_t{!best_specification} eq_iir_normal
	copy eq_iir_excess_t{!best_specification} eq_iir_excess
else
	copy eq_iir_t{!best_specification} eq_iir
endif

copy m_fp_t{!best_specification} m_fp
copy(o) dum_er_t{!best_specification} dum_er
copy(o) sc_threshold_t{!best_specification} sc_threshold

tb_results(1+!fp,1) = %fstart
if !two_regimes=1 then
	tb_results(1+!fp,2) = "Y"
else
	tb_results(1+!fp,2) = "N"
endif
tb_results(1+!fp,3) = tb_threshold_results(2,2)

if @upper(st_keep_equations)="T" then
	copy m_fp m_fp_{%fstart}	
	copy dum_er dum_er_{%fstart}
	copy sc_threshold sc_threshold_{%fstart}
		
	if  !two_regimes=1 then
		copy eq_iir_normal_t{!best_specification} eq_iir_normal_{%fstart}
		copy eq_iir_excess_t{!best_specification} eq_iir_excess_{%fstart}
	else
		copy eq_iir_t{!best_specification} eq_iir_{%fstart}
	endif
endif

if @upper(st_keep_objects)="T" then
	copy tb_threshold_results tb_threshold_results_{%fstart}
endif

delete(noerr) m_fp_t* dum_er_t* sc_threshold_t* eq_iir_*t*


endsub


subroutine normalized_r2(string %anchor, scalar !row, string %sub_sample)

'TSS
smpl {%sub_sample} 
series S_DepVar = iir-{%anchor}

series s_temp = (S_DepVar-@mean(S_DepVar))^2

scalar sc_tss = @sum(s_temp)

'RSS
smpl {%sub_sample} 
series s_resids = (iir_fit-{%anchor})-S_DepVar

series s_temp= s_resids^2

scalar sc_rss= @sum(s_temp)

scalar sc_r2 = 1-sc_rss/sc_tss

endsub


