include .\subroutines\include_list.prg

statusline Setting parameters
call settings_parameters

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ START OF LOOP TRHOUGH EQUATIONS $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

for !spec_id = 1 to sc_spec_count
	
	%intermediate_objects = ""
	call get_spec_info
	call get_spec_add_info
	
	' ##########################################
	' ##### 2.0 Creating recursive forecasts ###########
	' ##########################################
	
	statusline Recursieve forecasts ({st_spec_name})
	call recursive_forecasts
	
	' ####################################################
	' ##### 3.0 Caluclating forecast perormance metrics ###########
	' ####################################################	
	
	if @instr(@upper(st_exec_list),"METRICS") then

		statusline Forecast performance metrics	({%sub_spec_name})	

		%master_mnemonic = st_base_var + "_f{fstart}"
		call performance_metrics(st_base_var,%master_mnemonic, sc_forecastp_n,st_tfirst_backtest,st_tfirst_backtest,st_subsamples,st_performance_metrics,st_forecast_dep_var,st_include_growth_rate,st_forecast_horizons)
	endif
	
	' ##################################################
	' ##### 4.0 Creating  forecast perormance graphs ###########
	' ##################################################
	
	if @instr(@upper(st_exec_list),"GRAPHS") then
		statusline Foreacst perforamnce graphs ({st_spec_name})
		call forecast_graphs(st_base_var, st_spec_name, sc_forecastp_n, st_tfirst_backtest,st_tlast_backtest)
	endif

	if @instr(@upper(st_exec_list),"GRAPHS_BIAS") then
		call forecast_bias_graphs("s_history_series",st_base_var + "_f{fstart}")
	endif
	
	' ######################################
	' #### 5.0 Conditional scenario forecasts #####
	' ######################################
	
	if @instr(@upper(st_exec_list),"SCENARIOS") then
		statusline Conditional scenario forecasts	
		call conditional_scenario_forecast
	endif
		
	' ##########################################
	' ##### 5.0 Creating perfromance report ###########
	' ##########################################
	
	statusline Creating performance reports ({st_spec_name})
	call performance_report
	
	' ############################################
	' ##### 6.0 Storing results and cleaning up ###########
	' ############################################
	
	' Storing results 
	if sc_spec_count>1 or @isempty(st_alias)=0 then
		statusline Storing results with alias ({st_spec_name})
		call results_aliasing(st_alias)
	endif
	
	'Cleaning up
	statusline Cleaning up ({st_spec_name})
	call cleaning_up_objects

	
next

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ END OF LOOP TRHOUGH EQUATIONS $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

' ########################################################
' ##### 7.0 Creating multiple-equation perfromance report ###########
' ########################################################

if sc_spec_count>1 then
	statusline Creating multiple-specification performance report
	call performance_report_multi
endif

' ############################################
' ##### 8.0 Storign and displaying outputs ###########
' ############################################

sp_spec_evaluation.display

if (@upper(st_save_output)="F")=0 then
	call speceval_store
endif

statusline Specification evaluation is done.


' ############################################
' ##### 9.0 Cleaning up settings objects ###########
' ############################################

if @upper(st_keep_settings)="F" then	
	delete(noerr) sc_bias_horizons_n st_bias_horizons sc_forecast_horizons_n st_forecast_horizons sc_graph_horizons_n st_graph_horizons _
	st_transformation st_outofsample sc_subsample_count st_subsamples st_performance_metrics _
	st_spec_alias_list st_specification_list sc_spec_count  st_base_var  st_alias st_spec_name _
	st_tfirst_backtest_user st_tlast_backtest_user st_tfirst_graph_user st_tlast_graph_user _ 
	st_subsample{!SubSample} st_subsample{!SubSample}_start st_subsample{!SubSample}_end _
	st_include_bias st_include_mae st_include_rmse _
	st_auto_selection st_custom_reestimation st_forecast_dep_var st_include_growth_rate _
	st_scenarios st_scenario_dataload st_tfirst_scenarios st_tlast_scenarios st_tfirst_sgraph _
	st_graph_add_backtest st_graph_add_scenarios st_include_baseline st_include_original st_index_period st_spread_benchmark st_add_scenarios _
	st_eq_list_add sc_add_eq_count st_model_name_add st_forecasted_ivariables _ 
	st_keep_objects st_keep_equations st_keep_forecasts st_keep_settings st_keep_information st_use_names _
	st_exec_list st_exec_list_user st_ignore_errors
endif


