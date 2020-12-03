' ##########################
' ##### 1.0 Settings ###########
' ##########################

' Check if exist in current location or include from default location

%add_in_path = @linepath 

mode quiet

'--- Set the log mode ---'		
!debug = 1 'set to 1 if you want the logmsgs to display
if !debug = 0 then
	logmode +addin
else
	logmode logmsg
endif

call speceval_user_settings

call include_list

%object_type=_this.@type

%exec_file_name = "speceval_exec.prg"

%exec_file_path  = %add_in_path  + %exec_file_name

exec %exec_file_path

' ##################################################################################################################
' ##################################################################################################################
' ##################################################################################################################

subroutine speceval_user_settings

statusline User settings

' 1. Detemine if  this was run from the GUI
!dogui=1
if @len(@option(1))>0 then
	!dogui=@hasoption("prompt") 'if this is 0, we are NOT running through the GUI
endif


'2. Execute user dialog
if !dogui=1 then
	
	' 2.1 Basic settings

	' Defaults
	string st_exec_list_user = "medium"
	!forecast_type = 1
	string st_forecast_horizons = "1 2 4 8 12"
	string st_specification_list = _this.@name
	string st_scenarios = "" 
	string st_ignore_errors = "f"	
	
	!date_settings = 0
	!advanced_options = 0
	!store_settings = 0
		
	'Basic settings dialog
	!result = @uidialog("caption","Settings for forecast performance", _
		"edit",st_exec_list_user,"Enter list of procedure components you wish to include in execution",100, _
		"edit",st_specification_list,"Enter list of specifications", 200, _ 
		"radio",!forecast_type,"Type of forecasts","Out-of-sample In-sample", _
		"edit",st_forecast_horizons,"Enter the list of horizons", _
		"edit",st_scenarios,"Enter list of scenarios", _ 
		"check",!date_settings,"Change date settings", _
		"check",!advanced_options,"Change andvanced options", _
		"check",!store_settings,"Change store settings")
	
	' Stopping if user exited
	if !result = -1 then 'will stop the program unless OK is selected in GUI
		stop
	endif
	
	' Implementation of basic settings
	if !forecast_type = 1 then
		string st_outofsample = "t"			
	else
		string st_outofsample = "f"					
	endif
	
	' 2.2 Date settings

	'Setting defaults
	string st_tfirst_backtest_user = ""
	string st_tlast_backtest_user = ""
	string st_tfirst_graph_user = ""
	string st_tlast_graph_user = ""
	string st_SubSamples = ""
	string st_tfirst_scenarios = ""
	string st_tlast_scenarios = ""
	string st_tfirst_sgraph = ""

	if !date_settings = 1 then

		!result = @uidialog("caption","Date settings", _
		"edit",st_tfirst_backtest_user,"Enter starting date of backtesting", 10, _
		"edit",st_tlast_backtest_user,"Enter ending date of backtesting", 10, _
		"edit",st_tfirst_graph_user,"Enter starting date of backcasting graphs", 10, _
		"edit",st_tlast_graph_user,"Enter ending date of backcasting graphs", 10, _
		"edit",st_tfirst_scenarios,"Enter starting date of scenarios", 10, _
		"edit",st_tlast_scenarios,"Enter ending date of scenarios", 10, _
		"edit",st_tfirst_sgraph,"Enter starting date of scenario graphs", 10, _
		"edit",st_SubSamples,"Enter list of forecast sub-samples", 100)		
		
	endif

	
	' 2.3 Advanced settings

	' Defaults

	if st_forecast_horizons<>"1 2 4 8 12" then
		string st_graph_horizons = st_forecast_horizons
		string st_bias_horizons = st_forecast_horizons
	else
		string st_graph_horizons = "4 12" 
		string st_bias_horizons = "4"
	endif

	!include_rmse = 1 
	!include_mae = 0
	!include_bias = 0 		
	!percentage_error = 1
	!transformation = 1
	!include_growth_rate = 0		
	!forecast_dep_var = 1
	string st_graph_add_backtest = ""
	string st_graph_add_scenarios = ""
	!include_original = 1 
	!include_baseline = 1 
	!auto_selection = 0
	!custom_reestimation = 0
	string st_add_scenarios = ""
	string st_eq_list_add = ""
	string st_model_name_add = ""
	string st_forecasted_ivariables = ""
	!scenario_dataload = 1


	if !advanced_options = 1 then

		' Dialog
		!result = @uidialog("caption","Advanced options", _
		"text","PERFORMANCE METRIC OPTIONS", _ 
		"edit",st_graph_horizons,"Enter the list of graph horizons", _
		"edit",st_bias_horizons,"Enter the list of bias graph horizons", _
		"text","Which performance metric you want to include?", _
		"check",!include_rmse,"RMSE", _
		"check",!include_mae,"MAE", _
		"check",!include_bias,"BIAS", _
		"radio",!percentage_error,"Do you want to use percentage errors?","Auto Yes No", _
		"text","=========================", _
		"text","", _
		"text","PERFORMANCE GRAPH OPTIONS", _	
		"radio",!transformation,"Which transformation you want to use?","Level ""Growth rate"" ""Spread from benchmark"" Index ""Deviation from baseline""", _
		"radio",!forecast_dep_var,"Variable to be forecasted","""Underlying variable"" ""Dependent variable of equation""", _
		"edit",st_graph_add_backtest,"Enter the list of series to include in backtest graphs",100, _
		"edit",st_graph_add_scenarios,"Enter the list of series to include in scenario graphs",100, _
		"check",!include_original,"Include original forecast in scenario graphs", _
		"check",!include_baseline,"Include baseline forecast in scenario graphs", _
		"text","=========================", _
		"text","", _
		"text","FORECAST OPTIONS", _
		"check",!auto_selection,"Should automatic model selection be performed?", _
		"check",!custom_reestimation,"Should custom reestimation be used?", _
		"edit",st_eq_list_add,"Enter list of additional equations/identities for RHS variables", _
		"edit",st_model_name_add,"Enter name of model object which contains equations/identitie for RHS variables", _
		"edit",st_forecasted_ivariables,"Enter list of independent variables fowr which forecasts should be used ", _ 
		"check",!scenario_dataload,"Load missing scenario data from databases")

		'"check",!include_growth_rate,"Do you want to include growth rate results?", _

		' Stopping if user exited
		if !result = -1 then 'will stop the program unless OK is selected in GUI
			stop
		endif	
	endif	
			
	' Implementation of advanced settings
	string st_performance_metrics = "" 
	
	for %metric rmse mae bias
		if !include_{%metric} = 1 then
			st_performance_metrics = st_performance_metrics + %metric + " "
		endif
	next		
	
	string st_percentage_error = @word("AUTO T F",!percentage_error)
			
	string st_transformation = @word("none growth spread index deviation",!transformation)

	if @upper(st_transformation)="Deviation" then
		@uiedit(st_index_period,"Enter index period date")
	endif
	
	'if !include_growth_rate = 1 then
		string st_include_growth_rate = "f"
	'endif
	
	if !forecast_dep_var = 1 then
		string st_forecast_dep_var = "f"			
	else
		string st_forecast_dep_var = "t"					
	endif

	for %setting include_original include_baseline auto_selection custom_reestimation scenario_dataload
		if !{%setting} = 1 then
			string st_{%setting} = "T"
		else
			string st_{%setting} = "F"
		endif
	next
	
	' 2.4 Store settings

	' Defaults
	string  st_spec_alias_list  = ""
	!use_names = 0
	!include_descriptions = 0
	!keep_objects = 0
	!keep_forecasts = 0
	!keep_equations = 0
	!keep_information = 0
	!keep_settings = 0
	!save_output = 5

	if !store_settings = 1 then
		
		' Dialog
		!result = @uidialog("caption","Store settings", _
		"edit", st_spec_alias_list,"Enter list of specification aliases", 50, _
		"check",!use_names,"Do you want to use equation names instead of aliases in output?", _
		"check",!keep_objects,"Do you want to keep intermediate objects?", _
		"check",!keep_forecasts,"Do you want to keep intermediate objects?", _
		"check",!keep_equations,"Do you want to keep reestiamted  equations?", _
		"check",!keep_information,"Do you want to keep information objects?", _
		"check",!keep_settings,"Do you want to keep setting objects?", _
		"radio",!save_output,"Save output","Yes ""Yes - with ttiles"" ""Yes - with descriptions"" ""User dialog"" No")

		if !result = -1 then 'will stop the program unless OK is selected in GUI
			stop
		endif	
	endif	
		
	' Implementation of store settings
	for %store_object keep_objects keep_forecasts keep_equations keep_information keep_settings use_names include_descriptions
		if !{%store_object} = 1 then
			stirng st_{%store_object} = "t"
		else
			string st_{%store_object} = "f"
		endif				
	next

	string st_save_output = @word("t t d user f",!save_output)
endif

' 3. Extract execution options
'AAA
if !dogui=0 then

	' Main options
	string st_forecast_horizons = @equaloption("HORIZONS_FORECAST")
	string st_graph_horizons = @equaloption("HORIZONS_GRAPH")
	string st_bias_horizons = @equaloption("HORIZONS_BIAS")
	string st_outofsample = @equaloption("OOS")

	string st_base_var = @equaloption("")	
	string st_specification_list = @equaloption("SPEC_LIST")
	string st_spec_alias_list = @equaloption("ALIAS")	
	

	string st_eq_list_add = @equaloption("EQ_LIST_ADD")	
	string st_model_name_add = @equaloption("MODEL_NAME_ADD")	
	string st_forecasted_ivariables = @equaloption("FORECASTED_IVARIABLES")
	
	string st_scenarios = @equaloption("SCENARIOS")

	string st_exec_list_user = @equaloption("EXEC_LIST")
	string st_ignore_errors = @equaloption("IGNORE_ERRORS")
							
	' Date options	
	string st_tfirst_backtest_user = @equaloption("TFIRST_TEST")
	string  st_tlast_backtest_user = @equaloption("TLAST_TEST")
	string  st_tfirst_graph_user = @equaloption("TFIRST_GRAPH")
	string  st_tlast_graph_user = @equaloption("TLAST_GRAPH")
	string  st_tfirst_scenarios = @equaloption("TFIRST_SCENARIOS")
	string  st_tlast_scenarios = @equaloption("TLAST_SCENARIOS")
	string st_tfirst_sgraph = @equaloption("TFIRST_SGRAPH")
	
	string st_SubSamples = @equaloption("SubSamples") 

	'Advanced metrics and graphs options
	string st_performance_metrics = @equaloption("METRICS") 

	if @isempty(st_performance_metrics)=0 then
		
		if @instr(" " + @upper(st_performance_metrics) + " "," RMSE ")>0 then
			string st_include_rmse = "t"		
		else
			string st_include_rmse = "f"		
		endif

		if @instr(" " + @upper(st_performance_metrics) + " "," MAE ") then
			string st_include_mae = "t"
		else
			string st_include_mae = "f"		
		endif
		
		if @instr(" " + @upper(st_performance_metrics) + " "," BIAS ") then
			string st_include_bias = "t"		
		else
			string st_include_bias = "f"		
		endif
	endif
	
	string st_percentage_error = @equaloption("PERC")
	
	string st_include_growth_rate = @equaloption("GROWTH")
			
	string st_transformation = @equaloption("TRANS")	
	
	string st_spread_benchmark = @equaloption("SPREAD_BENCH")
	
	string st_index_period = @equaloption("INDEX_PERIOD")
	
	string st_forecast_dep_var = @equaloption("DEP_VAR")
	
	string st_graph_add_backtest = @equaloption("GRAPH_ADD_BACKTEST")
	string st_graph_add_scenarios = @equaloption("GRAPH_ADD_SCENARIOS")
	string st_include_original = @equaloption("ORIGINAL_FORECAST")	
	string st_include_baseline = @equaloption("BASELINE_FORECAST")	
	string st_add_scenarios = @equaloption("ADD_SCENARIOS")		
	
	' Advanced forecast options	
	
	string st_auto_selection = @equaloption("auto_select")	
	string st_custom_reestimation = @equaloption("CUSTOM_REEST")
	string st_scenario_dataload = @equaloption("SCENARIO_DATALOAD")
	
	' Store options
	string st_keep_objects = @equaloption("KEEP_OBJECTS")	
	string st_keep_forecasts = @equaloption("KEEP_FORECASTS")	
 	string st_keep_equations =  @equaloption("KEEP_EQS")		
 	string st_keep_settings =  @equaloption("KEEP_SETTINGS")		
 	string st_keep_information =  @equaloption("KEEP_INFO")
 	
 	string st_use_names = @equaloption("USE_NAMES")		

	string st_save_output = @equaloption("SAVE")

	' Initializing with defaults if option has not been specified

	if @isempty(st_outofsample) then
		string st_outofsample = "t"	
	endif
		
	if @isempty(st_transformation) then
		string st_transformation = "none"  
	endif
	
	if @isempty(st_forecast_dep_var) then
		st_forecast_dep_var = "f"
	endif
	
	if @isempty(st_include_growth_rate) then
		st_include_growth_rate = "f"
	endif
	
	if @isempty(st_keep_objects) then
		st_keep_objects = "f"
	endif
	
	if @isempty(st_keep_forecasts) then
		st_keep_forecasts = "t"
	endif
	
	if @isempty(st_keep_equations) then
		st_keep_equations = "f"
	endif
	
	if @isempty(st_keep_settings) then
		st_keep_settings = "f"
	endif
	
	if @isempty(st_keep_information) then
		st_keep_information = "t"
	endif	
	
	if @isempty(st_use_names) then
		st_use_names = "f"
	endif	

	if @isempty(st_save_output) then
		st_save_output = "f"
	endif

	if @upper(st_save_output)="D" then
		string st_include_descriptions = "t"
	else
		string st_include_descriptions = "t"
	endif
	
	if @isempty(st_auto_selection) then
		st_auto_selection = "f"
	endif		
	
	if @isempty(st_custom_reestimation) then
		st_custom_reestimation = "f"
	endif		

	if @isempty(st_scenario_dataload) then
		st_scenario_dataload = "t"
	endif		
	
endif

endsub

' ##################################################################################################################




' ##################################################################################################################

subroutine include_list

delete(noerr) tx_include_list
text tx_include_list

%subroutines = @linepath + "speceval_subroutines.prg"
tx_include_list.append include %subroutines

%include_list_path = %add_in_path + "include_list.prg"

if @upper(st_custom_reestimation)="T" then
	%custom_reest_file_path = @runpath + "\custom_reestimation.prg"

	if @fileexist(%custom_reest_file_path)=0 then 
		%custom_reest_file_path = @linepath + "reestimation_custom.prg"
	endif 

	tx_include_list.append include {%custom_reest_file_path}
endif

if @wcount(st_scenarios)>0  and @upper(st_scenario_dataload)="T" then
	%dataload_file_path = @runpath + "\scenario_dataload.prg"

	if @fileexist(%dataload_file_path)=0 then 
		%dataload_file_path = @linepath  + "scenario_dataload.prg"
	endif 

	tx_include_list.append include {%dataload_file_path}
endif

tx_include_list.save %include_list_path
delete(noerr) tx_include_list

endsub

' ##################################################################################################################


