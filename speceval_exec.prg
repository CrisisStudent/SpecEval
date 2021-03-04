include .\subroutines\speceval_subroutines.prg
include .\subroutines\include_list.prg

statusline Setting parameters
call settings_parameters

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ START OF LOOP TRHOUGH EQUATIONS $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

for !spec_id = 1 to sc_spec_count

	statusline Cleaning up objects
	call cleaning_up_objects(@word(st_specification_list,!spec_id))

	statusline Specification information  ({!spec_id})
	%intermediate_objects = ""
	call get_spec_info
	call get_spec_add_info


	' ##########################################
	' ##### 2.0 Creating recursive forecasts ###########
	' ##########################################
	
	if @instr(@upper(st_exec_list),"FORECASTS") then
		statusline Recursieve forecasts ({st_spec_name})
		call recursive_forecasts
	else	
		copy sc_*_{st_alias} sc_*
		copy st_*_{st_alias} st_*
		copy {st_base_var}_*_{st_alias} {st_base_var}_*

		if @upper(st_auto_type)="ARDL" then
			call auto_ardl_reg_series(st_spec_name)
		endif

		if @upper(st_auto_type)="ARMA" then
			call auto_arma_reg_series(st_spec_name)
		endif
	endif
	
	' ####################################################
	' ##### 3.0 Caluclating forecast perormance metrics ###########
	' ####################################################	
	
	if @instr(@upper(st_exec_list),"METRICS") then

		statusline Forecast performance metrics	({st_spec_name})	

		%master_mnemonic = st_base_var + "_f{fstart}"
		call performance_metrics(st_base_var,%master_mnemonic, sc_forecastp_n,st_tfirst_backtest,st_tfirst_backtest,st_subsamples,st_performance_metrics,st_forecast_dep_var,st_include_growth_rate,st_horizons_metrics)
	endif
	
	' ##################################################
	' ##### 4.0 Creating  forecast perormance graphs ###########
	' ##################################################
	
	if @instr(@upper(st_exec_list),"GRAPHS") then
		statusline Forecast performance graphs ({st_spec_name})
		call forecast_graph_sample
		call forecast_graphs(st_base_var, st_spec_name, sc_forecastp_n, st_tfirst_backtest,st_tlast_backtest, %graph_sample_string, st_forecast_dep_var)
	endif

	if @instr(@upper(st_exec_list),"GRAPHS_BIAS") then
		statusline Foreacst bias graphs ({st_spec_name})
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
	call evaluation_report

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
	call cleaning_up_objects(@word(st_specification_list,!spec_id))

	
next

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ END OF LOOP TRHOUGH EQUATIONS $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

' ########################################################
' ##### 7.0 Creating multiple-equation perfromance report ###########
' ########################################################

if sc_spec_count>1 then
	statusline Creating multiple-specification performance report
	call evaluation_multireport
endif

' ############################################
' ##### 8.0 Storign and displaying outputs ###########
' ############################################

sp_spec_evaluation.display

if (@upper(st_save_output)="F")=0 then
	call speceval_store
endif

' ############################################
' ##### 9.0 Cleaning up settings objects ###########
' ############################################

if @upper(st_keep_information)="F" then	
	delete(noerr) st_auto_type 
endif

if @upper(st_keep_settings)="F" then	
	delete(noerr) sc_horizons_bias_n st_horizons_bias sc_horizons_metrics_n st_horizons_metrics sc_horizons_graph_n st_horizons_graph _
	st_transformation st_outofsample sc_subsample_count st_subsamples st_performance_metrics _
	st_spec_alias_list st_specification_list sc_spec_count  st_base_var  st_alias st_spec_name _
	st_tfirst_backtest_user st_tlast_backtest_user st_tfirst_graph_user st_tlast_graph_user _ 
	st_subsample* st_subsample*_start st_subsample*_end sc_subsample*_start sc_subsample*_length _
	tb_forecast_decomposition _
	st_include_bias st_include_mae st_include_rmse st_percentage_error _
	st_auto_selection st_custom_reestimation st_forecast_dep_var st_include_growth_rate _
	st_scenarios st_scenario_dataload st_tfirst_scenarios st_tlast_scenarios st_tfirst_sgraph _
	st_graph_add_backtest st_graph_add_scenarios st_include_baseline st_include_original st_index_period st_graph_benchmark _
	st_eq_list_add sc_add_eq_count st_model_name_add st_forecasted_ivariables _ 
	st_keep_objects st_keep_equations st_keep_forecasts st_keep_settings st_keep_information st_use_names st_save_output st_include_descriptions _
	st_exec_list st_exec_list_user st_ignore_errors
endif

statusline Specification evaluation is done.


