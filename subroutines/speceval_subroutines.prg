' List of subroutines
'	1) subroutine settings_parameters
'		- subroutine base_var_ident
'		- subroutine SubSamples_info_objects(string %subsamples)

'	2) subroutine get_spec_info

'	3) subroutine get_spec_add_info

'	4) subroutine recursive_forecasts
'		- subroutine sample_boundaries(string %sub_eq_name, string %sub_preserve_boundaries)

'	5) subroutine performance_metrics(string %sub_EqVar,  string %sub_master_mnemonic, scalar !sub_forecastp_n, string %sub_tfirst, string %sub_tlast, string %subsamples, string %sub_forecast_dep_var, string %sub_include_growth_rate)

'	6) subroutine forecast_graphs(string %sub_EqVar, string %sub_eq_name,  scalar !sub_forecastp_n, string %sub_tfirst, string %sub_tlast)
' 		- subroutine forecast_graphs_summary(string %sub_history_series,string %sub_master_mnemonic, scalar !sub_horizon,string %sub_tfirst, string %sub_tlast, string %sub_transformation, string %sub_graph_sample, string %sub_spread_benchmark, string %sub_index_period, string %sub_graph_add, string %sub_forecasted_ivariables)

'	7) subroutine forecast_bias_graphs(string %sub_history_series,string %sub_master_mnemonic)

'	8) subroutine conditional_scenario_forecast

'	9) subroutine evaluation_report

'	10) subroutine results_aliasing(st_alias)

'	11) subroutine cleaning_up_objects

'	12) subroutine evaluation_multireport

'	13) subroutine speceval_store




' ##################################################################################################################

subroutine settings_parameters

' 1. Execution settings

' Component lists
%graphs_component_list = "GRAPHS_SUMMARY GRAPHS_SS GRAPHS_BIAS"
%scenarios_component_list = "SCENARIOS_INDIVIDUAL SCENARIOS_ALL SCENARIOS_LEVEL SCENARIOS_TRANS"

%full_component_list = " FORECASTS METRICS GRAPHS SCENARIOS DECOMPOSITION REG_OUTPUT STABILITY "

%multiple_components_list = "ALL SHORT MEDIUM LONG"

' Default 
string st_exec_list = ""

if @isempty(st_exec_list_user) then
	st_exec_list = "medium"
endif 

' Creating final component and remove lists

if @isempty(st_exec_list_user)=0 then
	for %c {st_exec_list_user}
		if @left(%c,1)<>"-" then
			if @instr(" "+ @upper(%full_component_list) + " "," " +@upper(%c) + " ")>0 or @instr(" " + @upper(%multiple_components_list)+ " "," " +@upper(%c) + " ")>0 then   
				st_exec_list = st_exec_list + %c + " "
			endif
		else
			%c = @mid(%c,2)
		
			if @instr(@upper(%full_component_list)," " +@upper(%c) + " ")>0 or @instr(@upper(%multiple_components_list)," " +@upper(%c) + " ")>0 then   
				%remove_list = %remove_list + %c + " "
			endif
		endif
	next
endif

' Dealing with length options
if @instr(" " + @upper(st_exec_list) + " "," SHORT ") then
	st_exec_list = @replace(@upper(st_exec_list),"SHORT","FORECASTS METRICS GRAPHS_SUMMARY REG_OUTPUT")

	if @isempty(st_forecast_horizons) then
		string st_forecast_horizons = "8 24"
		!forecast_horizons_user = 0 
	endif
endif

if @instr(" " + @upper(st_exec_list) + " "," MEDIUM ") then
	st_exec_list = @replace(@upper(st_exec_list),"MEDIUM","FORECASTS METRICS GRAPHS_SUMMARY GRAPHS_SS SCENARIOS_ALL REG_OUTPUT")

'	if @isempty(st_forecast_horizons) then
'		string st_forecast_horizons = "8 24"
'		!forecast_horizons_user = 0 
'	endif
endif

if @instr(" " + @upper(st_exec_list) + " "," LONG ") then
	st_exec_list = @replace(@upper(st_exec_list),"LONG","ALL")

	if @isempty(st_forecast_horizons) then
		string st_forecast_horizons = "2 4 8 16 24"
		!forecast_horizons_user = 0 
	endif

	if @isempty(st_performance_metrics) then
		st_performance_metrics = "rmse mae bias"
	endif

endif

'Dealing with all option
if @instr(" " + @upper(st_exec_list) + " "," ALL ") then
	st_exec_list = @replace(@upper(st_exec_list),"ALL",%full_component_list)
endif

' First removal of components
if @wcount(%remove_list)>0 then
	for %c {%remove_list}
		if @instr(" " + @upper(st_exec_list) + " "," "+ @upper(%c) + " ") then	
			st_exec_list = @replace(" " + @upper(st_exec_list) + " "," "+ @upper(%c) + " "," ")
		endif
	next
endif

' Replacing aggregate options
if @instr(" " + @upper(st_exec_list)," GRAPHS ") then
	st_exec_list = @replace(@upper(st_exec_list)," GRAPHS "," " + %graphs_component_list + " ")
endif

if @instr(" " + @upper(st_exec_list)," SCENARIOS ") then
	st_exec_list = @replace(@upper(st_exec_list)," SCENARIOS "," " + %scenarios_component_list + " ")
endif

if @instr(" " + @upper(st_exec_list)," SCENARIOS_INDIVIDUAL ") or @instr(" " + @upper(st_exec_list)," SCENARIOS_ALL ") then
	st_exec_list = @replace(@upper(st_exec_list),"SCENARIOS_ALL","SCENARIOS_ALL SCENARIOS_LEVEL SCENARIOS_TRANS")
	st_exec_list = @replace(@upper(st_exec_list),"SCENARIOS_INDIVIDUAL","SCENARIOS_INDIVIDUAL SCENARIOS_LEVEL SCENARIOS_TRANS")
endif

if @instr(" " + @upper(%remove_list) + " "," GRAPHS ") then
	%remove_list = @replace(" " + @upper(%remove_list) + " "," GRAPHS "," " + %graphs_component_list + " ")
endif

if @instr(" " + @upper(%remove_list) + " "," SCENARIOS ") then
	%remove_list = @replace(" " + @upper(%remove_list)+ " "," SCENARIOS "," " + %scenarios_component_list + " ")
endif

' Removing duplicates
st_exec_list = @wunique(st_exec_list)

' Second removal of components
if @wcount(%remove_list)>0 then
	for %c {%remove_list}
		if @instr(" " + @upper(st_exec_list) + " "," "+ @upper(%c) + " ") then	
			st_exec_list = @replace(" " + @upper(st_exec_list) + " "," "+ @upper(%c) + " "," ")
		endif
	next
endif

' 2. Equation information

' Processing equation lists
if @instr(@upper(st_specification_list),"*")>0 then
	%patterns = @wdelim(st_specification_list,","," ")			
	
	st_specification_list = ""
	
	for %pattern {%patterns}
		if @instr(@upper(%pattern),"*")>0 then		
			string st_specification_list =   st_specification_list + " " + @wlookup(%pattern,"equation")			
		else
			string st_specification_list =   st_specification_list + " " + %pattern
		endif
	next				
endif

if @instr(@upper(st_specification_list),",")>0 then
	st_specification_list = @wdelim(st_specification_list,","," ")			
endif

if @isempty(st_specification_list) then
	
	st_specification_list = _this.@name
else
	st_specification_list = _this.@name + " " + st_specification_list
endif

st_specification_list = @wunique(@upper(st_specification_list))
scalar sc_spec_count = @wcount(st_specification_list)

if sc_spec_count>1 then
	
	table tb_equation_list
	tb_equation_list(1,1) = "Equation alias"
	tb_equation_list(1,2) = "Equation name"	
	
endif

'Procesing alias in name setting
if @upper(st_spec_alias_list)="NAME" and @wcount(%patterns)>0 then
	
	%spec_name_masters = ""
	
	for %pattern {%patterns}
		if @instr(@upper(%pattern),"*")>0 then		 
			%spec_name_masters = %spec_name_masters + @replace(%pattern,"*","") + " "
		endif		
	next	
	
	%spec_name_masters = @stripquotes(%spec_name_masters)
	st_spec_alias_list = ""
	
	for !spec_id = 1 to sc_spec_count
		%spec = @word(st_specification_list,!spec_id)
		
		!alias_identified = 0	
		for !m = 1 to @wcount(%spec_name_masters) 
			%spec_name_master = @word(%spec_name_masters,!m)
		
			if @instr(@upper(%spec),@upper(%spec_name_master))>0 then
				
				%alias = @replace(@upper(%spec),@upper(%spec_name_master),"")
				!alias_identified = 1
				
				if @isempty(%alias) then
					st_spec_alias_list = st_spec_alias_list + "No_alias" + " "
				else
					st_spec_alias_list = st_spec_alias_list + %alias + " "
				endif
			endif
		next
		
		if !alias_identified = 0 then
			st_spec_alias_list = st_spec_alias_list + %spec + " "			
		endif
	next
endif

' Dealing with mutliple auto select arguments
if @instr(st_auto_selection,",")>0 then
	st_auto_selection = @wdelim(st_auto_selection,","," ")
endif
	
if @wcount(st_auto_selection)>1  then	
		
	if @wcount(st_auto_selection)=sc_spec_count then
		copy st_auto_selection st_auto_selection_all
	else
		st_auto_selection = @word(st_auto_selection,1) 
		@uiprompt("WARNING: The number of auto select paratmeters does not correspond to number of equations. Auto select was set to "+ st_auto_selection + ".")
	endif		
endif

' 3. Specifying forecast performance parameters

' Metrics
if @isempty(st_performance_metrics) then
	string st_performance_metrics = "rmse"	
endif	

for %metric rmse mae bias
	if @instr(@upper(st_performance_metrics),@upper(%metric))>0 then
		string st_include_{%metric} = "t"
	else
		string st_include_{%metric} = "f"
	endif
next


' Horizons 
!forecast_horizons_user = 1
if @isempty(st_forecast_horizons) then
	string st_forecast_horizons = "8 24"
	!forecast_horizons_user = 0 
endif

if @isempty(st_graph_horizons) then
	if !forecast_horizons_user = 0 then
		string st_graph_horizons = "8 24"	
	else
		string st_graph_horizons = st_forecast_horizons
	endif	
endif

if @isempty(st_bias_horizons) then
	string st_bias_horizons = "8 24"
endif

st_forecast_horizons = @replace(st_forecast_horizons,", "," ")
st_forecast_horizons = @replace(st_forecast_horizons,",","")
st_graph_horizons = @replace(st_graph_horizons,", "," ")
st_graph_horizons = @replace(st_graph_horizons,",","")
st_bias_horizons = @replace(st_bias_horizons,", "," ")
st_bias_horizons = @replace(st_bias_horizons,",","")

scalar sc_forecast_horizons_n = @wcount(st_forecast_horizons)
scalar sc_graph_horizons_n = @wcount(st_graph_horizons)
scalar sc_bias_horizons_n = @wcount(st_bias_horizons)

' 4. Perceentage error default
if @isempty(st_percentage_error) or @upper(st_percentage_error)="AUTO" then
	
	if @isempty(st_base_var) then
		string st_spec_name = _this.@name
		call  base_var_ident(st_spec_name)
	endif
	!trend_default = 0

	series s_depvar= @d({st_base_var})
	!variance_depvar = @stdev(s_depvar)
	
	if !variance_depvar>0 then

		smpl @all
		'equation et_{st_base_var}.ls {st_base_var} c @trend
		'equation et_{st_base_var}.ls {st_base_var}-@elem({st_base_var},%sub_qfirst) {st_base_var}(-1)-@elem({st_base_var},%sub_qfirst) @trend
		equation et_{st_base_var}.ls @d({st_base_var}) c
		
		if !trend_default = 1 then		
			if et_{st_base_var}.@pval(1)>0.15 then
	'		if et_{st_base_var}.@pval(2)<0.05 and et_{st_base_var}.@r2>0.5 then
				st_percentage_error = "f"
			else
				st_percentage_error = "t"
			endif
		else
			if et_{st_base_var}.@pval(1)<0.05 and et_{st_base_var}.@coef(1)>0 then
	'		if et_{st_base_var}.@pval(2)<0.05 and et_{st_base_var}.@r2>0.5 then
				st_percentage_error = "t"
			else
				st_percentage_error = "f"
			endif
		endif

		%intermediate_objects = %intermediate_objects + "et_" + st_base_var +  " "

	endif
	
	delete(noerr) s_depvar

	if @upper(st_keep_information)="F" then
		delete(noerr) et_{st_base_var}
	endif

endif

' 5. Additional graph settings
if @isobject("st_spread_benchmark")=0 then
	string st_spread_benchmark = "" 
endif

if @isempty(st_spread_benchmark) and @upper(st_transformation)="SPREAD" then
	@uiedit(st_spread_benchmark,"Enter name of series you wish to use as spread benchmark")
endif

if @isobject("st_index_period")=0 then
	string st_index_period = "" 
endif

' 6. Sub-sample program variables
if @wcount(st_subsamples)>0 then
	call SubSamples_info_objects(st_SubSamples)
else
	scalar sc_subsample_count = 0
	st_exec_list = @replace(@upper(st_exec_list),"GRAPHS_SS","")
endif

' 7. Specifying conditional shock scenarios settings
if @isempty(st_scenarios) then
	for %c scenarios {%scenarios_component_list}
		st_exec_list = @replace(" " + @upper(st_exec_list) + " "," "+ @upper(%c) + " "," ")	
	next
else

	if @instr(st_scenarios,",")>0 then
		st_scenarios = @wdelim(st_scenarios,","," ")
	endif

	' NOT IMPLEMENTED - User can change this by including [B] after alias of scenario which should be used as base scenario
	'	if instr(st_scenarios,",")>0 then
	'		%base_scenario 
	'	endif

	if @isempty(st_tlast_scenarios) then
		st_tlast_scenarios = "@last"
	endif
	
	if @isempty(st_tfirst_sgraph) then
		st_tfirst_sgraph = "2005" 
	endif
	
	%baseline_alias = @word(st_scenarios,1)

endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine base_var_ident(string %sub_spec_name)

if _this.@type = "EQUATION" then
	{%sub_spec_name}.makeregs gr_regs
	string st_base_var = @word(gr_regs.@depends,1) 'dependent variable without transformations
	string st_depvar = @word({%sub_spec_name}.@spec,1)
endif

if _this.@type = "VAR" then
	{%sub_spec_name}.makeendog gr_regs
	string st_base_var = @word(gr_regs.@depends,1) 
endif

if _this.@type = "STRING" then
	%spec = {%sub_spec_name}
	%regs = @replace(%spec,"=","")
	group gr_regs {%regs}
	string st_base_var = @word(gr_regs.@depends,1)
	string st_depvar = @left(%spec,@instr(%spec,"=")-1)
endif

%intermediate_objects = %intermediate_objects + "st_depvar" + " "

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine SubSamples_info_objects(string %subsamples)

%SubSamples = @stripquotes(@wdelim(%SubSamples,","," "))

scalar sc_subsample_count = @wcount(%SubSamples)

for !SubSample = 1 to sc_subsample_count

	string st_subsample{!SubSample} = @word(%SubSamples,!SubSample) 	
	string st_subsample{!SubSample} = @wdelim(st_subsample{!SubSample},"-"," ")

	string st_subsample{!SubSample}_start = @word(st_subsample{!SubSample},1)
	string st_subsample{!SubSample}_end = @word(st_subsample{!SubSample},2)
	scalar sc_SubSample{!SubSample}_length = @dtoo(st_subsample{!SubSample}_end)-@dtoo(st_subsample{!SubSample}_start)+1
	scalar sc_SubSample{!SubSample}_start = -999
			
next

endsub

' ##################################################################################################################




' ##################################################################################################################

subroutine get_spec_info
	
' Equation name
string st_spec_name = @word(st_specification_list,!spec_id)

' Equation alias
if sc_spec_count>1 then
	
	call spec_alias
	
	tb_equation_list(1+!spec_id,1) = st_alias
	tb_equation_list(1+!spec_id,2) = st_spec_name
else
	string st_alias = st_spec_alias_list					
endif

' Underlying dependent variable
if {st_spec_name}.@type="EQUATION" or {st_spec_name}.@type="STRING" then
	call  base_var_ident(st_spec_name)
endif

' Auto select in case multiple arguments were specifed
if @isobject("st_auto_selection_all") then
	if @wcount(st_auto_selection_all)=sc_spec_count then
		string st_auto_selection = @word(st_auto_selection_all,!spec_id)
	endif
endif

' Auto type
string st_auto_type = ""

if @upper(st_auto_selection)="T" then
	
	%command = {st_spec_name}.@command	

	if @left(@upper(%command),4) = "ARDL" then
		string st_auto_type = "ARDL"
	endif
	
	if @instr(@upper(" "+ %command)," AR(")>0 or @instr(@upper(" "+ %command)," MA(")>0 or @instr(@upper(" "+ %command),"ARMA=")>0 then
		string st_auto_type = "ARMA"	
	endif

	if {st_spec_name}.@type="VAR" then
		string st_auto_type = "VAR"
	endif
	
	if @isempty(st_auto_type) then
		st_auto_selection = "f"
		
		if sc_spec_count>1 and @isobject("st_auto_selection_all")=0 then
			%restore_auto_selection = "t"
		endif
	endif
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine spec_alias

if @wcount(st_spec_alias_list) = @wcount(st_specification_list) then
	string st_alias = @word(st_spec_alias_list,!spec_id)
else
	string st_alias = @str(!spec_id)	
endif	

endsub

' ##################################################################################################################




' ##################################################################################################################

subroutine get_spec_add_info
	
' Multple-equation

if @isempty(st_eq_list_add) then
	scalar sc_add_eq_count = 0
else
	
	string st_eq_list_add_final = ""
	
	for !add_eq = 1 to @wcount(st_eq_list_add)
		
		%add_eq = @word(st_eq_list_add,!add_eq)
		
		' In-sample/Out-of-sample indicators
		string st_add_eq_oos = ""
		
		if @instr(@upper(%add_eq),"[OOS]") then
			string st_add_eq_oos = "t"	
			%add_eq = @replace(@upper(%add_eq),"[OOS]","")
		endif
			
		if @instr(@upper(%add_eq),"[IS]") then
			string st_add_eq_oos = "f"
			%add_eq = @replace(@upper(%add_eq),"[IS]","")
		endif
		
		if @isempty(st_add_eq_oos) then
			if @upper(st_outofsample)="T" then
				 st_add_eq_oos = "t"
			else
				 st_add_eq_oos = "f"
			endif
		endif		
		
		'Auto selection indicator
		string st_add_eq_auto = "f"
		
		if @instr(@upper(%add_eq),"[AUTO]") then
			string st_add_eq_auto = "t"	
			%add_eq = @replace(@upper(%add_eq),"[AUTO]","")
		endif
				
		' Equation/identity name
		string st_add_eq_name = %add_eq
			
		if @instr(@upper(st_add_eq_name),"[ALIAS]")>0 then	
			st_add_eq_name = @replace(@upper(st_add_eq_name),"[ALIAS]",st_alias) 
		endif
		
		' Checking existence of object 
		%object_exists = "f"
		if @isobject(st_add_eq_name)  then
			if  {st_add_eq_name}.@type="EQUATION" or {st_add_eq_name}.@type="STRING" then
				%object_exists = "t"
			endif
		endif
				
		' In case object does not exist checking if no-alias object exists
		%no_alias_name =st_add_eq_name
		if @upper(%object_exists)="F" and @instr(@upper(%add_eq),"[ALIAS]")>0 then
			
			%no_alias_name = @replace(@upper(st_add_eq_name),@upper(st_alias),"")
			if  @isobject(%no_alias_name) then
				if  {%no_alias_name}.@type="EQUATION" or {%no_alias_name}.@type="STRING" then
					st_add_eq_name = %no_alias_name
					%object_exists = "t"
				endif
			endif			
		endif		
		
		if @upper(%object_exists)="T" then
			if {st_add_eq_name}.@type="EQUATION" then
				string st_add_eq_type = "equation"
			else
				string st_add_eq_type = "identity"			
			endif			
		endif
				
		' In case object does not exist check if if exists in model objects specified by user
		if @upper(%object_exists)="F" and @isempty(st_model_name_add)=0 and @isobject(st_model_name_add) then
			%model_spec = {st_model_name_add}.@spec(%no_alias_name)	
						
			if @isempty(%model_spec)=0 then
				if @left(%model_spec,1)=":" then
					st_add_eq_name = @mid(%model_spec,2)
					
					if @isobject(st_add_eq_name) then
						string st_add_eq_type = "equation"
						%object_exists = "t"
					endif
				else			
					string id_{st_add_eq_name} = %model_spec
					st_add_eq_name = "id_" + st_add_eq_name
					
					string st_add_eq_type = "identity"			
					%object_exists = "t"
				endif
			endif	
		endif				
											
		' Storing		
		
		if @upper(st_add_eq_type)="IDENTITY" then
			st_add_eq_oos = "f"
		endif
		
		if @upper(%object_exists)="T" then
			st_eq_list_add_final = st_eq_list_add_final + " "  + st_add_eq_name	
			
			rename  st_add_eq_oos  st_add_eq_oos{!add_eq}
			rename  st_add_eq_auto st_add_eq_auto{!add_eq}
			rename  st_add_eq_name st_add_eq_name{!add_eq}
			rename  st_add_eq_type st_add_eq_type{!add_eq}
		else
			@uiprompt("No equation/identity found for additional equation " + %add_eq)		
		endif
	next
	
	scalar sc_add_eq_count = @wcount(st_eq_list_add_final)
	
endif

endsub

' ##################################################################################################################



	
' ##################################################################################################################

subroutine recursive_forecasts

' 1. Sample boundaries

' Main equation
call sample_boundaries(st_spec_name,"f")

if @upper(st_auto_selection)="F" and {st_spec_name}.@type<>"STRING" then
	call estimation_boundaries(st_spec_name,"")	
endif

call sample_boundaries_adjust(st_spec_name,st_outofsample,st_auto_selection,"","f")

' Additional equations
for !add_eq = 1 to sc_add_eq_count
	
	if @upper(st_add_eq_type{!add_eq})="EQUATION" then
		
		call sample_boundaries(st_add_eq_name{!add_eq},"t")
	
		if @upper(st_add_eq_oos{!add_eq})="T" then			
			
			if @upper(st_auto_selection)="F" then
				call estimation_boundaries(st_add_eq_name{!add_eq},"add" + @str(!add_eq))	
			endif
						
			call sample_boundaries_adjust(st_add_eq_name{!add_eq},st_outofsample,st_add_eq_auto{!add_eq},"add" + @str(!add_eq),"t")
	
		endif
	endif
next

' Calculating forecast period number
!forecastp_n = @dtoo(st_tlast_backtest)-@dtoo(st_tfirst_backtest)+1
scalar sc_forecastp_n = !forecastp_n

' 2. Creating table to hold forecast 
call create_forecast_number_tb

' 3. Creating forecasting model
if @upper(st_custom_reestimation)="F" then
	call create_forecast_model(st_spec_name,"m_speceval",st_forecast_dep_var)
	%intermediate_objects = %intermediate_objects +  "m_speceval" + " "
endif

for !fp = 1 to !forecastp_n

	%fstart = @otod(@dtoo(st_tfirst_backtest)+!fp-1)	

	' 4. Re-estimation on pre-forecast sample
	if @upper(st_outofsample) = "T" and {st_spec_name}.@type<>"STRING" then
		call reestimation(st_spec_name,st_auto_selection)		
	endif

	for !add_eq = 1 to sc_add_eq_count
		if @upper(st_add_eq_type{!add_eq})="EQUATION" and @upper(st_add_eq_oos{!add_eq})="T" then
			call reestimation(st_add_eq_name{!add_eq},st_add_eq_auto{!add_eq})		
		endif
	next 
	
	' 5. Forecasting
	call creating_forecasts("m_speceval",%fstart,st_tlast_backtest,st_base_var,st_forecast_dep_var)	

	call subsample_ident

next

' 6. Restoring original model
if @upper(st_outofsample) = "T" and @upper(st_custom_reestimation)="F" and {st_spec_name}.@type<>"STRING" then
	m_speceval.replacelink {st_spec_name}_reest {st_spec_name}
endif

' 7. Creating history series
smpl @all
series s_history_series = {%history_series}

' 8. Cleaning up

delete(noerr) {st_spec_name}_reest

%all_fvars = m_speceval.@endoglist
for  %fvar {%all_fvars}
	delete(noerr) {%fvar}_f
next

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine sample_boundaries(string %sub_eq_name, string %sub_preserve_boundaries)

if {%sub_eq_name}.@type<>"STRING" then

	' 1. Creating regressor group 
	call regressor_group(%sub_eq_name)
	
	' 2. Identifying smaple boundaries
	call sb_identification("tb_sb_" + %sub_eq_name,"gr_"+ %sub_eq_name+ "_regs" )

else
	call sb_identification_identity(%sub_eq_name)
endif

' 3. Storing sample boundaries
call sb_create_strings

' 4. Clearning up
delete(noerr) s_reg

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine regressor_group(string %sub_eq_name)

'Equatiion
if {%sub_eq_name}.@type="EQUATION" then
	if @upper(st_auto_selection)="F" then
		
		if @isobject("gr_"+ %sub_eq_name + "_regs")=0 then
			{%sub_eq_name}.makeregs gr_{%sub_eq_name}_regs
		endif
	
	else
		%command = {%sub_eq_name}.@command
		if @left(@upper(%command),4) = "ARDL" then
			%regressors = @mid(%command,@instr(%command,") ")+1)
			%regressors = @replace(%regressors," @","")
			group gr_{%sub_eq_name}_regs {%regressors}
		else
			if @isobject("gr_"+ %sub_eq_name + "_regs")=0 then
				{%sub_eq_name}.makeregs gr_{%sub_eq_name}_regs
			endif
		endif	
	endif
endif

' VAR
if {%sub_eq_name}.@type="VAR" then
	if @isobject("gr_"+ %sub_eq_name + "_regs")=0 then
		{%sub_eq_name}.makeendog gr_{%sub_eq_name}_regs
	
		%endog_vars = gr_{%sub_eq_name}_regs.@members
	
		%command = {%sub_eq_name}.@command
		%exog_vars = @mid(%command,@instr(%command," @ ")+2)
		%exog_vars = @replace(" "+ %exog_vars + " "," C ","")
	
		gr_{%sub_eq_name}_regs.add {%exog_vars}
	endif
endif

' Number of regressors
!reg_n = gr_{%sub_eq_name}_regs.@count

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine sb_identification(string %sub_tb_name,string %sub_group_name)

table {%sub_tb_name}
{%sub_tb_name}(1,1) = "Regressor"
{%sub_tb_name}(1,2) = "Sample start"
{%sub_tb_name}(1,3) = "Sample end"

!tfirst = 1
!tlast = @obsrange

for !r = 1 to !reg_n

	smpl @all
	series s_reg = {%sub_group_name}(!r)

	smpl @all
	!tfirst_reg = @dtoo(s_reg.@first)
	!tlast_reg = @dtoo(s_reg.@last)

	{%sub_tb_name}(1+!r,1) = {%sub_group_name}.@seriesname(!r)
	{%sub_tb_name}(1+!r,2) = s_reg.@first
	{%sub_tb_name}(1+!r,3) = s_reg.@last

	if !tfirst<!tfirst_reg then
		!tfirst=!tfirst_reg
	endif

	if !tlast>!tlast_reg then
		!tlast=!tlast_reg
	endif
next

!last_row = {%sub_tb_name}.@rows
{%sub_tb_name}.sort(A2:C{!last_row}) c

smpl @all
%tfirst = @otod(!tfirst) 
%tlast = @otod(!tlast) 

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine sb_identification_identity(string %sub_identity_name)

%lhs_string = @left({%sub_identity_name},@instr({%sub_identity_name},"=")-1)
%rhs_string = @right({%sub_identity_name},@length({%sub_identity_name})-@instr({%sub_identity_name},"="))

smpl @all
series s_lhs = {%lhs_string}
series s_rhs = {%rhs_string}

%tfirst_lhs = s_lhs.@first
%tlast_lhs = s_lhs.@last

%tfirst_rhs = s_rhs.@first
%tlast_rhs = s_rhs.@last

if @dtoo(%tfirst_lhs)<@dtoo(%tfirst_rhs) then
	%tfirst = %tfirst_rhs
else
	%tfirst = %tfirst_lhs
endif 

if @dtoo(%tlast_lhs)>@dtoo(%tlast_rhs) then
	%tlast = %tlast_rhs
else
	%tlast = %tlast_lhs
endif 	

%intermediate_objects = %intermediate_objects + "s_lhs s_rhs" + " "

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine sb_create_strings

if @upper(%sub_preserve_boundaries)="F" or @isobject("st_tfirst_backtest")=0  then
	string st_tfirst_backtest = %tfirst 
	string st_tlast_backtest = %tlast 
else
	if @dtoo(%tfirst)>@dtoo(st_tfirst_backtest) then
		string st_tfirst_backtest = %tfirst 
	endif
	
	if @dtoo(%tlast)<@dtoo(st_tlast_backtest) then
		string st_tlast_backtest = %tlast 
	endif	
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine estimation_boundaries(string %sub_eq_name, string %sub_object_alias)

freeze(tb_estimates) {%sub_eq_name}.results

for !r = 1 to tb_estimates.@rows

	!found = 0
	for !c = 1 to  tb_estimates.@cols
		if @instr(@upper(tb_estimates(!r,!c)),"SAMPLE") then

			!sample_row = !r
			!sample_col = !c
			
			!found = 1

			exitloop
			
		endif
	next
	
	if !found=1 then
		exitloop
	endif
next

%estimation_sample = tb_estimates(!sample_row,!sample_col)
%estimation_sample = @mid(%estimation_sample,@instr(%estimation_sample,":")+1)

smpl @all
%tfirst_estimation = @word(%estimation_sample,1)
%tlast_estimation = @word(%estimation_sample,2)

string st_estimation_sample{%sub_object_alias} = %estimation_sample
string st_tfirst_estimation{%sub_object_alias} = %tfirst_estimation
string st_tlast_estimation{%sub_object_alias} = %tlast_estimation

delete(noerr) tb_estimates

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine sample_boundaries_adjust(string %sub_eq_name, string %sub_outofsample,  string %sub_auto_selection, string %sub_object_alias, string %sub_preserve_boundaries)

' 1. Shifting backtest start for out-of-sample forecasting 

' Determning backtest start shift due to reestimation

if @upper(%sub_outofsample) = "T" then 
	call backtest_start_shift(%sub_eq_name, %sub_outofsample,  %sub_auto_selection, %sub_object_alias)
	%tfirst = @otod(@dtoo(st_tfirst_backtest)+ sc_backtest_start_shift)
endif

' 2. Adjusting backtest start based on user input
if @isempty(st_tfirst_backtest_user)=0 then
	if  @dtoo(st_tfirst_backtest_user)>@dtoo(%tfirst) then
		%tfirst = st_tfirst_backtest_user
	endif
endif

' 3. Adjusting backtest start based on estimation start
if @upper(%sub_outofsample) = "T" then 
	if @isempty(%tfirst_estimation)=0 and  @upper(st_auto_selection)="F" then
		if  @dtoo(%tfirst_estimation)+sc_backtest_start_shift>=@dtoo(%tfirst) then
			if @upper(%sub_outofsample) = "T" then 
				%tfirst = @otod(@dtoo(%tfirst_estimation)+ sc_backtest_start_shift)
			else
				%tfirst = %tfirst_estimation
			endif
		endif
	endif
endif

' 4. Adjusting backtest end based on user input
if @isempty(st_tlast_backtest_user)=0 then
	if @dtoo(st_tlast_backtest_user)<@dtoo(st_tlast_backtest) then
		%tlast = st_tlast_backtest_user
	endif
endif

' 5. Storing final values
if @upper(%sub_preserve_boundaries)="F" or @isobject("st_tfirst_backtest")=0  then
	string st_tfirst_backtest = %tfirst 
	string st_tlast_backtest = %tlast 
else
	if @dtoo(%tfirst)>@dtoo(st_tfirst_backtest) then
		string st_tfirst_backtest = %tfirst 
	endif
	
	if @dtoo(%tlast)<@dtoo(st_tlast_backtest) then
		string st_tlast_backtest = %tlast 
	endif	
endif

' 6. Adjusting subsmaple boundaries
if sc_subsample_count>0 then
	for !SubSample = 1 to sc_subsample_count

		!ss_adjusted= 0
		if @dtoo(st_subsample{!SubSample}_start)<@dtoo(st_tfirst_backtest) then
			st_subsample{!SubSample}_start=st_tfirst_backtest
			!ss_adjusted= 1
		endif

		if @dtoo(st_subsample{!SubSample}_end)>@dtoo(st_tlast_backtest) then
			st_subsample{!SubSample}_end=st_tlast_backtest
			!ss_adjusted= 1
		endif		

		if !ss_adjusted= 1 then
			scalar sc_SubSample{!SubSample}_length = @dtoo(st_subsample{!SubSample}_end)-@dtoo(st_subsample{!SubSample}_start)+1
			st_subsample{!SubSample} = st_subsample{!SubSample}_start + " " + st_subsample{!SubSample}_end
		endif	
	next
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine backtest_start_shift(string %sub_obj_name, string %sub_outofsample, string %sub_auto_selection, string %sub_object_alias)

' 1. Equation
if  {%sub_obj_name}.@type="EQUATION" then
	if @upper(%sub_auto_selection)="F" then
		!coef_n = {%sub_obj_name}.@ncoef
		scalar sc_backtest_start_shift{%sub_object_alias} = !coef_n*2
	else
		%command = {%sub_obj_name}.@command
		
		if @upper(st_auto_type) = "ARDL" then
			
			call ardl_auto_select_options(%sub_obj_name,%sub_object_alias)

			if sc_reglags{%sub_object_alias}<sc_deplags{%sub_object_alias} then
				scalar sc_backtest_start_shift{%sub_object_alias} = sc_reglags*2+sc_deplags*2+sc_deplags
			else
				scalar sc_backtest_start_shift{%sub_object_alias} = sc_reglags*2+sc_deplags*2+sc_reglags
			endif
			
			if @instr(@upper(%command),"TREND=NONE")=0 then
				sc_backtest_start_shift{%sub_object_alias} = sc_backtest_start_shift{%sub_object_alias}  + 2
			endif
				
			sc_backtest_start_shift{%sub_object_alias} = sc_backtest_start_shift{%sub_object_alias} + @wcount(%regressors)*2

		endif
		
		if @upper(st_auto_type) = "ARMA" then
			
			call arma_auto_select_options(%sub_obj_name)
			
			scalar sc_backtest_start_shift{%sub_object_alias} = sc_maxar*2+sc_maxma*2+2	
			
			if @instr(@upper(%command)," C ")>0 then
				sc_backtest_start_shift{%sub_object_alias} = sc_backtest_start_shift{%sub_object_alias}  + 1
			endif		
		endif
	endif
endif

' 2. VAR shift value
if  {%sub_obj_name}.@type="VAR" then
	if @upper(%sub_auto_selection)="F" then
		'!lag_order = {%sub_obj_name}.@lagorder Already accounted for through estimation sample adjustment
		!coef_n = {%sub_obj_name}.@ncoef
		scalar sc_backtest_start_shift{%sub_object_alias} = !coef_n*2
	else
		call var_auto_select_options(%sub_obj_name)

		!var_eq_n = {%sub_obj_name}.@neqn
		scalar sc_backtest_start_shift{%sub_object_alias} = sc_maxlag*!var_eq_n*2	
	endif
endif

if  {%sub_obj_name}.@type="STRING" then
	scalar sc_backtest_start_shift{%sub_object_alias} = 0
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine ardl_auto_select_options(string %sub_eq_name, string %sub_object_alias)
	
%deplags = @mid(%command,@instr(@upper(%command),"DEPLAGS"))
%deplags = @mid(%deplags,@instr(@upper(%deplags),"=")+1)

scalar sc_deplags{%sub_object_alias} = @val(@left(%deplags,@instr(%deplags,",")-1))

%reglags = @mid(%command,@instr(@upper(%command),"REGLAGS"))
%reglags = @mid(%reglags,@instr(@upper(%reglags),"=")+1)

if @instr(%reglags,",")>0 then
	scalar sc_reglags{%sub_object_alias} = @val(@left(%reglags,@instr(%reglags,",")-1))
else
	scalar sc_reglags{%sub_object_alias} = @val(@left(%reglags,@instr(%reglags,")")-1))	
endif

%regressors = @mid(%command,@instr(%command,") ")+1)
%regressors = @replace(%regressors," @","")

string st_auto_info = ""

if @instr(@upper(%command),"IC=")>0 then
	%selection_info = @mid(%command,@instr(@upper(%command),"IC="))
	%selection_info = @mid(%selection_info,@instr(@upper(%selection_info),"=")+1)

	if @instr(@upper(%selection_info),",")>0 then
		st_auto_info  = @left(%selection_info ,@instr(%selection_info ,",")-1)
	else
		st_auto_info  = @left(%selection_info ,@instr(%selection_info ,")")-1)
	endif

endif

if @isempty(st_auto_info) then
	st_auto_info 	= "AIC"
endif

if @upper(st_auto_info)="BIC"  or  @upper(st_auto_info)="SIC"  then
	st_auto_info = "schwarz"
endif
	
endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine arma_auto_select_options(string %sub_eq_name)
	
%selection_info = {%sub_eq_name}.@attr("selection_info")

if @isempty(%selection_info)=0 then

	if @instr(@upper(%selection_info),"MAXAR")>0 then
		%maxar = @mid(%selection_info,@instr(@upper(%selection_info),"MAXAR"))
		%maxar = @mid(%maxar,@instr(@upper(%maxar),"=")+1)
		
		if @instr(%maxar,",") then
			scalar sc_maxar{%sub_object_alias} = @val(@left(%maxar,@instr(%maxar,",")-1))
		else
			scalar sc_maxar{%sub_object_alias} = @val(%maxar)				
		endif	
	else
		scalar sc_maxar{%sub_object_alias} = 0 
	endif
	
	if @instr(@upper(%selection_info),"MAXMA")>0 then
		%maxma = @mid(%selection_info,@instr(@upper(%selection_info),"MAXMA"))
		%maxma = @mid(%maxma,@instr(@upper(%maxma),"=")+1)
		
		if @instr(%maxma,",") then
			scalar sc_maxma{%sub_object_alias} = @val(@left(%maxma,@instr(%maxma,",")-1))
		else
			scalar sc_maxma{%sub_object_alias} = @val(%maxma)				
		endif	
	else
		sc_maxma = 0 
	endif

	%info = @mid(%selection_info,@instr(@upper(%selection_info),"INFO"))
	string st_auto_info = @mid(%info,@instr(@upper(%info),"=")+1)

else
	scalar sc_maxar = 4	
	scalar sc_maxma = 4
endif

endsub


' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine var_auto_select_options(string %sub_eq_name)
	
%selection_info = {%sub_eq_name}.@attr("selection_info")

string st_auto_info = ""
scalar sc_maxlag = na

if @isempty(%selection_info)=0 then
	%maxlag = @mid(%selection_info,@instr(@upper(%selection_info),"MAXLAG"))
	%maxlag = @mid(%maxlag,@instr(@upper(%maxlag),"=")+1)
	
	if @instr(%maxlag,",") then
		scalar sc_maxlag{%sub_object_alias} = @val(@left(%maxlag,@instr(%maxlag,",")-1))
	else
		scalar sc_maxlag{%sub_object_alias} = @val(%maxlag)				
	endif	

	%info = @mid(%selection_info,@instr(@upper(%selection_info),"INFO"))
	string st_auto_info = @mid(%info,@instr(@upper(%info),"=")+1)
	
else
	string st_auto_info = "LR"
	scalar sc_maxlag = 4
endif

if @isempty(st_auto_info) then
	st_auto_info = "LR"
endif

if @isna(sc_maxlag) then
	sc_maxlag = 4
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine create_forecast_model(string %sub_eq_name, string %sub_cf_model_name, string %sub_forecast_dep_var)

'Create model
model {%sub_cf_model_name}

'Add main equation
if {%sub_eq_name}.@type="STRING" then
	{%sub_cf_model_name}.append {{%sub_eq_name}}
else
	{%sub_cf_model_name}.merge {%sub_eq_name}
endif

'Add dependent variable identity
if @upper(%sub_forecast_dep_var)="T" then
	%sub_DepVar = st_depvar
	{%sub_cf_model_name}.append @identity DepVar = {%sub_DepVar} 
endif

' Add additioanl equation
for !add_eq = 1 to sc_add_eq_count
	if @upper(st_add_eq_type{!add_eq})="EQUATION" then
		{%sub_cf_model_name}.merge {st_add_eq_name{!add_eq}}
	else
		%identity_string = {st_add_eq_name{!add_eq}}
		{%sub_cf_model_name}.append %identity_string
	endif
next

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine reestimation_parameters(string %sub_eq_name)

%est_command	 = 	{%sub_eq_name}.@command 

if @isempty(%tfirst_estimation)  then
	%tfirst_reestimation = @otod(1)
else
	%tfirst_reestimation = %tfirst_estimation
endif

%tlast_reestimation = @otod(@dtoo(%fstart)-1)

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine reestimation(string %sub_eq_name, string %sub_auto_selection)
	
' Defining reestimation parameters
call reestimation_parameters(%sub_eq_name)
			
if @upper(st_custom_reestimation)="F" then	

	' Identifying zero variance regressors
	if @instr(@upper(%est_command)," C ") then
						
		if @isobject("gr_"+ %sub_eq_name + "_regs")=0 then
			{%sub_eq_name}.makeregs gr_{%sub_eq_name}_regs
		endif
		
		!reg_n = gr_{%sub_eq_name}_regs.@count

		%regs = gr_{%sub_eq_name}_regs.@members		

		call zerovariance_identification(%regs, %tfirst_reestimation,  %tlast_reestimation, "zerovariance")
	endif
	
	' Identifying perfect correlation regressors
	if @isobject("gr_"+ %sub_eq_name + "_regs")=0 then
		{%sub_eq_name}.makeregs gr_{%sub_eq_name}_regs
	endif
	
	!reg_n = gr_{%sub_eq_name}_regs.@count
	call perfect_corr_identification(gr_{%sub_eq_name}_regs.@members, %tfirst_reestimation,  %tlast_reestimation, "perfectcor")

	' Reestimating 
	if @upper(%sub_auto_selection)="F" then
		call reestimating(%sub_eq_name)
	else
		call reestimating_auto(%sub_eq_name)
	endif
	
	' Updating model
	call update_forecast_model(%sub_eq_name,"m_speceval")
		
	if @upper(st_auto_selection)="T" and @upper(st_auto_type) = "ARDL"  and !fp=1 then			
		%depvar = gr_{%sub_eq_name}_regs.@seriesname(1)
		m_speceval.append {%depvar}=s_depvar

		for !reg = 1 to !reg_n	
			%reg = @word(%regs,!reg)
			m_speceval.append  s_reg{!reg} = {%reg}
		next
	endif		
else
	' Performing custom reestimation
	call reestimation_custom(%tfirst_reestimation,  %tlast_reestimation)			
endif	

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine zerovariance_identification(string %sub_series_list, string %sub_tfirst, string %sub_tlast, string %sub_indicator_name)

%{%sub_indicator_name} = "f"

!ser_n = @wcount(%sub_series_list)

for !ser = 1 to !ser_n 

	%sub_ser = @word(%sub_series_list,!ser)
	
	if @upper(%sub_ser)="C" then
		!{%sub_indicator_name}{!ser}  = 0
	else
		delete(noerr) s_temp

		smpl {%sub_tfirst} {%sub_tlast}
		series s_temp = {%sub_ser}
		
		!stdev = @stdev(s_temp)
	
		if !stdev=0 then
			!{%sub_indicator_name}{!ser}  = 1
			%{%sub_indicator_name} = "t"
		else
			!{%sub_indicator_name}{!ser}  = 0
		endif
	
		delete(noerr) s_temp
		
	endif
next

endsub


' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine perfect_corr_identification(string %sub_series_list, string %sub_tfirst, string %sub_tlast, string %sub_indicator_name)

%{%sub_indicator_name} = "f"

!ser_n = @wcount(%sub_series_list)

delete(noerr) gr_temp tb_cor

smpl {%sub_tfirst} {%sub_tlast}
group gr_temp {%sub_series_list}
freeze(tb_cor) gr_temp.cor

for !ser = 1 to !ser_n 		
	!{%sub_indicator_name}{!ser}  = 0		
next

for !ser1 = 1 to !ser_n 		
	for !ser2 = 1 to !ser_n 		
		if  !ser1<!ser2 then
			if @val(tb_cor(2+!ser1,1+!ser2))=1 then
				!{%sub_indicator_name}{!ser2}  = 1
				%{%sub_indicator_name} = "t"				
			endif
		endif		
	next
next

delete(noerr) gr_temp tb_cor

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine reestimating(string %sub_eq_name)

' 1. Initializing re-estimation command
%est_command_reest = %est_command

' 2. Removing zero-variance regressors 
if  @instr(@upper(%est_command)," C ") then
	if %zerovariance = "t" then
		for !r = 2 to !reg_n
			if !zerovariance{!r} = 1 then				
		
				'%reg_string = gr_{%sub_eq_name}_regs.@seriesname(!r)
				
				%est_command_reest = @replace(" " + @upper(%est_command_reest) + " "," C "," ")
				
			endif			
		next
		
		if !zerovariance1 = 1 then		
			@uiprompt("Dependent variable does not have any variation on sample " + %tfirst_reestimation + " "  + %tlast_reestimation)
		endif
	endif
endif

%est_command_reest = @trim(%est_command_reest)

' 3. Removing perfect correlation regressors
if @instr("  "  + @upper(%eq_command_reest) + " "," C ")=0 and !reg_n=2  then
	%perfectcor = "f"  
endif

if %perfectcor = "t" then
	for !reg = 2 to  !reg_n
		if !perfectcor{!reg} = 1 then
			%reg_string = gr_{%sub_eq_name}_regs.@seriesname(!reg)
			%est_command_reest = @replace(" " + @upper(%est_command_reest) + " "," "+ @upper(%reg_string) + " "," ")
		endif			
	next
endif 	

%est_command_reest = @trim(%est_command_reest)

' 4. Reestimating
if @upper(st_ignore_errors)="T" then
	!original_max_errors = @maxerrcount
	!original_errors = @errorcount
	!new_max_errors = !original_errors+2
	if !new_max_errors>!original_max_errors then
		setmaxerrs !new_max_errors
	endif
endif

%obj_type = {%sub_eq_name}.@type

smpl {%tfirst_reestimation} {%tlast_reestimation}
{%obj_type} {%sub_eq_name}_reest.{%est_command_reest}

if @upper(st_ignore_errors)="T" then

	if @isobject(%sub_eq_name + "_reest") then
		freeze(tx_temp) {%sub_eq_name}_reest.representations

		if @instr(@upper(tx_temp.@line(1)),"EQUATION DOES NOT HAVE ESTIMATES")>0 then
			!previous_fp = !fp-1
			copy(o) {%sub_eq_name}_reest{!previous_fp} {%sub_eq_name}_reest
		endif
	else
		copy(o) {%sub_eq_name} {%sub_eq_name}_reest
	endif
endif

delete(noerr) tx_temp

' 5. Storing 
copy {%sub_eq_name}_reest {%sub_eq_name}_reest{!fp}

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine reestimating_auto(string %sub_eq_name)

statusline Recursive forecasts: {!fp} out of {!forecastp_n} ({st_spec_name})

!auto_type_identified = 0

%command = {%sub_eq_name}.@command

if @upper(st_auto_type) = "ARDL" then

	if !fp = 1 then	
		call reestimation_auto_ardl(%sub_eq_name,"f")
	else
		if !fp = 1 then
			call reestimation_auto_ardl(%sub_eq_name,"t")
		else
			call reestimation_auto_ardl(%sub_eq_name,"t")		
		endif
	endif
	
	!auto_type_identified = 1
endif

if @upper(st_auto_type) = "ARMA" then
	call reestimation_auto_arma(%sub_eq_name)	
	!auto_type_identified = 1
endif

if @upper(st_auto_type) = "VAR" then
	call reestimation_auto_var(%sub_eq_name) 
	!auto_type_identified = 1
endif

if !auto_type_identified = 0 then
	call reestimating(%sub_eq_name)
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine reestimation_auto_ardl(string %sub_eq_name, string %sub_use_existing_table)
	
' 1. Determining dependent variable and regressors
call auto_ardl_reg_series(%sub_eq_name)

' 2. Determining maximum orders and IC

%command = {%sub_eq_name}.@command

call ardl_auto_select_options(%sub_eq_name,"")

' 3. Creating table
if @upper(%sub_use_existing_table)="F"  or @isobject("tb_ardl_models")=0 then
	
	'Headings
	table tb_ardl_models
	
	tb_ardl_models(1,1) = "Model #"
	tb_ardl_models(1,2) = "Criterion"
	tb_ardl_models(1,3) = "ARDL order"
	tb_ardl_models(1,4) = "ARDL equation"
	
	' Dependent varaible variations
	!model_count = 0
	for !dl = 0 to sc_deplags	
		!model_count = !model_count +1	
		tb_ardl_models(1+!model_count,3) = @str(!dl,"f.0") + " - " 	
	next
	
	'Regressor variations
	for !reg = 1 to !reg_n
		!current_row_n = tb_ardl_models.@rows
		!tr_count = !current_row_n
		for !tr = 2 to !current_row_n	
			for !rl = 0 to sc_reglags
				
				!tr_count = !tr_count+1	
				tb_ardl_models(!tr_count,3) = tb_ardl_models(!tr,3) + @str(!rl,"f.0") + ","
			next
		next
		
		!delete_row_n = !current_row_n -1 
		tb_ardl_models.deleterow(2) !delete_row_n
	next
	
	
	' Equation string master
	%ardl_equation_string_master = "s_depvar "
	
	for !reg = 1 to !reg_n	
		%reg = @word(%regs,!reg)
		%ardl_equation_string_master = %ardl_equation_string_master  + " " + "s_reg" + @str(!reg)
	next
	
	if @instr(@upper(%command),"TREND=NONE")=0 then
		%ardl_equation_string_master = %ardl_equation_string_master  + " " + "C"
	endif
	
	for  !m = 1 to tb_ardl_models.@rows-1
		
		' Model orders
		tb_ardl_models(!m+1,1) = @str(!m,"f.0")
		
		%ardl_order = tb_ardl_models(1+!m,3)
		!dlag = @val(@left(%ardl_order,@instr(%ardl_order,"-")-1))
		
		%reglag_orders = @mid(%ardl_order,@instr(%ardl_order,"-")+1)
		for !reg = 1 to !reg_n
			%rlag{!reg} = @left(%reglag_orders,@instr(%reglag_orders,",",!reg)-1)
			
			if !reg>1 then
				%rlag{!reg}  = @mid(%rlag{!reg},@instr(%rlag{!reg} ,",",!reg-1)+1)
			endif
			
			!rlag{!reg} = @val(%rlag{!reg})
		next
		
		'Creating equation string
		%ardl_equation_string = %ardl_equation_string_master
		
		if !dlag>0 then
			for !dl = 1 to !dlag
				%ardl_equation_string = %ardl_equation_string  + " " + "s_depvar" +  "(-" + @str(!dl) + ")"
			next
		endif	 
			
		for !reg = 1 to !reg_n				
			if !rlag{!reg} >0 then			
				for !rl = 1 to !rlag{!reg}
					%ardl_equation_string = %ardl_equation_string  + " " + "s_reg"+ @str(!reg) +  "(-" + @str(!rl) + ")"
				next
			endif	
		next
			
		tb_ardl_models(1+!m,4) = %ardl_equation_string
		
	next
	
	'Sorting
	!row_n =  tb_ardl_models.@rows
	tb_ardl_models.sort(a2:d{!row_n}) c
	
	'Adding model numbers
	for  !m = 1 to tb_ardl_models.@rows-1		
		tb_ardl_models(!m+1,1) = @str(!m,"f.0")		
	next
	
endif

' 4. Estimating all models
	
for  !m = 1 to tb_ardl_models.@rows-1
	
	'Specifying equation string
	%ardl_equation_string = tb_ardl_models(1+!m,4)
	
	' Removing zero-variance regressors 
	if @instr(@upper(%command),"TREND=NONE")=0 then
		call zerovariance_identification(%ardl_equation_string, %tfirst_reestimation,  %tlast_reestimation, "zerovariance")
	endif
	
	if %zerovariance = "t" then
		for !reg = 2 to @wcount(%ardl_equation_string)
			if !zerovariance{!reg} = 1 then
				%reg_string = @word(%ardl_equation_string,!reg)				
				%ardl_equation_string= @replace(" " + @upper(%ardl_equation_string) + " "," "+ @upper(%reg_string) + " "," ")				
			endif			
		next
		
		if !zerovariance1 = 1 then		
			@uiprompt("Dependent variable does not have any variation on sample " + %tfirst_reestimation + " "  + %tlast_reestimation)
		endif
	endif
	
	' Removing perfectly colinear regressors
	%ardl_equation_string_o = %ardl_equation_string
	 
	call perfect_corr_identification(%ardl_equation_string, %tfirst_reestimation,  %tlast_reestimation, "perfectcor")
	
	if %perfectcor = "t" then
		for !reg = 2 to  @wcount(%ardl_equation_string_o)			
			if !perfectcor{!reg} = 1 then
				%reg_string = @word(%ardl_equation_string_o,!reg)				
				%ardl_equation_string= @replace(" " + @upper(%ardl_equation_string) + " "," "+ @upper(%reg_string) + " "," ")	
			endif			
		next
	endif 	
	
	' Estimating
	smpl {%tfirst_reestimation} {%tlast_reestimation}
	equation eq_ardl{!m}.ls {%ardl_equation_string}
	
	tb_ardl_models(1+!m,2) = eq_ardl{!m}.@{st_auto_info}
	
next

' 5. Storing selected model

' Sorting
!row_n =  tb_ardl_models.@rows
if @upper(%select_info)="RBAR2" then
	tb_ardl_models.sort(a2:d{!row_n}) -b
else
	tb_ardl_models.sort(a2:d{!row_n}) b
endif

' selecting 
!final_model = @val(tb_ardl_models(2,1))
copy eq_ardl{!final_model} {%sub_eq_name}_reest

' 6. Storing and cleaning up
copy {%sub_eq_name}_reest {%sub_eq_name}_reest{!fp}

for  !m = 1 to tb_ardl_models.@rows-1
	delete(noerr) eq_ardl{!m}
next

if @isobject("sp_ardl_model_selection")=0 then 
	spool sp_ardl_model_selection
endif

sp_ardl_model_selection.insert(name=smpl_{%tfirst_reestimation}_{%tlast_reestimation}) tb_ardl_models

tb_ardl_models.sort(a2:d{!row_n}) c

%intermediate_objects = %intermediate_objects +  "s_depvar"  + " "

for !reg = 1 to !reg_n
	%intermediate_objects = %intermediate_objects +  "s_reg" + @str(!reg) + " "
next

%intermediate_objects = %intermediate_objects +  "tb_ardl_models sp_ardl_model_selection"  + " "
	
endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine auto_ardl_reg_series(string %sub_eq_name)

if @isobject("gr_"+ %sub_eq_name + "_regs")=0 then
	%regressors = @mid(%command,@instr(%command,") ")+1)
	%regressors = @replace(%regressors," @","")
	group gr_{%sub_eq_name}_regs {%regressors}
endif	

%depvar = gr_{%sub_eq_name}_regs.@seriesname(1)

smpl @all
%regs = gr_{%sub_eq_name}_regs.@members
%regs = @replace(@upper(%regs),@upper(%depvar),"")

!reg_n = @wcount(%regs)

smpl @all
series s_depvar = {%depvar}

for !reg = 1 to !reg_n	
	%reg = @word(%regs,!reg)
	series s_reg{!reg} = {%reg}
next

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine reestimation_auto_arma(string %sub_eq_name)
		
'Determining dependent variable and regressors
call auto_arma_reg_series(%sub_eq_name)

' Removing zero-variance regressors 
if %zerovariance = "t" then
	for !r = 2 to !reg_n
		if !zerovariance{!r} = 1 then
			%reg_string = gr_{%sub_eq_name}_regs.@seriesname(!r)
			
			%regs = @replace(" " + @upper(%regs) + " "," "+ @upper(%reg_string) + " "," ")
			
		endif			
	next
	
	if !zerovariance1 = 1 then		
		@uiprompt("Dependent variable does not have any variation on sample " + %tfirst_reestimation + " "  + %tlast_reestimation)
	endif
endif

'Removing perfect correlation regressors
if %perfectcor = "t" then
	for !reg = 2 to  !reg_n
		if !perfectcor{!reg} = 1 then
			%reg_string = gr_{%sub_eq_name}_regs.@seriesname(!reg)
			%regs= @replace(" " + @upper(%regs) + " "," "+ @upper(%reg_string) + " "," ")
		endif			
	next
endif 	

' Determining selection criterion
call arma_auto_select_options(%sub_eq_name)

' Estimating 
smpl {%tfirst_reestimation} {%tlast_reestimation}

if @instr(@upper({%sub_eq_name}.@command)," C ")>0 then
	s_depvar.autoarma(tform=none,diff=0,maxar={sc_maxar},maxma={sc_maxma},maxsar=0,maxsma=0,select={st_auto_info},eqname={%sub_eq_name}_reest) s_depvar_f c {%regs}
else
	s_depvar.autoarma(tform=none,diff=0,maxar={sc_maxar},maxma={sc_maxma},maxsar=0,maxsma=0,select={st_auto_info},eqname={%sub_eq_name}_reest) s_depvar_f {%regs}
endif

'Replacing dependent variable placeholder with actual dependent variable
%command={%sub_eq_name}_reest.@command 
%est_command_reest  = @replace(@upper(%command),"S_DEPVAR",%depvar)

smpl {%tfirst_reestimation} {%tlast_reestimation}
equation {%sub_eq_name}_reest.{%est_command_reest}

' Storing 
copy {%sub_eq_name}_reest {%sub_eq_name}_reest{!fp}


%intermediate_objects = %intermediate_objects +  "s_depvar s_depvar_f"  + " "

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine auto_arma_reg_series(string %sub_eq_name)

if @isobject("gr_"+ %sub_eq_name + "_regs")=0 then
	{%sub_eq_name}.makeregs gr_{%sub_eq_name}_regs
endif	

%depvar = gr_{%sub_eq_name}_regs.@seriesname(1)

smpl @all
series s_depvar = {%depvar}

%regs = gr_{%sub_eq_name}_regs.@members
%regs = @replace(@upper(%regs),@upper(%depvar),"")

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine reestimation_auto_var(string %sub_var_name)

'Determining dependent variable and regressors
if @isobject("gr_"+ %sub_var_name + "_regs")=0 then
	call regressor_group(%sub_var_name)
endif	

for !reg = 1 to gr_{%sub_var_name}_regs.@count
	%endog_var = gr_{%sub_var_name}_regs.@seriesname(!reg)
	if @instr(@upper(%endog_var),@upper(st_base_var))>0 then 
		%base_var_depvar = %endog_var
		exitloop
	endif
next


%regs_original = gr_{%sub_var_name}_regs.@members
%regs = @replace(@upper(%regs_original),@upper(%base_var_depvar ),"")

' Removing zero-variance regressors 
if %zerovariance = "t" then
	for !r = 2 to !reg_n
		if !zerovariance{!r} = 1 then
			%reg_string = gr_{%sub_var_name}_regs.@seriesname(!r)
			
			%regs = @replace(" " + @upper(%regs) + " "," "+ @upper(%reg_string) + " "," ")
			
		endif			
	next
	
	if !zerovariance1 = 1 then		
		@uiprompt("Dependent variable does not have any variation on sample " + %tfirst_reestimation + " "  + %tlast_reestimation)
	endif
endif

'Removing perfect correlation regressors
if %perfectcor = "t" then
	for !reg = 2 to  !reg_n
		if !perfectcor{!reg} = 1 then
			%reg_string = gr_{%sub_var_name}_regs.@seriesname(!reg)
			%regs= @replace(" " + @upper(%regs) + " "," "+ @upper(%reg_string) + " "," ")
		endif			
	next
endif 	

'Estimating initial var
%est_command_reest = "LS 1 2 " + @mid(@upper(%est_command),@instr(@upper(%est_command),@upper(gr_{%sub_var_name}_regs.@seriesname(1))))
%est_command_reest = @replace(@upper(%est_command_reest),@upper(%regs_original),@upper(%regs))

smpl {%tfirst_reestimation} {%tlast_reestimation}
var {%sub_var_name}_reest.{%est_command_reest} 

' Determining lag order
call var_auto_select_options(%sub_var_name)

freeze(tb_laglength) {%sub_var_name}_reest.laglen({sc_maxlag},vname=v_laglength) 

scalar sc_laglength =na

for !info = 1 to 5
	%info = @word(" LR FPE AIC SC HQ",!info)

	if @upper(st_auto_info)=%info then
		sc_laglength = v_laglength(!info)
	endif
next

%est_command_reest = @replace(%est_command_reest,"1 2","1 "+ @str(sc_laglength))

if @isobject("sp_var_model_selection")=0 then 
	series s_laglength = na
	spool sp_var_model_selection
endif

sp_var_model_selection.insert(name=smpl_{%tfirst_reestimation}_{%tlast_reestimation}) tb_laglength

smpl  {%tlast_reestimation}  {%tlast_reestimation}
s_laglength = sc_laglength

delete(noerr) tb_laglength v_laglength sc_laglength

' Estimating 
smpl {%tfirst_reestimation} {%tlast_reestimation}
var {%sub_var_name}_reest.{%est_command_reest}

' Storing 
copy {%sub_var_name}_reest {%sub_var_name}_reest{!fp}

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine create_forecast_number_tb

table(!forecastp_n+1,2) tb_forecast_numbers
tb_forecast_numbers(1,1) = "Forecast #"
tb_forecast_numbers(1,2) = "Forecast start"

tb_forecast_numbers.setformat(A) "f.0"
tb_forecast_numbers.setwidth(B) 15
	
endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine update_forecast_model(string %sub_eq_name, string %sub_cf_model_name)
	
if !fp=1 then
	{%sub_cf_model_name}.replacelink {%sub_eq_name} {%sub_eq_name}_reest
else
	{%sub_cf_model_name}.update {%sub_eq_name}_reest
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine creating_forecasts(string %sub_cf_model_name,string %sub_fstart,string %sub_fend, string %sub_EqVar, string %sub_forecast_dep_var)
	
' 1. Forecasting	

' Creating scenario
%forecast_alias = "f"
{%sub_cf_model_name}.scenario(n,a=_{%forecast_alias}) {%fstart} forecast

' Adding overrdides for forecasted indepdent varibles
if @isempty(st_forecasted_ivariables)=0 then
	for %ivar {st_forecasted_ivariables}
		if @isobject(%ivar + "_f" + %fstart) then
			copy {%ivar}_f{%fstart} {%ivar}_f
			{%sub_cf_model_name}.override(m) {%ivar}
		else
			if !fp = 1 and !spec_id=1 then
				@uiprompt("Could not locate forecast for independent variable: " + %ivar + "_f" + %fstart)
			endif
		endif
	next
endif

' Solving model
smpl {%sub_fstart} {%sub_fend}
{%sub_cf_model_name}.solve

' 2. Defining forecasted series
if @upper(%sub_forecast_dep_var)="T" then
	%history_series = st_depvar
	%forecasted_series = "DepVar" + "_" + %forecast_alias
else
	%history_series = %sub_EqVar
	%forecasted_series = %sub_EqVar + "_" + %forecast_alias
endif

' 3. Storing
smpl {%fstart}-1 {st_tlast_backtest}
series {%sub_EqVar}_f{%fstart} = {%forecasted_series}

tb_forecast_numbers(!fp+1,1) = !fp
tb_forecast_numbers(!fp+1,2) =%fstart
	
endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine subsample_ident
	
for !SubSample = 1 to sc_subsample_count
	if (@dateval(%fstart)=@dateval(st_subsample{!SubSample}_start)) then
		sc_SubSample{!SubSample}_start = !fp
	endif	
next

endsub

' ##################################################################################################################




' ##################################################################################################################

subroutine performance_metrics(string %sub_EqVar,  string %sub_master_mnemonic, scalar !sub_forecastp_n, string %sub_tfirst, string %sub_tlast, string %subsamples,string %sub_performance_metrics, string %sub_forecast_dep_var, string %sub_include_growth_rate, string %sub_forecast_horizons)

!sub_forecast_horizons_n = @wcount(%sub_forecast_horizons)

'1 Creating information objects if they do not exist
if @wcount(%subsamples)>0 then
	if @isobject("st_subsample"+ @str(@wcount(%subsamples)) + "_end")=0 then
		call SubSamples_info_objects(%subsamples)
	endif	

	for !subsample = 1 to sc_subsample_count
		sc_SubSample{!SubSample}_start = @dtoo(st_subsample{!subsample}_start)-@dtoo(%sub_tfirst)+1
	next
else
	scalar sc_subsample_count = 0
endif

' 2. Creating history series

if @upper(%sub_forecast_dep_var)="T" then
	%sub_history_series = st_depvar
else
	%sub_history_series = %sub_EqVar
endif

' 3. Adjusting set of forecast horizons	
call forecast_horizon_adjust(!sub_forecastp_n,%sub_forecast_horizons)

' 4. Creating performance vectors
call performance_vectors("v_"+ %sub_EqVar, %sub_performance_metrics,%sub_include_growth_rate)

' 5. Calculating performance metrics
for !flength_id = 1 to !sub_forecast_horizons_n
	
	!flength = @val(@word(%sub_forecast_horizons,!flength_id))
	
	' Creating performance vectors
	call fe_vectors("v_"+ %sub_EqVar,!sub_forecastp_n,%sub_tlast, !flength,%sub_include_growth_rate)
	
	'Calculating
	call performance_calculation(%sub_EqVar, %sub_history_series, %sub_master_mnemonic, %sub_tfirst, !sub_forecastp_n, %sub_performance_metrics, %sub_include_growth_rate)

next

' 6. Creating table
call metrics_table(%sub_performance_metrics, %sub_forecast_horizons)

endsub


' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine forecast_horizon_adjust(scalar !sub_forecastp_n, string %sub_forecast_horizons)

!forecast_horizon_adjust = 0

for !flength_id = 1 to !sub_forecast_horizons_n
	!flength = @val(@word(%sub_forecast_horizons,!flength_id))

	if !sub_forecastp_n-!flength +1<=0 then

		!forecast_horizon_adjust = 1
	 	!sub_forecast_horizons_n = !flength_id-1
		exitloop		
	endif
next

if !forecast_horizon_adjust = 1 then
	%sub_forecast_horizons_o = %sub_forecast_horizons

	if !sub_forecast_horizons_n = 0 then
		@uiprompt("There are no correct forecast horizons for model " + %alias + ". The forecast horizon was set to 1.")
		!sub_forecast_horizons_n =1

		%sub_forecast_horizons = "1"
	else

		%sub_forecast_horizons = ""

		for !flength_id = 1 to !sub_forecast_horizons_n
			%sub_forecast_horizons= %sub_forecast_horizons + @word(%sub_forecast_horizons_o,!flength_id) + " "
		next
	endif

	if @isobject("st_forecast_horizons") then
		delete(noerr) st_forecast_horizons_o
		rename st_forecast_horizons st_forecast_horizons_o
		 st_forecast_horizons = %sub_forecast_horizons
	endif 
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine performance_vectors(string %sub_vector_name_prefix, string %sub_performance_metrics, string %sub_include_growth_rate)

for %pm {%sub_performance_metrics} 
	
	%{%pm}_vector = %sub_vector_name_prefix + "_" + %pm
	vector(!sub_forecast_horizons_n) {%{%pm}_vector} = na
	
	%intermediate_objects = %intermediate_objects +  %{%pm}_vector + " "
	
	if @upper(%sub_include_growth_rate)="T" then
		%{%pm}_vector_growth = %sub_vector_name_prefix + "_"+ %pm  "_growth"
		vector(!sub_forecast_horizons_n) {%{%pm}_vector_growth} = na
		
		%intermediate_objects = %intermediate_objects +  %{%pm}_vector_growth + " "
	endif
	
	for !SubSample = 1 to sc_subsample_count
		%{%pm}_vector_ss{!SubSample} = %sub_vector_name_prefix + "_" + %pm + "_ss" + @str(!SubSample) 
		vector(!sub_forecast_horizons_n) {%{%pm}_vector_ss{!SubSample}} = na
		
		%intermediate_objects = %intermediate_objects +  %{%pm}_vector_ss{!SubSample} + " "
	next	

next

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	
subroutine fe_vectors(string %sub_vector_name_prefix, scalar !sub_forecastp_n, string %sub_tlast, scalar !sub_flength, string %sub_include_growth_rate)

%sub_vector_name_suffix = "_h" + @str(!sub_flength)

%fe_vector_name_body = %sub_vector_name_prefix + "_fe" 
%fe_vector = %fe_vector_name_body  + %sub_vector_name_suffix
vector(!sub_forecastp_n-!sub_flength +1) {%fe_vector} = na

%intermediate_objects = %intermediate_objects +  %fe_vector  + " "

if @upper(%sub_include_growth_rate)="T" then
	%fe_vector_growth = %sub_vector_name_prefix + "_fe_gr" + %sub_vector_name_suffix    
	vector(!sub_forecastp_n-!sub_flength +1) {%fe_vector_growth} = na
	
	%intermediate_objects = %intermediate_objects +  %fe_vector_growth  + " "
endif

for !SubSample = 1 to sc_subsample_count
	%fe_vector_SubSample_{!SubSample} = %sub_vector_name_prefix + "_fe_ss" + @str(!SubSample) + %sub_vector_name_suffix  
	
	!subsample_obs_n = sc_SubSample{!SubSample}_length-!flength+1

	if !subsample_obs_n>0 then
		vector(!subsample_obs_n) {%fe_vector_SubSample_{!SubSample}} = na
	endif	
	
	%intermediate_objects = %intermediate_objects +  %fe_vector_SubSample_{!SubSample}  + " "
	
next

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine performance_calculation(string %sub_EqVar, string %sub_history_series, string %sub_master_mnemonic, string %sub_tfirst, scalar !sub_forecastp_n, string %sub_performance_metrics, string %sub_include_growth_rate)

' 1. Calculating forecast errors

for !fp = 1 to !sub_forecastp_n-!flength+1						
	%fstart = @otod(@dtoo(%sub_tfirst)+!fp-1)
	
	%sub_forecast_series =  @replace(@upper(%sub_master_mnemonic),"{FSTART}",%fstart)

	' Forecast errors - level
	call forecast_error_calculation(%sub_history_series, %sub_forecast_series,@otod(@dtoo(%fstart)+!flength-1),%sub_include_growth_rate,%fe_vector,!fp) 

	' Forecasti error - sub-samples
	for !SubSample = 1 to sc_subsample_count
		if !flength<=sc_subsample{!subsample}_length then
			if !fp>=sc_SubSample{!SubSample}_start and !fp+!flength<=sc_SubSample{!SubSample}_start+sc_SubSample{!SubSample}_length then
				{%fe_vector_SubSample_{!SubSample}}(!fp-sc_SubSample{!SubSample}_start+1) = !forecast_error	
			endif
		endif
	next
		
	' Forecast errors - growth rates
	if @upper(%sub_include_growth_rate)="T" then
		series s_history_growth = @pc(s_history_series)
		series s_forecast_growth = @pc({%sub_forecast_series})
		
		call forecast_error_calculation("s_history_growth","s_forecast_growth",@otod(@dtoo(%fstart)+!flength-1),"f",%fe_vector_growth,!fp) 
	endif		

next

' 2. calculating performance metrics

'RMSE
if @instr(@upper(%sub_performance_metrics),"RMSE")>0 then
	{%rmse_vector}(!flength_id) = @sqrt(@mean(@epow({%fe_vector},2)))

	for !SubSample = 1 to sc_subsample_count
		if !flength<=sc_subsample{!subsample}_length then
			{%rmse_vector_ss{!SubSample}}(!flength_id) = @sqrt(@mean(@epow({%fe_vector_SubSample_{!SubSample}},2))) 
		endif
	next
endif

' MAE
if @instr(@upper(%sub_performance_metrics),"MAE")>0 then
	{%mae_vector}(!flength_id) = @mean(@abs({%fe_vector}))

	for !SubSample = 1 to sc_subsample_count
		if !flength<=sc_subsample{!subsample}_length then
			{%mae_vector_ss{!SubSample}}(!flength_id) = @mean(@abs({%fe_vector_SubSample_{!SubSample}}))
		endif
	next
endif

' Bias
if @instr(@upper(%sub_performance_metrics),"BIAS")>0 then
	{%bias_vector}(!flength_id) = @mean({%fe_vector})
	
	for !SubSample = 1 to sc_subsample_count
		if !flength<=sc_subsample{!subsample}_length then
			{%bias_vector_ss{!SubSample}}(!flength_id) = @mean({%fe_vector_SubSample_{!SubSample}})
		endif
	next
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine forecast_error_calculation(string %sub_history_series, string %sub_forecast_series, string %sub_fend, string %sub_percentage_error, string %sub_vector,scalar !sub_position)

if @upper(%sub_percentage_error) = "T" then
	!forecast_error =  100*(1-@elem({%sub_forecast_series},%sub_fend)/@elem({%sub_history_series},%sub_fend))		
else
	!forecast_error = @elem({%sub_history_series},%sub_fend)-@elem({%sub_forecast_series},%sub_fend)
endif

{%sub_vector}(!sub_position) = !forecast_error

endsub


' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine metrics_table(string %sub_performance_metrics, string %sub_forecast_horizons)

' 1  Creating table
delete(noerr) tb_performance_metrics
table tb_performance_metrics
tb_performance_metrics(2,1) = "Metric"

for !pm = 1 to @wcount(%sub_performance_metrics)
	
	%pm = @word(%sub_performance_metrics,!pm)		

	tb_performance_metrics(3+!pm,1) = @upper(%pm)	

next

tb_performance_metrics(3+@wcount(%sub_performance_metrics)+1,1) = "#"

tb_performance_metrics(1,2) = "Forecast horizons (# of steps ahead)"

for !h = 1 to !sub_forecast_horizons_n
	
	%h = @word(%sub_forecast_horizons,!h)
	tb_performance_metrics(2,1+!h) = @upper(%h)		
next

tb_performance_metrics(2,1+!sub_forecast_horizons_n+1) = "Avg." 

!last_col = !sub_forecast_horizons_n+2
tb_performance_metrics.setlines(3,1,3,{!last_col}) +d
tb_performance_metrics.setlines(1,2,1,{!last_col}) +b

' 2. Fillling table	

' Full sample
for !pm = 1 to @wcount(%sub_performance_metrics)
	
	%pm = @word(%sub_performance_metrics,!pm)		

	!sum = 0 
	!horizons_count = 0
	for !h = 1 to !sub_forecast_horizons_n

		!value = {%{%pm}_vector}(!h)
		call get_formated_value(!value,"metric_value")
		tb_performance_metrics(3+!pm,1+!h) = %metric_value

		if @isna(!value)=0 then
			!sum = !sum + !value
			!horizons_count = !horizons_count +1 
		endif
	next	

	!average = !sum/!horizons_count
	call get_formated_value(!average,"metric_average")
	tb_performance_metrics(3+!pm,1+!sub_forecast_horizons_n+1) = %metric_average
	
next

for !h = 1 to !sub_forecast_horizons_n
	%h = 	 @word(%sub_forecast_horizons,!h)
	tb_performance_metrics(3+@wcount(%sub_performance_metrics)+1,1+!h) = @str({%fe_vector_name_body}_h{%h}.@rows,"f.0")
next


' Sub samples

if sc_subsample_count>0 then
	
	tb_performance_metrics.insertrow(4) 1 
	tb_performance_metrics(4,1) = "Full sample"
	tb_performance_metrics.setfont(4,1) +b
	tb_performance_metrics.setjust(4,1) left
		
	
	for !subsample = 1 to sc_subsample_count
		!heading_row = 3+@wcount(%sub_performance_metrics)+2+(!subsample-1)*(@wcount(%sub_performance_metrics)+2)+1
	
		tb_performance_metrics(!heading_row,1) =@mid(st_subsample{!SubSample}_start,3)+"_" + @mid(st_subsample{!SubSample}_end,3)
		tb_performance_metrics.setfont(!heading_row,1) +b
		tb_performance_metrics.setjust(!heading_row,1) left			


		for !pm = 1 to @wcount(%sub_performance_metrics)
			
			%pm = @word(%sub_performance_metrics,!pm)		
			
			!row = !heading_row + !pm
			
			tb_performance_metrics(!row,1) = @upper(%pm)
		
			!sum = 0 
			!horizons_count = 0
			for !h = 1 to !sub_forecast_horizons_n

				!value = {%{%pm}_vector_ss{!SubSample}}(!h)
				call get_formated_value(!value,"metric_value")
				tb_performance_metrics(!row,1+!h) = %metric_value

				if @isna(!value)=0 then
					!sum = !sum + !value
					!horizons_count = !horizons_count +1 
				endif
			next
			
			!average = !sum/!horizons_count
			call get_formated_value(!average,"metric_average")

			tb_performance_metrics(!row,1+!sub_forecast_horizons_n+1) = %metric_average

		next	
		
		tb_performance_metrics(!heading_row+@wcount(%sub_performance_metrics)+1,1) = "#"
		
		for !h = 1 to !sub_forecast_horizons_n
			%h = 	 @word(%sub_forecast_horizons,!h)
			'v.@droprow(@emult(@eneq(v, v), @ranks(@ones(@rows(v)), "a", "i"))) - removing NAs

			if @isobject(%fe_vector_name_body + "_ss"+ @str(!subsample) + "_h"+ %h) then
				tb_performance_metrics(!heading_row+@wcount(%sub_performance_metrics)+1,1+!h) = @str({%fe_vector_name_body}_ss{!subsample}_h{%h}.@rows,"f.0")
			endif
		next
	next
endif	

'Full sample - growth rate
' TBA

' Additional formating
!last_row = tb_performance_metrics.@rows
tb_performance_metrics.setlines(2,1,!last_row,1) +r

if sc_subsample_count>0 then
	tb_performance_metrics.setwidth(	A) 15
endif

endsub 

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine get_formated_value(scalar !sub_value,string %sub_string_name)

if @abs(!sub_value)>10 then
	%{%sub_string_name}= @str(!sub_value,"f.0")
endif

if @abs(!sub_value)<10 and @abs(!sub_value)>1 then
	%{%sub_string_name}= @str(!sub_value,"f.2")
endif

if @abs(!sub_value)<1 then
	%{%sub_string_name}= @str(!sub_value,"g.2")
endif

if @isna(!sub_value) then
	%{%sub_string_name}= @str(!sub_value)
endif

endsub

' ##################################################################################################################





' ##################################################################################################################

subroutine forecast_graphs(string %sub_EqVar, string %sub_eq_name,  scalar !sub_forecastp_n, string %sub_tfirst, string %sub_tlast,string %sub_forecast_dep_var)

' 0. Creating history series if it does not exist
if @isobject("s_history_series")=0 then
	if @upper(%sub_forecast_dep_var)="T" then
		series s_history_series = {st_depvar}
	else
		series s_history_series = {st_base_var}
	endif
endif

' 1. All forecasts

if @instr(@upper(st_exec_list),"GRAPHS_SUMMARY") then
	'  Graph sample
	call foreast_graphs_sample(st_tfirst_backtest,st_tlast_backtest)
	
	if @upper(st_transformation)="INDEX" then
		if @isempty(st_index_period) then
			st_index_period = %sub_tfirst
		endif
	endif
	
	'Creating graphs
	
	for !flength_id = 1 to sc_graph_horizons_n
	
		!flength = @val(@word(st_graph_horizons,!flength_id))

		call forecast_graphs_summary("s_history_series",%sub_EqVar + "_f{fstart}",!flength,%sub_tfirst, %sub_tlast,st_transformation,%graph_sample_string,st_spread_benchmark,st_index_period,st_graph_add_backtest,st_forecasted_ivariables) 
		copy(o) gp_forecasts_all gp_forecasts_all_h{!flength}
		delete(noerr) gp_forecasts_all
		
	next
endif

' 2. Subsample forecasts
if @instr(@upper(st_exec_list),"GRAPHS_SS") then
	for !SubSample = 1 to sc_subsample_count
	
		if @dtoo(%sub_tfirst)<=@dtoo(st_subsample{!SubSample}_start) then
	
			call graphs_SubSample("s_history_series",%sub_EqVar + "_f{fstart}",st_spread_benchmark)
			copy(o) gp_forecast_SubSample gp_forecast_SubSample{!SubSample}
			delete(noerr) gp_forecast_SubSample 
			
			'call SubSample_drivers
			'sp_forecast_SubSample_{!SubSample}.insert(name=spec{!id}_drivers) gp_{%eq_var}_drs	
			'delete(noerr) gp_{%eq_var}_drs

			if @instr(@upper(st_exec_list),"DECOMPOSITION") then
				%ss_sample = st_subsample{!SubSample}
	
				if @upper(st_outofsample)="T" then
					%ss_eq = st_spec_name + "_reest"+ @str(sc_subsample{!subsample}_start)
				else
					%ss_eq = st_spec_name
				endif
	
				%ss_alias = "_f" +st_subsample1_start
				%ss_graph_name = "gp_forecast_subsample"+ @str(!subsample) + "_fd"
				delete(noerr) {%ss_graph_name}		
	
				{%ss_eq}.fcastdecomp(scenarios=%ss_alias, include_addf="f",sample=%ss_sample,keep_table="t",graph_name=%ss_graph_name)
	
				if @isobject(%ss_graph_name) then
					{%ss_graph_name}.addtext(t) Decomposition of conditional forecast for {%ss_sample}
					{%ss_graph_name}.setattr("desc") Decomposition of conditional forecast for {%ss_sample}
				endif
			endif
		endif
	next
endif
		
endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine foreast_graphs_sample(string %sub_tfirst, string %sub_tlast)

%graph_sample_string = %sub_tfirst + " " + %sub_tlast

if @isempty(%sub_tfirstgraph_user) = 0 then
	%graph_sample_string = @replace(@upper(%graph_sample_string),@upper(%sub_tfirst),@upper(%sub_tfirstgraph_user))
endif

if @isempty(%sub_tlastgraph_user) = 0 then
	%graph_sample_string = @replace(@upper(%graph_sample_string),@upper(%sub_tlast),@upper(%sub_tlastgraph_user))
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine forecast_graphs_summary(string %sub_history_series,string %sub_master_mnemonic, scalar !sub_horizon,string %sub_tfirst, string %sub_tlast, string %sub_transformation, string %sub_graph_sample, string %sub_spread_benchmark, string %sub_index_period, string %sub_graph_add, string %sub_forecasted_ivariables)
		
!sub_forecastp_n = @dtoo(%sub_tlast)-@dtoo(%sub_tfirst)+1

' 1. Preparing history comparison series

' Removing right-axis idetificator
%additional_graph_series = @replace(@upper(%sub_graph_add),"[R]","")

'2. Creating group

delete(noerr) gr_forecasts_all 
group gr_forecasts_all 

' Adding historical series

if @upper(%sub_transformation)="GROWTH" then
	smpl @all
	gr_forecasts_all.add @pca({%sub_history_series}) {%additional_graph_series}
endif

if @upper(%sub_transformation)="SPREAD" then
	smpl @all
	gr_forecasts_all.add {%sub_history_series}-{%sub_spread_benchmark} {%additional_graph_series}
endif

if @upper(%sub_transformation)="INDEX" then
	smpl @all
	gr_forecasts_all.add {%sub_history_series}/@elem({%sub_history_series},%sub_index_period)*100 {%additional_graph_series}
endif

if @isempty(%sub_transformation) or @upper(%sub_transformation)="LEVEL" or @upper(%sub_transformation)="NONE" or @upper(%sub_transformation)="DEVIATION" then
	smpl @all
	gr_forecasts_all.add {%sub_history_series} {%additional_graph_series}
endif

'Adding forecast series
if @dtoo(%sub_tfirst)<=@dtoo(@word(%sub_graph_sample,1)) then
	%sub_add_tfirst = @word(%sub_graph_sample,1)
else
	%sub_add_tfirst = %sub_tfirst
endif

call forecasts_add(%sub_history_series,%sub_master_mnemonic,!sub_horizon, %sub_add_tfirst, %sub_tlast, %sub_transformation, %sub_spread_benchmark, %sub_index_period, %sub_forecasted_ivariables)

' 3. Creating graph
delete(noerr) gp_forecasts_all

smpl {%sub_graph_sample}
graph gp_forecasts_all.line gr_forecasts_all

' 4. Formating graph

gp_forecasts_all.legend -display

gp_forecasts_all.addtext(t) Conditional forecasts - {!sub_horizon} step ahead
gp_forecasts_all.setelem(1) symbol(7) legend("Actuals")

if @isempty(%sub_graph_add)=0 then

	gp_forecasts_all.legend +display position(r)

	!e_count = 1
	!s_count = 1
	for !v = 1 to @wcount(%sub_graph_add)

		!e_count = !e_count +1
		!s_count = !s_count + 1
		%hvar_name = @word(%sub_graph_add,!v)

		gp_forecasts_all.setelem(!e_count) linepattern(solid) legend(%hvar_name) 'symbol(!s_count) 
	
		if @instr(@upper(%hvar_name),"[R]")>0 then
			gp_forecasts_all.setelem(!e_count) axis(r)
			gp_forecasts_all.axis overlap
		endif
	next
endif

!e_count = 1+@wcount(%sub_graph_add)
for !f = 1 to gr_forecasts_all.@count-1-@wcount(%sub_graph_add)
	!e_count = !e_count +1
	gp_forecasts_all.setelem(!e_count)  legend("") linepattern(dash6) linewidth(1)
next

gp_forecasts_all.options +linepat

if @upper(%sub_transformation)="GROWTH" or @upper(%sub_transformation)="SPREAD" then
	gp_forecasts_all.draw(left,line) 0 0
endif

if @upper(%sub_transformation)="GROWTH" or @upper(%sub_transformation)="SPREAD" then
	gp_forecasts_all.draw(left,line) 0 0
endif


' 6. Cleaning up

for !f = 1 to !sub_forecastp_n		
	%fstart = @otod(@dtoo(%sub_tfirst)+!f-1)		
	delete(noerr) forecast{%fstart}
next

delete gr_forecasts_all

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine forecasts_add(string %sub_history_series, string %sub_master_mnemonic,scalar !sub_horizon,   string %sub_tfirst, string %sub_tlast, string %sub_transformation, string %sub_spread_benchmark, string %sub_index_period, string %sub_forecasted_ivariables)

' 1. Checking for level-type equations
%q_level_check = @otod(@dtoo(%sub_tfirst)+8)	

for !f = 1 to 2	

	%fstart = @otod(@dtoo(%sub_tfirst)+!f-1)	

	%sub_forecast_series =  @replace(@upper(%sub_master_mnemonic),"{FSTART}",%fstart)
	
	!forecast_level_check{!f} = @elem({%sub_forecast_series},%q_level_check)
	'scalar forecast_level_check{!f} = !forecast_level_check{!f}
next

!level_specification = 1
!forecast_level_check = !forecast_level_check1

for !f = 1 to 2

	if !forecast_level_check<>!forecast_level_check{!f} then
		!level_specification = 0
		exitloop
	endif
next

' 2. Adding forecasts

for !f = 1 to @dtoo(%sub_tlast)-@dtoo(%sub_tfirst)+1		
				
	' Forecast date
	%fstart = @otod(@dtoo(%sub_tfirst)+!f-1)

	' Series name
	%sub_forecast_series =  @replace(@upper(%sub_master_mnemonic),"{FSTART}",%fstart)

	'Preparing foreast series
	if @upper(%sub_transformation)<>"GROWTH" and @upper(%sub_transformation)<>"SPREAD" then
		if !level_specification<>1 then
			smpl {%fstart}-1 {%fstart}+!sub_horizon-1
			series forecast{%fstart} = {%sub_forecast_series}
		else
			smpl {%fstart} {%fstart}+!sub_horizon-1
			series forecast{%fstart} = {%sub_forecast_series}
		endif
	endif

	if @upper(%sub_transformation)="GROWTH" then

		smpl {%fstart}-1 {%fstart}+!sub_horizon-1
		series forecast{%fstart} = @pca({%sub_forecast_series})

		smpl {%fstart}-1 {%fstart}-1
		forecast{%fstart} = @pca({%sub_history_series})

	endif

	if @upper(%sub_transformation)="SPREAD" then

		if @instr(@upper(%sub_forecasted_ivariables),@upper(%sub_spread_benchmark))>0 then
			%sub_spread_benchmark = %sub_spread_benchmark + "_f"+ %fstart
		endif

		smpl {%fstart}-1 {%fstart}+!sub_horizon-1
		series forecast{%fstart} = {%sub_forecast_series}-{%sub_spread_benchmark}
	endif

	if  @upper(%sub_transformation)="INDEX" then
		series forecast{%fstart} = forecast{%fstart}/@elem({%sub_history_series},%sub_index_period)*100
	endif		
	
	'Adding to group
	gr_forecasts_all.add forecast{%fstart}

next

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine graphs_SubSample(string %sub_history_series, string %sub_master_mnemonic, string %sub_spread_benchmark)

delete(noerr) gp_forecast_SubSample

%sub_forecast_series =  @replace(@upper(%sub_master_mnemonic),"{FSTART}",st_subsample{!SubSample}_start)

if @upper(st_transformation)="NONE" or @upper(st_transformation)="DEVIATION" then
	smpl {st_subsample{!SubSample}_start}-1  {st_subsample{!SubSample}_end}
	graph gp_forecast_SubSample.line {%sub_history_series} {%sub_forecast_series}
endif

if @upper(st_transformation)="GROWTH" then
	smpl {st_subsample{!SubSample}_start}-1  {st_subsample{!SubSample}_end}
	graph gp_forecast_SubSample.line @pca({%sub_history_series}) @pca({%sub_forecast_series})
endif

if @upper(st_transformation)="SPREAD" then
	smpl {st_subsample{!SubSample}_start}-1  {st_subsample{!SubSample}_end}
	graph gp_forecast_SubSample.line {%sub_history_series}-{%sub_spread_benchmark} {%sub_forecast_series}-{%sub_spread_benchmark}
endif

if @upper(st_transformation)="INDEX" then
	%base_q_subsample = @otod(@dtoo(st_subsample{!SubSample}_start)-1)
	
	smpl {st_subsample{!SubSample}_start}-1  {st_subsample{!SubSample}_end}
	graph gp_forecast_SubSample.line {%sub_history_series}/@elem({%sub_history_series},%base_q_subsample)*100 {%sub_forecast_series}/@elem({%sub_forecast_series},%base_q_subsample)*100
endif

gp_forecast_SubSample.setelem(1)  legend(Actuals) symbol(filledcircle)
gp_forecast_SubSample.setelem(2) legend(Forecast)

gp_forecast_SubSample.addtext(t) Conditional forecast for {st_subsample{!SubSample}_start}-{st_subsample{!SubSample}_end}

endsub

' ##################################################################################################################





' ##################################################################################################################

subroutine forecast_bias_graphs(string %sub_history_series,string %sub_master_mnemonic)
	
for !flength_id = 1 to sc_bias_horizons_n
	
	' 1. Forecast horizon
	!flength = @val(@word(st_bias_horizons,!flength_id))

	' 2. Creating forecast bias matrix
	matrix(sc_forecastp_n-!flength +1,2) m_forecast_bias

	for !f = 1 to sc_forecastp_n-!flength+1

		%fstart = @otod(@dtoo(st_tfirst_backtest)+!f-1)	

		%sub_forecast_series =  @replace(@upper(%sub_master_mnemonic),"{FSTART}",%fstart)

		%forecast_p = @otod(@dtoo(%fstart)+!flength-1)

		m_forecast_bias(!f,1) = @elem({%sub_forecast_series},%forecast_p)			
		m_forecast_bias(!f,2) = @elem({%sub_history_series},%forecast_p)

	next	
	
	' 3 Creating forecast bias graph
	
	' Creating graph
	delete(noerr) gp_forecast_bias
	freeze(gp_forecast_bias) m_forecast_bias.scat linefit()
	gp_forecast_bias.setelem(1) legend(Forecast)
	gp_forecast_bias.setelem(2) legend(Actual)
	gp_forecast_bias.addtext(t) Forecast bias - {!flength} steps ahead
	gp_forecast_bias.setattr("descr") Forecast bias - {!flength} steps ahead
	
	' Adjusting axis scales
	!range_min = @min(m_forecast_bias)*0.95
	!range_max = @max(m_forecast_bias)*1.05
	
	gp_forecast_bias.axis(l) range(!range_min, !range_max)
	gp_forecast_bias.axis(b) range(!range_min, !range_max)	
	
	' Adding 45-degree line
	'gp_forecast_bias.addarrow axipos(!range_min,!range_min, !range_max, !range_max) pattern(dash6) color(black) startsym(none) endsym(none)
	gp_forecast_bias.addarrow pos(0,3,3,0) startsym(none) endsym(none) pattern(7) linewidth(0.5)
	
	' Storing objects
	copy(o) gp_forecast_bias gp_forecast_bias_h{!flength}
	copy(o) m_forecast_bias m_fb_h{!flength}
	
	delete(noerr) gp_forecast_bias m_forecast_bias

	%intermediate_objects = %intermediate_objects +  "m_fb_h" + @str(!flength) + " "	

next

endsub


' ##################################################################################################################




' ##################################################################################################################

subroutine conditional_scenario_forecast
	
' 1. Creating forecast model
if @isobject("m_speceval")=0 then
	call create_cforecast_model(st_spec_name,"m_speceval",st_forecast_depvar)
endif

' 2. Identifying all model
string st_exog_variables = m_speceval.@exoglist

' 3. Checking existence of scenario series
call missing_scen_variables

' 4. Loading missing variables
if @upper(st_scenario_dataload) = "T" then
	for %s {st_scenarios}
		if @isempty(st_missing_variables_{%s})=0 then
			call scenario_dataload(st_missing_variables_{%s},%s)
		endif
	next
endif

'5. Updating list of missing scenario variables 
call missing_scen_variables

' 6. Defining forecasting sample

if @isobject("tb_sb_" + st_spec_name)=0 then
	call sample_boundaries(st_spec_name,"f")	
endif

if @isempty(st_tfirst_scenarios)=0 then
	if @dtoo(tb_sb_{st_spec_name}(2,3))<@dtoo(st_tfirst_scenarios) then
		st_tfirst_scenarios = tb_sb_{st_spec_name}(2,3)
	endif
else
	st_tfirst_scenarios = tb_sb_{st_spec_name}(2,3)	
endif

' 6. Creating scenario forecasts	

for !s = 1 to @wcount(st_scenarios)	
	%scenario = @word(st_scenarios,!s)	
	call csf_forecasting(%scenario,"csf" +  %scenario,"Conditional shock - " + %scenario,"m_speceval")	
next

' 7. Creating scenario forecast graphs

' 7.1 Individual scenario graphs
if @instr(@upper(st_exec_list),"SCENARIOS_INDIVIDUAL") then
	for !s = 1 to @wcount(st_scenarios)
		
		%scenario  = @word(st_scenarios,!s)
		
		%sub_transformation = st_transformation
		
		if !s = 1 and @upper(st_transformation)="DEVIATION" then
			%sub_transformation = "level"
		endif
				
		%add_scenarios = st_add_scenarios
		if !s>1 and @upper(st_include_baseline)="T" then
			%add_scenarios = "csf"+ %baseline_alias + " " + %add_scenarios 
		endif

		if @upper(st_include_original)="T" then
			%add_scenarios = @replace(@upper(%add_scenarios),@upper(%scenario),"")
		endif

		call shock_graphs(st_include_original,%add_scenarios,%sub_transformation)
	next
endif

' 7.3 Creating all scenario graphs
if @instr(@upper(st_exec_list),"SCENARIOS_ALL") then
	call all_scenario_graphs(st_base_var+ "_csf" +"{S}",st_transformation)
endif

' 8. Scenario forecast drivers
if @instr(@upper(st_exec_list),"DECOMPOSITION") then

	%csf_sample = st_tfirst_scenarios  + " " + st_tlast_scenarios
	for %s {st_scenarios}
		%alias = "_csf" + %s + "[" +"_"+  %s + "]"
		%graph_name = "gp_csf_fd_" + %s

		{st_spec_name}.fcastdecomp(scenarios=%alias,include_addf="f",sample=%csf_sample,keep_table="t",use_table="t",graph_name=%graph_name)

		if @isobject(%graph_name) then
			%desc = "Decomposition of conditional "+ %scenario + " forecast"
			{%graph_name}.addtext(t) {%desc}
			{%graph_name}.setattr(description) {%desc}
		endif
	next

	for !s = 2 to @wcount(st_scenarios)
		%alias_list = "_csf" + "_"+ @word(st_scenarios,!s)  +"[" + "_"+ @word(st_scenarios,!s)   + "]" +  " " +"_csf"+  @word(st_scenarios,1)  +"[" + "_"+ @word(st_scenarios,1)   + "]" 
		%graph_name = "gp_csf_fdd_" + %s

		{st_spec_name}.fcastdecomp(scenarios=%alias_list,include_addf="f",sample=%csf_sample,keep_table="t",graph_name=%graph_name)

		if @isobject(%graph_name) then
			%desc = "Decomposition of conditional "+ %scenario + "-" + @word(st_scenarios,1)  + " forecast"
			{%graph_name}.addtext(t) {%desc}
			{%graph_name}.setattr(description) {%desc}
		endif
	next

	delete(noerr) gp_fd st_equation_vars
	%intermediate_objects = %intermediate_objects + " "+ "tb_forecast_decomposition"

endif


' 9. Cleaning up
delete(noerr) {st_base_var}_csf

if @wcount(st_exog_variables)>0 then
	for %evar {st_exog_variables}
		delete(noerr) {%evar}_csf
	next
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine missing_scen_variables

for %s {st_scenarios}
	
	string st_missing_variables_{%s} = "" 
	
	if @wcount(st_exog_variables)>0 then
		for %var {st_exog_variables}
			if @isobject(%var + "_"  + %s)=0 then  
				st_missing_variables_{%s} = st_missing_variables_{%s} + %var + " "
			endif
		next
	endif
	
	%intermediate_objects = %intermediate_objects + " " + "st_missing_variables_" + %s
next

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine csf_forecasting(string %sub_salias_source, string %sub_salias, string %sub_scenario_name, string %sub_model_name)

'1. Creating scenario 

%override_list = @wnotin(@upper(st_exog_variables),@upper(st_missing_variables_{%sub_salias_source}))

{%sub_model_name}.scenario(n,a=_csf) %sub_scenario_name
{%sub_model_name}.override {%override_list}

' 2. Creating scenario series
if @wcount(%override_list)>0 then
	for %ovar {%override_list}
		copy(o) {%ovar}_{%sub_salias_source} {%ovar}_csf
	next
endif

' 3. Adjusting forecast end
%forecast_end = st_tlast_scenarios

%exoglist = {%sub_model_name}.@exoglist(%sub_scenario_name)

if @wcount(%exoglist)>0 then
	for %evar {%exoglist}
		if @dtoo({%evar}.@last)<@dtoo(%forecast_end) then
			%forecast_end ={%evar}.@last
		endif
	next
endif

' 4. Creating forecasts
if @dtoo(%forecast_end)>@dtoo(st_tfirst_scenarios) then
	smpl 	{st_tfirst_scenarios} {%forecast_end} 
	{%sub_model_name}.solve
	
	%forecasts_not_available = "f"
else
	@uiprompt("Data for conditional forecast  for scenario " + %sub_salias_source + " are not avbailable")
	%forecasts_not_available = "t"
endif

' 5. Storing forecast
%endoglist = {%sub_model_name}.@endoglist(%sub_scenario_name)

for %var {%endoglist}
	
	%var = @replace(@upper(%var),"_CSF","")

	if @upper(%forecasts_not_available)="F" then
		copy(o) {%var}_csf {%var}_{%sub_salias}
		delete(noerr) {%var}_csf
	else
		copy(o) {%var} {%var}_{%sub_salias}
	endif
	
	{%var}_{%sub_salias}.displayname {%var} - Conditional scenario forecast - {%sub_salias_source}
next

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine shock_graphs(string %sub_include_original, string %sub_include_add, string %sub_transformation)

' 1. Creating list of comparison variables
call csf_graph_group(%sub_include_original,%sub_include_add,st_graph_add_scenarios)

'3. Creating graphs
call csf_graphs_create(%sub_transformation)

' 4. Adding legends, shading and grid
call csf_graphs_legend(%sub_include_original,%sub_include_add, %sub_transformation)

' 5. Storing and cleaning up

for %gp {%scenario_graph_list}
	copy(o) gp_csf_{%gp} gp_csf_{%gp}_{%scenario} 
next

delete(noerr) gr_scen_graph gp_csf_level gp_csf_trans

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine csf_graph_group(string %sub_include_original, string %sub_add_scenarios, string %sub_add_series)

%addional_graph_series = ""

if @isempty(%sub_add_series) = 0 then
	%addional_graph_series  = st_graph_add_scenarios

	for %cv {st_graph_add_scenarios}

		if @instr(@upper(%cv),"[CSF]")>0 then
			%cv_alias = "csf"+ %scenario
			%scenario_series = @replace(@upper(%cv),"[CSF]","") + "_" + %cv_alias		
		else
			%cv_alias = %scenario
			%scenario_series = %cv+ "_" + %cv_alias		
		endif

		if @isobject(%scenario_series) then
			%addional_graph_series  = @replace(@upper(%addional_graph_series),@upper(%cv),%scenario_series)	
		else
			if @isobject(%cv + "_" + %scenario) then
				%addional_graph_series  = @replace(@upper(%addional_graph_series),@upper(%cv),@upper(%cv) + "_" + %scenario)	
			endif
		endif
	next
'	for %scen_var {st_graph_add_scenarios}
'		%addional_graph_series  = 	%addional_graph_series  + %scen_var + "_" + %scenario + " "
'	next
endif

' 2. creating group of series to be graphed
%csf_included_series = st_base_var + "_csf" +  %scenario + " "

if @upper(%sub_include_original)="T" and @isobject(st_base_var +  "_" + %scenario) then
	%csf_included_series = %csf_included_series  + st_base_var +  "_" + %scenario + " "
endif

if @wcount(%sub_add_scenarios)>0 then
	for %add_s {%sub_add_scenarios}
		if @isobject( st_base_var +  "_" + %add_s) then		
			%csf_included_series = %csf_included_series  +  st_base_var +  "_" + %add_s + " "
		endif
	next
endif

group gr_scen_graph {%csf_included_series} {%addional_graph_series}

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine csf_graphs_create(string %sub_trasnformation)

' 1. Level graph

if @instr(@upper(st_exec_list),"SCENARIOS_LEVEL") then
	
	%graph_string = ""
	for !gs = 1 to gr_scen_graph.@count
		%gs = gr_scen_graph.@seriesname(!gs)
	
		if @upper(%sub_transformation)="INDEX" then
			%graph_string = %graph_string + %gs + "/" +	"@elem(" + %gs + + "," + %csf_base_q + ")*100" + " "
		else
			%graph_string = %graph_string + %gs + " "
		endif
	next	
	
	delete(noerr) gp_csf_level
	
	smpl {st_tfirst_sgraph} {st_tlast_scenarios}
	graph gp_csf_level.line  {%graph_string}
	
	gp_csf_level.addtext(t) Conditional {%scenario}  forecast
	gp_csf_level.setattr(heading) Conditional {%scenario}  forecast

endif

' 2.Transformation graphs

if @instr(@upper(st_exec_list),"SCENARIOS_TRANS") then
	
	' Period-change graph
	if @upper(%sub_transformation)<>"SPREAD" and @upper(%sub_transformation)<>"DEVIATION" then
		
		%graph_string = ""
		
		for !gs = 1 to gr_scen_graph.@count
			%gs = gr_scen_graph.@seriesname(!gs)
			
			if @upper(st_percentage_error)="T" then
				%graph_string = %graph_string + " " + "@pca(" + %gs + ")" 
			else
				%graph_string = %graph_string + " " + "@d(" + %gs + ")" 
			endif				
		next
		
		graph gp_csf_trans.line  {%graph_string} 	
	
		if @upper(st_percentage_error)="T" then
			gp_csf_trans.addtext(t) Conditional {%scenario}  forecast - Growth rate
			gp_csf_trans.setattr(heading) Conditional {%scenario}  forecast - Growth rate
		else
			gp_csf_trans.addtext(t) Conditional {%scenario}  forecast - Differences
			gp_csf_trans.setattr(heading) Conditional {%scenario}  forecast - Differences
		endif
	
	endif
	
	' Spread graph
	if @upper(%sub_transformation)="SPREAD"  then
	
		%graph_string = ""
		
		for !gs = 1 to gr_scen_graph.@count
			%gs = gr_scen_graph.@seriesname(!gs)
	
			%spread_benchmark_scen = st_spread_benchmark + "_" + %scenario
	
			%graph_string = %graph_string +" " + %gs + "-" + %spread_benchmark_scen
		next
		
		smpl {st_tfirst_sgraph} {st_tlast_scenarios}
		graph gp_csf_trans.line  {%graph_string} 
		gp_csf_trans.addtext(t) Conditional {%scenario}  forecast - Spread from {st_spread_benchmark}
		gp_csf_trans.setattr(heading) Conditional {%scenario}  forecast - Spread from {st_spread_benchmark}
	endif
	
	' Deviations from baseline graph
	if @upper(%sub_transformation)="DEVIATION" then
	
		%graph_string = ""
		
		for !gs = 1 to gr_scen_graph.@count
			%gs = gr_scen_graph.@seriesname(!gs)
	
			if @upper(st_percentage_error)="T" then
				%graph_string = %graph_string + " " + "(" + %gs + "/" + st_base_var + "_csf" + %baseline_alias + "-1" + ")*100" 
			else
				%graph_string = %graph_string + " " + %gs + "-" + st_base_var + "_csf" + %baseline_alias
			endif				
		next
		
		smpl {st_tfirst_sgraph} {st_tlast_scenarios}
		graph gp_csf_trans.line  {%graph_string} 	
	
		if @upper(st_percentage_error)="T" then
			gp_csf_trans.addtext(t) Conditional {%scenario}  forecast - Deviation from baseline
			gp_csf_trans.setattr(heading) Conditional {%scenario}  forecast - Deviation from baseline
		else
			gp_csf_trans.addtext(t) Conditional {%scenario}  forecast - Difference from baseline
			gp_csf_trans.setattr(heading) Conditional {%scenario}  forecast - Difference from baseline
		endif
	
	endif
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine csf_graphs_legend(string %sub_include_original, string %sub_add_scenarios, string %sub_transformation)

%scenario_graph_list = "" 

if @instr(@upper(st_exec_list),"SCENARIOS_LEVEL") then
	%scenario_graph_list = %scenario_graph_list + "level" + " "
endif

if @instr(@upper(st_exec_list),"SCENARIOS_TRANS") then
	%scenario_graph_list = %scenario_graph_list + "trans" + " "
endif

for %gp {%scenario_graph_list}

	!ecount = 1

	gp_csf_{%gp}.setelem(1) legend(Model scenario forecast) symbol(filledsquare) linepattern(solid)  linecolor(blue)

	if @upper(%sub_include_original)="T" and @isobject(st_base_var + "_" + %scenario) then	
		!ecount = !ecount + 1
		gp_csf_{%gp}.setelem(!ecount) legend(Original scenario forecast) linepattern(dash6) linecolor(orange)
	endif

	if @wcount(%sub_add_scenarios)>0 then
		for %add_s {%sub_add_scenarios}
			if @isobject( st_base_var +  "_" + %add_s) then		
				!ecount = !ecount + 1

				if @instr(@upper(%add_s),"CSF")>0 then
					if @replace(@upper(%add_s),"CSF","")=@upper(%baseline_alias) then
						%legend ="Model baseline  forecast"
						%pattern = "dash8"
						%color = "green"
					else
						%legend ="Model "+   @replace(@upper(%add_s),"CSF","") +  "  forecast"
						%pattern = "solid"
						%color = ""
					endif
				else
					%legend = "Original "+ %add_s + " forecast"
					%pattern = "solid"
					%color = ""
				endif

				if @isempty(%color) then
					gp_csf_{%gp}.setelem(!ecount) legend({%legend}) linepattern({%pattern})
				else
					gp_csf_{%gp}.setelem(!ecount) legend({%legend}) linepattern({%pattern}) linecolor({%color})
				endif
			endif
		next
	endif

	if @wcount(gp_csf_{%gp}.@members)>!ecount then
		for !e = !ecount+1 to @wcount(gp_csf_{%gp}.@members)
			gp_csf_{%gp}.setelem(!e) linepattern(solid)	
		next
	endif

	%shading_end = @otod(@dtoo(st_tfirst_scenarios)-1)
	gp_csf_{%gp}.draw(shade,bottom,color(219,219,219)) @first {%shading_end}
	gp_csf_{%gp}.options gridl

	gp_csf_{%gp}.options +linepat

next

endsub


' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine all_scenario_graphs(string %sub_scenario_forecast, string %sub_transformation)

' 1. Level graphs

if @instr(@upper(st_exec_list),"SCENARIOS_LEVEL") then

	group gr_all_scen_graph 
	
	for %scenario {st_scenarios}
		%scenario_series = @replace(@upper(%sub_scenario_forecast),"{S}",%scenario)
		gr_all_scen_graph.add {%scenario_series}
	next
	
	smpl {st_tfirst_sgraph} {st_tlast_scenarios}  
	graph gp_csf_level_all.line gr_all_scen_graph
	
	!elem = 0
	for %s {st_scenarios}
		!elem = !elem +1
		gp_csf_level_all.setelem(!elem) legend(Model {%s} forecast)
	next
	
	gp_csf_level_all.addtext(t) Conditional scenario forecasts
	gp_csf_level_all.setattr(heading) Conditional scenario forecasts

	delete(noerr) gr_all_scen_graph

endif

' 2.Transformation graphs

if @instr(@upper(st_exec_list),"SCENARIOS_TRANS") then
	
	' Q/Q graph string
	if @upper(%sub_transformation)<>"SPREAD" and @upper(%sub_transformation)<>"DEVIATION" then
		
		%graph_string = ""
	
		for %scenario {st_scenarios}
			%gs = @replace(@upper(%sub_scenario_forecast),"{S}",%scenario)
	
			if @upper(st_percentage_error)="T" then
				%graph_string = %graph_string + " " + "@pca(" + %gs + ")" 
			else
				%graph_string = %graph_string + " " + "@d(" + %gs + ")" 
			endif
		next
	endif
	
	
	' Spread graph string
	if @upper(%sub_transformation)="SPREAD"  then
		
		%graph_string = ""
		
		for %scenario {%model_baseline_alias} {st_scenarios}
			%gs = @replace(@upper(%sub_scenario_forecast),"{S}",%scenario)
	
			st_spread_benchmark_scen = st_spread_benchmark + "_" + %scenario
	
			%graph_string = %graph_string +" " + %gs + "-" + st_spread_benchmark_scen
		next
	endif
	
	' Devaitions from baseline graph string 
	if @upper(%sub_transformation)="DEVIATION" then
		
	
		%graph_string = ""
	
		%model_baseline_series =  @replace(@upper(%sub_scenario_forecast),"{S}",%baseline_alias)
	
		for %scenario {st_scenarios}
			%gs = @replace(@upper(%sub_scenario_forecast),"{S}",%scenario)
	
			if @upper(st_percentage_error)="T" then
				%graph_string = %graph_string + " " + "(" + %gs + "/" + %model_baseline_series + "-1" + ")*100" 
			else
				%graph_string = %graph_string + " " + %gs + "-" + %model_baseline_series
			endif
		next
	endif
	
	' Creating graph
	graph gp_csf_trans_all.line  {%graph_string} 
	
	' Adding legend
	if @upper(%sub_transformation)<>"DEVIATION" then
		!elem = 0
		for %s {st_scenarios}
			!elem = !elem +1
			gp_csf_trans_all.setelem(!elem) legend(Model {%s} forecast)
		next
	else
		
		!elem = 0
		for !s=2 to @wcount(st_scenarios)
			%s = @word(st_scenarios,!s)	
			!elem = !elem +1
			gp_csf_trans_all.setelem(!elem) legend(Model {%s} forecast)
		next
	endif
	
	' Adding description text
	if @upper(%sub_transformation)<>"SPREAD" and @upper(%sub_transformation)<>"DEVIATION" then
		if @upper(st_percentage_error)="T" then
			gp_csf_trans_all.addtext(t) Conditional scenario forecasts - Growth rate
			gp_csf_trans_all.setattr(heading) Conditional scenario forecasts - Growth rate
		else
			gp_csf_trans_all.addtext(t) Conditional scenario forecasts - Differences
			gp_csf_trans_all.setattr(heading) Conditional scenario forecasts - Differences
		endif
	endif
	
	if @upper(%sub_transformation)="SPREAD"  then
		gp_csf_trans_all.addtext(t) Conditional scenario forecasts - Spread from {st_spread_benchmark}
	endif
	
	if @upper(%sub_transformation)="DEVIATION" then
		if @upper(st_percentage_error)="T" then
			gp_csf_trans_all.addtext(t) Conditional scenario  forecast - Deviation from baseline
			gp_csf_trans_all.setattr(heading) Conditional scenario  forecast - Deviation from baseline
		else
			gp_csf_trans_all.addtext(t) Conditional scenario  forecast - Difference from baseline
			gp_csf_trans_all.setattr(heading) Conditional scenario  forecast - Difference from baseline	
		endif
	endif
endif

endsub

' ##################################################################################################################




' ##################################################################################################################

subroutine evaluation_report

'1. Creating spool
delete(noerr) sp_spec_evaluation
spool sp_spec_evaluation

' 2.  Regression output
if @instr(@upper(st_exec_list),"REG_OUTPUT") and {st_spec_name}.@type<>"STRING" then
	call regression_output_adjusted(st_spec_name)
	sp_spec_evaluation.insert(name=regression_output) tb_reg_output

	%obj_name =  "Regression output"
	%obj_desc = "- Coefficients: blue=negative; orange=positive \n - Tstats/pvals: green=significant,red=insignificant,yellow=marginally significant"  
	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	sp_spec_evaluation.comment regression_output %comment

	%intermediate_objects = %intermediate_objects +  " " + "tb_reg_output"  + " "
endif

' 3. Coefficient stability
if @upper(st_outofsample)="T" and @instr(@upper(st_exec_list),"STABILITY") then

	call coefficient_stability

	if @isobject("gp_coef_stability") then
		sp_spec_evaluation.insert(name=coefficient_stability) gp_coef_stability
		
		%obj_name =  "Coefficient stability graphs" 
		%obj_desc = "- Coefficients based on increasing estimation sample with 2 standard deviation error bands"  
		call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
 		sp_spec_evaluation.comment coefficient_stability %comment
	endif	
endif	

'3. Auto orders
if @upper(st_outofsample)="T" and @instr(@upper(st_exec_list),"STABILITY") then

	call auto_orders

	if @isobject("gp_lag_orders") then
		sp_spec_evaluation.insert(name=Lag_orders) gp_lag_orders
		
		%obj_name =  "Automatically selected lag orders" 
		%obj_desc = "- Automatically selected number of lags " 
		if @upper(st_auto_type) = "ARMA" then
			%obj_desc = %obj_desc + "of autoregressive and moving average components "
		endif
		if @upper(st_auto_type) = "ARDL" then
			%obj_desc = %obj_desc + "of dependent and independet variables "
		endif
		%obj_desc = %obj_desc + "corresponding to different estimation samples (dates indicate end of estiamtion sample)"
		call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
 		sp_spec_evaluation.comment Lag_orders %comment
	endif	
endif	

' 4. Performance metrics
if @instr(@upper(st_exec_list),"METRICS") then
	sp_spec_evaluation.insert(name=forecast_metrics) tb_performance_metrics

	%obj_name =  "Forecast performance metrics" 
	%obj_desc = "- Forecast metric based on all available forecast errors at given horizon \n - #=number of forecasts \n - Last column=average across horizons - \n - Sub-samples include only forecast that completely lie in given sub-sample"  
	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	sp_spec_evaluation.comment forecast_metrics %comment

endif

' 3. Forecast graphs

' Forecast summary graphs
if @instr(@upper(st_exec_list),"GRAPHS_SUMMARY") then

	%h_include_list = ""

	for !h = 1 to sc_graph_horizons_n
		
		%h = @word(st_graph_horizons,!h)

		if @isobject("gp_forecasts_all_h" + %h) then
			sp_spec_evaluation.insert(name=f_h{%h}) gp_forecasts_all_h{%h}
			%h_include_list = %h_include_list + %h + " "		
		endif
	next

	%obj_name =  "All forecast graphs" 
	%obj_desc = "- blue with squares = actual historical series \n - dashed without symbol = individual forecasts \n - other solid = user-included series"  
	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	%first_graph = "f_h" + @word(%h_include_list,1)
	sp_spec_evaluation.comment {%first_graph}  %comment
endif

	
' Subsample graphs
if @instr(@upper(st_exec_list),"GRAPHS_SS") then

	%ss_include_list = ""

	for !SubSample = 1 to sc_subsample_count	
		%ss_name = "F_" + @mid(st_subsample{!SubSample}_start,3)+"_" + @mid(st_subsample{!SubSample}_end,3)
		
		if @isobject("gp_forecast_SubSample"+ @str(!SubSample)) then
			sp_spec_evaluation.insert(name={%ss_name}) gp_forecast_SubSample{!SubSample}
			%ss_include_list = %ss_name + " "
		endif

		if @isobject("gp_subsample"+ @str(!SubSample) + "_fd") then
			sp_spec_evaluation.insert(name={%ss_name}_decomposition) gp_subsample{!subsample}_fd
		endif
	next	

	%obj_name = " Subsample forecast graphs" 
	%obj_desc = "- blue with squares = actual historical series \n - orange without symbol = forecast \n - other solid = user-included series"  

	if @instr(@upper(st_exec_list),"DECOMPOSITION") then
		%obj_desc = %obj_desc + " \n \n SUBSAMPLE FORECAST DECOMPOSITION GRAPHS \n - Blue with squares = Dependent variable  (in transformation) \n - other lines = individual drivers (regressors in transformation multipled by coefficients)" 
	endif

	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	%first_graph = @word(%ss_include_list,1)
	sp_spec_evaluation.comment  {%first_graph} %comment

endif

' 4. Bias graphs

if @instr(@upper(st_exec_list),"GRAPHS_BIAS") then
	%h_include_list = ""

	for !h = 1 to sc_bias_horizons_n
		
		%h = @word(st_bias_horizons,!h)
	
		if @isobject("gp_forecasts_all_h" + %h) then
			sp_spec_evaluation.insert(name=bias_h{%h}) gp_forecast_bias_h{%h}
			%h_include_list = %h_include_list + %h + " "
		endif
	next

	%obj_name =  "Forecast bias graphs" 
	%obj_desc = "- points=actual vs. forecast value \n - orange line = linear fit \n - dashed line = 45-degree line"  
	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	%first_graph = "bias_h" + @word(%h_include_list,1)
	sp_spec_evaluation.comment {%first_graph}  %comment

endif

' 5. Conditional scenario graphs
if @instr(@upper(st_exec_list),"SCENARIOS_INDIVIDUAL") then

	%s_include_list = ""

	for %s {st_scenarios}	

		if @instr(@upper(st_exec_list),"SCENARIOS_LEVEL") then
			sp_spec_evaluation.insert(name={%s}_level) gp_csf_level_{%s}
			%s_include_list = %s_include_list + %s + "_level" + " "
		endif

		if @instr(@upper(st_exec_list),"SCENARIOS_TRANS") then
			sp_spec_evaluation.insert(name={%s}_transformation) gp_csf_trans_{%s}
			%s_include_list = %s_include_list + %s + "_transformation" + " "
		endif
	next

	%obj_name =  "Individual conditional scenario forecast graphs" 
	%obj_desc = "- blue with squares = scenario forecast based on given specification \n - orange with dash = original scenario forecast taken from workfile \n - green with dash-dot   = baseline scenario forecast based on given specification \n - other solid = user-included series \n - (model foreast = forecast based on given specification and workfile values of RHS variables; original forecast = scenario forecast taken from workfile)"  
	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	%first_graph = @word(%s_include_list,1)
	sp_spec_evaluation.comment {%first_graph}  %comment

endif

if @instr(@upper(st_exec_list),"SCENARIOS_ALL") then

	%s_include_list = ""

	if @instr(@upper(st_exec_list),"SCENARIOS_LEVEL") then
		sp_spec_evaluation.insert(name=all_level) gp_csf_level_all
		%s_include_list = %s_include_list + "all_level" + " "
	endif

	if @instr(@upper(st_exec_list),"SCENARIOS_TRANS") then
		sp_spec_evaluation.insert(name=all_transformation) gp_csf_trans_all
		%s_include_list = %s_include_list + "all_transformation" + " "
	endif

	%obj_name =  "All conditional scenario forecast graphs" 
	%obj_desc = "- Model scenario forecast (= forecast based on given specification and workfile values of RHS variables) for all scenarios "  
	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	%first_graph = @word(%s_include_list,1)
	sp_spec_evaluation.comment {%first_graph}  %comment

endif

if @instr(@upper(st_exec_list),"DECOMPOSITION") and @wcount(st_scenarios)>1 then

	%s_include_list = ""

	for %s {st_scenarios}

		if @isobject("gp_csf_fd_"+ %s) then
			sp_spec_evaluation.insert(name={%s}_decomposition) gp_csf_fd_{%s}
			%s_include_list = %s_include_list + %s + "_decomposition" + " "
		endif

		if @isobject("gp_csf_fdd_"+ %s) then
			sp_spec_evaluation.insert(name={%s}_decomposition_diff)  gp_csf_fdd_{%s}
			%s_include_list = %s_include_list + %s + "_decomposition_diff" + " "
		endif
	next


	%obj_name =  "Scenario forecast decomposition graphs" 
	%obj_desc = "- Blue with squares = Conditional scenario forecast for dependent variable (in transformation)  \n - other lines = individual scenario drivers (regressors scenario values in transformation multipled by coefficients)"

	if @wcount(st_scenarios)>1 then
		%obj_desc = %obj_desc + "\n \n Scenario forecast decomposition graphs - Difference from baseline \n - Difference between scenario forecast drivers and baseline scenario drivers"	
	endif

	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	%first_graph = @word(%s_include_list,1)

	if @wcount(%s_include_list)>0 then
		sp_spec_evaluation.comment {%first_graph}  %comment
	endif

endif

endsub


' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine comment_string(string %sub_title, string %sub_desc,string %sub_include_eq_info ,string %sub_use_names,string %sub_include_desc)

%comment = @upper(%sub_title)

if @upper(%sub_include_eq_info)="T" then
	if @upper(%sub_use_names)="T" then
		%comment = %comment  + " for " st_spec_name
	else
		%comment = %comment + " for specification " +  st_alias
	endif
endif

if @upper(%sub_include_desc)="T" then
	%comment = %comment + " \n " + %sub_desc
endif

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine regression_output_adjusted(string %sub_equation_name)
	
' 1. Obtaining regression results
delete(noerr) tb_reg_output
freeze(tb_reg_output) {%sub_equation_name}.results	

' 2. Color coding regression results table

' Identifying starting row
!start_row = 10
for !r = 1 to tb_reg_output.@rows
	'for !c = 1 to  tb_reg_output.@cols
		if @upper(tb_reg_output(!r,2))="COEFFICIENT" then
			!start_row = !r+2	
			exitloop
		endif
	'next
next

' Identifying p-value column
!pvalue_column = 5
for !c = 1 to  tb_reg_output.@cols
	if @instr(@upper(tb_reg_output(!start_row-2,!c)),"PROB")>0 then
		!pvalue_column = !c
		exitloop
	endif
next

' Color coding
for !reg = 1 to {%sub_equation_name}.@ncoef
	if @val(tb_reg_output(!start_row+!reg-1,!pvalue_column))<0.1 then
		tb_reg_output.setfillcolor(!start_row+!reg-1,!pvalue_column) green
		tb_reg_output.setfillcolor(!start_row+!reg-1,!pvalue_column-1) green
	endif

	if @val(tb_reg_output(!start_row+!reg-1,!pvalue_column))>0.1 and @val(tb_reg_output(!start_row+!reg-1,!pvalue_column))<0.25 then
		tb_reg_output.setfillcolor(!start_row+!reg-1,!pvalue_column) yellow
		tb_reg_output.setfillcolor(!start_row+!reg-1,!pvalue_column-1) yellow
	endif

	if @val(tb_reg_output(!start_row+!reg-1,!pvalue_column))>0.25 then
		tb_reg_output.setfillcolor(!start_row+!reg-1,!pvalue_column) red
		tb_reg_output.setfillcolor(!start_row+!reg-1,!pvalue_column-1) red
	endif


	if @val(tb_reg_output(!start_row+!reg-1,2))>0 then
		tb_reg_output.setfillcolor(!start_row+!reg-1,2) @rgb(255,128,0)
		tb_reg_output.setfillcolor(!start_row+!reg-1,2) @rgb(255,128,0)
	else
		tb_reg_output.setfillcolor(!start_row+!reg-1,2) @rgb(0,255,255)
		tb_reg_output.setfillcolor(!start_row+!reg-1,2) @rgb(0,255,255)
	endif
next

' 3. Adding standardize coefs
if {%sub_equation_name}.@type="EQUATION" then
	call standardized_coefs_manual(%sub_equation_name)
endif

' 4. Setting coefficient numerical format
for !reg = 1 to  {%sub_equation_name}.@ncoef
	for %tc 2 3 4 6
		
		!tc = {%tc}
		
		!value = @val(tb_reg_output(!start_row+!reg-1,!tc))
		
		if @abs(!value)<1 then
			tb_reg_output.setformat(!start_row+!reg-1,!tc) "g.2"
		else
			tb_reg_output.setformat(!start_row+!reg-1,!tc) "f.2"
		endif
	next
next

' 5. Adjuting column length
!max_length = 20
for !reg = 1 to {%sub_equation_name}.@ncoef
	!length = @length(tb_reg_output(!start_row+!reg-1,1))
	if !length>!max_length then
		!max_length= !length
	endif
next

tb_reg_output.setwidth(1) !max_length

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine standardized_coefs_manual(string %sub_equation_name)
	
if @isobject("st_estimation_sample")=0 then
	call estimation_boundaries(%sub_equation_name,"")
endif

tb_reg_output.setlines(!start_row-1,!pvalue_column+1) +d
tb_reg_output.setlines(!start_row-3,!pvalue_column+1) +d
tb_reg_output.setlines(!start_row++ {%sub_equation_name}.@ncoef,!pvalue_column+1) +d
tb_reg_output(!start_row-2,!pvalue_column+1) = "Std. coef."

smpl @all
%DepVar = @word({%sub_equation_name}.@varlist,1)
series s_depvar = {%DepVar}

for !reg = 1 to {%sub_equation_name}.@ncoef	
	
	%reg = tb_reg_output(!start_row+!reg-1,1)

	if @upper(%reg)<>"C" and  @instr(@upper(" " + %reg)," AR(")=0 and @instr(@upper(" " + %reg)," MA(")=0 and @instr(@upper(" " + %reg)," PDL(")=0  and @upper(%reg)<>"SIGMASQ" and @instr(@upper(" " + %reg)," C(")=0  then
	
		' Calculating
		series s_reg = {%reg}

		smpl {st_estimation_sample}
		tb_reg_output(!start_row+!reg-1,!pvalue_column+1)= {%sub_equation_name}.@coef(!reg)*@stdev(s_reg)/@stdev(s_DepVar)

		' Color coding
		if @abs(@val(tb_reg_output(!start_row+!reg-1,!pvalue_column+1)))>0.5 then
			tb_reg_output.setfillcolor(!start_row+!reg-1,!pvalue_column+1) green
		endif

		if @abs(@val(tb_reg_output(!start_row+!reg-1,!pvalue_column+1)))<0.5 and @abs(@val(tb_reg_output(!start_row+!reg-1,!pvalue_column+1)))>0.1 then
			tb_reg_output.setfillcolor(!start_row+!reg-1,!pvalue_column+1) yellow
		endif

		if @abs(@val(tb_reg_output(!start_row+!reg-1,!pvalue_column+1)))<0.1 then
			tb_reg_output.setfillcolor(!start_row+!reg-1,!pvalue_column+1) red
		endif
	endif
next	

delete(noerr) s_depvar s_reg	

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine coefficient_stability

delete(noerr) gp_coefs

if @upper(st_auto_selection)<>"T" then
		
	' Original equation estimation list
	'freeze(tb_rr_full_sample) {st_spec_name}.results
	
	%eq_varlist = {st_spec_name}.@spec

	' Series of coefficients and standard errors
	call coefficient_stability_series(%eq_varlist)
	
	' Creatin graph
	call coefficient_stability_graph("t")	
	
	' Creating table
	' TBA
	
else
	
	%command = {st_spec_name}.@command
	
	if @upper(st_auto_type) = "ARDL" then
		
		' Getting full list of potential regressors
		call ardl_eq_varlist_full
				
		' Series of coefficients and standard errors
		call coefficient_stability_series(%eq_varlist)
	
		' Creatin graph
		call coefficient_stability_graph("f")	

	endif
	
	if @upper(st_auto_type) = "ARMA" then
		
	
		' Getting full list of potential regressors
		call arma_eq_varlist_full	
		
		' Series of coefficients and standard errors
		call coefficient_stability_series(%eq_varlist)	
		
			
		' Creatin graph
		call coefficient_stability_graph("f")		

				
	endif
endif

delete(noerr) tb_temp

endsub 

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine coefficient_stability_series(string %sub_varlist)

!coef_n = @wcount(%sub_varlist)-1

for !coef = 1 to 	!coef_n
	series s_coefs{!coef} = na
	series s_serrors{!coef} = na
next
	
for !fp = 1  to sc_forecastp_n		
	
	delete(noerr) tb_temp
	freeze(tb_temp) {st_spec_name}_reest{!fp}.results
	
	for !coef = 1 to !coef_n
		%reg = @upper(@word(%sub_varlist,!coef+1))

		!coef_value = na
		!serror_value = na

		for !tr = 1 to tb_temp.@rows
			if @upper(tb_temp(!tr,1))=@upper(%reg) then
				!coef_value = @val(tb_temp(!tr,2)) 
				!serror_value = @val(tb_temp(!tr,3))
				
				smpl {st_tfirst_backtest}+!fp-1 {st_tfirst_backtest}+!fp-1
				s_coefs{!coef} = !coef_value
				s_serrors{!coef} = !serror_value
				exitloop	
			endif
		next
	next	
next

for !coef = 1 to !coef_n
	%intermediate_objects = %intermediate_objects +  "s_coefs" + @str(!coef)   + " " + "s_serrors" + @str(!coef)   + " "
next
	
endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine coefficient_stability_graph(string %sub_include_fs)
	
!coef_stability_shift = 12

%graph_merge_string = ""

for !coef = 1 to !coef_n
	
	if s_coefs{!coef}.@obs>0 then
		smpl {st_tfirst_backtest} {st_tlast_backtest}
		series s_up_bound = s_coefs{!coef}+2*s_serrors{!coef}
		series s_down_bound = s_coefs{!coef}-2*s_serrors{!coef}
				
		delete(noerr) gp_coefs{!coef}
	
		'Creating graph
		smpl {st_tfirst_backtest}+!coef_stability_shift {st_tlast_backtest}
		graph gp_coefs{!coef}.errbar s_up_bound  s_down_bound s_coefs{!coef}

		'Adjusting range
		
		
		' Adding full sample coefficient
		if  {st_spec_name}.@ncoef>=!coef and @upper(%sub_include_fs)="T" then
			!full_sample_coef = {st_spec_name}.@coef(!coef)
			gp_coefs{!coef}.draw(line,left,pattern(7)) {!full_sample_coef} 
		endif
					
		' Setting legend	
		%reg_name = @word(%eq_varlist,!coef+1)
		gp_coefs{!coef}.addtext(t) Coefficeint stability for {%reg_name}

		' Adding zero line
		if (gp_coefs{!coef}.@axismax("l")>0 and gp_coefs{!coef}.@axismin("l")<0) then
			gp_coefs{!coef}.draw(left,line,pattern(solid),color(red),width(1)) 0
		endif
	
		'Creating merge string
		%graph_merge_string = %graph_merge_string + "gp_coefs" + @str(!coef) + " "
				
		delete(noerr) s_up_bound s_down_bound
	endif
next

delete(noerr) gp_coef_stability

if @wcount(%graph_merge_string)>1 then
	graph gp_coef_stability.merge {%graph_merge_string}
	gp_coef_stability.align(3,1,1)
else
	if @isobject("gp_coefs") then
		copy gp_coefs1 gp_coef_stability
	endif
endif

if @isobject("gp_coef_stability") then
	if @upper(st_use_names)="T" then
		gp_coef_stability.addtext(t) Coefficient stability graphs for {st_spec_name}
		gp_coef_stability.setattr("desc") Coefficient stability graphs for {st_spec_name}
	else
		gp_coef_stability.addtext(t) Coefficient stability graphs for specification {st_alias}
		gp_coef_stability.setattr("desc") Coefficient stability graphs for specification {st_alias}
	endif

	gp_coef_stability.addtext(b) Circles: Recursive coefficient estimates \r Dahsed line: Full sample coefficient \r Blue lines: Confidence interval

	%intermediate_objects = %intermediate_objects + "gp_coef_stability" + " "
endif

for !coef = 1 to !coef_n
	delete(noerr) gp_coefs{!coef}
next

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine ardl_eq_varlist_full

if @isobject("gr_"+ st_spec_name + "_regs")=0 then
	{st_spec_name}.makeregs gr_{st_spec_name}_regs
endif

%depvar = gr_{st_spec_name}_regs.@seriesname(1)

smpl @all
%regs = gr_{st_spec_name}_regs.@members
%regs = @replace(@upper(%regs),@upper(%depvar),"")

!reg_n = @wcount(%regs)

%eq_varlist = "s_depvar"

for !reg = 1 to !reg_n	
	%reg = @word(%regs,!reg)
	%eq_varlist = %eq_varlist   + " " + "s_reg" + @str(!reg)
next

if @instr(@upper(%command),"TREND=NONE")=0 then
	%eq_varlist = %eq_varlist +  " " + "C"
endif

!first_lag = @wcount(%eq_varlist)
		
for !dl = 1 to sc_deplags
	%eq_varlist = %eq_varlist + " " + "s_depvar" +  "(-" + @str(!dl) + ")"
next

for !reg = 1 to !reg_n				
	for !rl = 1 to sc_reglags
		%eq_varlist = %eq_varlist+ " " + "s_reg"+ @str(!reg) +  "(-" + @str(!rl) + ")"
	next
next
		
endsub


' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine arma_eq_varlist_full

%depvar = gr_{st_spec_name}_regs.@seriesname(1)

smpl @all
%regs = gr_{st_spec_name}_regs.@members
%regs = @replace(@upper(%regs),@upper(%depvar),"")

!reg_n = @wcount(%regs)

!first_lag = !reg_n +1+1

%eq_varlist = %depvar + " " + " c " + %regs

for !l = 1 to sc_maxar
	%eq_varlist = %eq_varlist + " " + "ar" +  "(" + @str(!l) + ")"
next

for !l = 1 to sc_maxma
	%eq_varlist = %eq_varlist + " " + "ma" +  "(" + @str(!l) + ")"
next

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine auto_orders

if @upper(st_auto_type) = "ARDL" then
	call ardl_order_graph
endif

if @upper(st_auto_type) = "ARMA" then
	call arma_order_graph
endif

if @upper(st_auto_type) = "VAR" then
	smpl {st_tfirst_backtest}   {st_tlast_backtest}
	graph gp_lag_orders.line s_laglength
endif

%intermediate_objects = %intermediate_objects + "gp_lag_orders" + " "

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine ardl_order_graph
	
smpl @all	
series s_deplags = na

for !reg = 1 to !reg_n	
	smpl @all	
	series s_reglags{!reg} = na
next

if sc_deplags>0 then
	group gr_deplag_coefs
	
	for !lag = 1 to sc_deplags
		!coef = !first_lag+!lag-1
		
		gr_deplag_coefs.add s_coefs{!coef}				
	next			
endif

if sc_reglags>0 then
	for !reg = 1 to !reg_n	
		group gr_reglag_coefs{!reg}
		
		for !lag = 1 to sc_reglags
			!coef = !first_lag+!lag-1+sc_deplags+sc_reglags*(!reg-1)
			gr_reglag_coefs{!reg}.add s_coefs{!coef}	
		next				
	next			
endif

%graph_string = "" 
if sc_deplags>0 then
	smpl {st_tfirst_backtest} {st_tlast_backtest}
	s_deplags = @robs(gr_deplag_coefs)
	%graph_string = %graph_string + "s_deplags" + " "
	
	%intermediate_objects = %intermediate_objects +  "s_deplags gr_deplag_coefs"  + " "
endif

if sc_reglags>0 then
	for !reg = 1 to !reg_n			
		smpl {st_tfirst_backtest} {st_tlast_backtest}		
		 s_reglags{!reg} = @robs(gr_reglag_coefs{!reg})
		 %graph_string = %graph_string + "s_reglags" + @str(!reg) + " "
		 
		 %intermediate_objects = %intermediate_objects +  "s_reglags" + @str(!reg) +  " "+  "gr_relag_coef" + @str(!reg)  + " "
	next
endif

%symbol_list = "circle square star  triup cross tridown disagcross"

smpl {st_tfirst_backtest} {st_tlast_backtest} 
graph gp_lag_orders.line {%graph_string}
gp_lag_orders.setelem(1) legend(Dependent variable lags) linepattern(dash6) symbol(filledsquare)

for !reg = 1 to !reg_n			
	!e = !reg+(sc_deplags>0)		
	%sym = @word(%symbol_list,!reg)
	
	gp_lag_orders.setelem(!e) legend(Regressor {!reg} lags) symbol({%sym})
next

%intermediate_objects = %intermediate_objects + "gp_lag_orders" + " "

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine arma_order_graph
	
smpl @all	
series s_arlags = na

smpl @all	
series s_malags = na

if sc_maxar>0 then
	group gr_arlag_coefs
	
	for !lag = 1 to sc_maxar
		!coef = !first_lag+!lag-1
		gr_arlag_coefs.add s_coefs{!coef}				
	next			
endif

if sc_maxma>0 then
	group gr_malag_coefs
	
	for !lag = 1 to sc_maxar
		!coef = !first_lag+sc_maxar+!lag-1
		gr_malag_coefs.add s_coefs{!coef}				
	next			
endif

%graph_string = "" 
if sc_maxar>0 then
	smpl {st_tfirst_backtest} {st_tlast_backtest}
	s_arlags = @robs(gr_arlag_coefs)
	%graph_string = %graph_string + "s_arlags" + " "
	
	%intermediate_objects = %intermediate_objects +  "s_arlags gr_arlag_coefs"  + " "
endif

if sc_maxma>0 then
	smpl {st_tfirst_backtest} {st_tlast_backtest}
	s_malags = @robs(gr_malag_coefs)
	%graph_string = %graph_string + "s_malags" + " "
	
	%intermediate_objects = %intermediate_objects +  "s_malags gr_malag_coefs"  + " "
endif


smpl {st_tfirst_backtest} {st_tlast_backtest} 
graph gp_lag_orders.line {%graph_string}

!e = 0
if sc_maxar>0 then
	!e = !e+1
	gp_lag_orders.setelem(!e) legend(AR lags) symbol(square) symbolsize(large)
endif

if sc_maxar>0 then
	!e = !e+ 1
	gp_lag_orders.setelem(!e) legend(MA lags) symbol(circle) symbolsize(small)
endif

%intermediate_objects = %intermediate_objects + "gp_lag_orders" + " "

endsub

' ##################################################################################################################




' ##################################################################################################################

subroutine results_aliasing(string %sub_alias)

' Creating object list
if sc_spec_count>1 then
	%object_list = "sp_spec_evaluation tb_performance_metrics tb_reg_output"
else
	%object_list = ""
endif

for !fh = 1 to sc_graph_horizons_n
	%fh = @word(st_graph_horizons,!fh)
	%object_list = %object_list + " " + "gp_forecasts_all_h" + %fh
next

for !ss = 1 to sc_subsample_count
	%object_list = %object_list  + " " +  "gp_forecast_subsample" + @str(!ss) + " " + "gp_subsample"+ @str(!ss)  + "_fd"
next

for !fh = 1 to sc_bias_horizons_n
	%fh = @word(st_bias_horizons,!fh)
	%object_list = %object_list + " " + "gp_forecast_bias_h" + %fh
	%object_list = %object_list + " " + "m_fb_h" + %fh
next
if @isempty(st_scenarios)=0 then
	for %s {st_scenarios}
		%object_list = %object_list + " " + "gp_csf_level_"	+ %s + " " + "gp_csf_trans_"	+ %s + " "+  "gp_csf_fd_" + %s  + " "+  "gp_csf_fdd_" + %s  
	next

	%object_list = %object_list + " " + "gp_csf_level_all gp_csf_trans_all "
endif

%object_list = %object_list + " " + "tb_reg_output gp_coef_stability gp_lag_orders gp_lag_orders gp_var_lags"

if @upper(st_keep_objects)="T" then
	%object_list = %object_list + " " + %intermediate_objects
endif

if @upper(st_keep_forecasts)="T" then				
	for !fp = 1 to sc_forecastp_n
		%fstart = @otod(@dtoo(st_tfirst_backtest)+!fp-1)
		%object_list = %object_list +" " +st_base_var + "_f" + %fstart
	next

	if @isempty(st_scenarios)=0 then
		for %s {st_scenarios}
			%object_list = %object_list +" "  + st_base_var + "_csf" + %s
		next
	endif
endif

if @upper(st_keep_information)="T" then
	%object_list = %object_list + " " + "st_estimation_sample st_tfirst_estimation st_tlast_estimation st_tfirst_backtest st_tlast_backtest tb_forecast_numbers tb_sb_eq_ardl_d_dr_aic sc_forecastp_n sc_backtest_start_shift st_auto_info sp_var_model_selection s_laglength"	
endif

'string st_object_list = %object_list

' Creating aliased objects
for %obj {%object_list}
	
	if @instr(@upper(%obj),"*")>0 then
		delete(noerr) {%obj} {%obj}_{%sub_alias}
		rename {%obj} {%obj}_{%sub_alias}
	else
		if @isobject(%obj) then
			delete(noerr) {%obj}_{%sub_alias}		
			rename {%obj} {%obj}_{%sub_alias}
		endif
	endif	
next

'if @upper(st_keep_information)="T" then
'	copy sc_forecastp_n_{%sub_alias} sc_forecastp_n
'	copy st_tfirst_backtest_{%sub_alias} st_tfirst_backtest
'	'copy st_percentage_error_{%sub_alias} st_percentage_error
'endif

endsub

' ##################################################################################################################




' ##################################################################################################################

subroutine cleaning_up_objects

' 1. Cleaning up intermediate objects
if @upper(st_keep_objects)="F" then
	delete(noerr) {%intermediate_objects}
endif

' 2. Cleaning up forecasts
if @upper(st_keep_forecasts)="F" then				
	for !fp = 1 to @obsrange
		%fstart = @otod(!fp)
		delete(noerr) {st_base_var}_f{%fstart}
	next

	if @isempty(st_scenarios)=0 then
		for %s {st_scenarios}
			delete(noerr) {st_base_var}_csf{%s}
		next
	endif
endif

' 3. Cleaning up equations
if @upper(st_keep_equations)="F" then				
	for !fp = 1 to @obsrange
		delete(noerr) {st_spec_name}_reest{!fp}
	next
endif	


' 3. Cleaning up process information objects
if @upper(st_keep_information)="F" then
	delete(noerr) st_estimation_sample st_tfirst_estimation st_tlast_estimation st_tfirst_backtest st_tlast_backtest tb_forecast_numbers tb_sb_{st_spec_name} sc_forecastp_n sc_backtest_start_shift st_exog_variables st_auto_type  st_auto_info sc_maxlag sp_var_model_selection s_laglength
	
	if @isobject("st_eq_list_add_final") then
		for %eq {st_eq_list_add_final}
			delete(noerr) tb_sb_{%eq} 		
		next
	endif
	
	if  !spec_id=sc_spec_count then
		delete(noerr) st_percentage_error
	endif
endif

' 4. Cleaning up other objects
if @upper(st_keep_objects)="F" and sc_spec_count=1 then
	for %h {st_graph_horizons}
		delete(noerr) gp_forecasts_all_h{%h}
	next

	for %h {st_bias_horizons}
		delete(noerr) gp_forecast_bias_h{%h}
	next

	for !ss = 1 to sc_subsample_count
		delete(noerr) gp_forecast_subsample{!ss}
	next	

	if @isempty(st_scenarios)=0 then
		for %s {st_scenarios} all
			delete(noerr) gp_csf_*_{%s}
		next
	endif
	 	
	delete(noerr)   tb_performance_metrics
endif

delete(noerr) gr_regs s_history_series

if @isobject("st_spec_name") then
	delete(noerr) gr_{st_spec_name}_regs
endif 

' Restoring
if @upper(%restore_auto_selection)="T" then
	st_auto_selection = "T"
endif
 
endsub

' ##################################################################################################################




' ##################################################################################################################

subroutine evaluation_multireport

' 1. Individual reports aggregated
delete(noerr) sp_spec_evaluation_specs
spool sp_spec_evaluation_specs

for !spec_id = 1 to sc_spec_count

	call spec_alias

	sp_spec_evaluation_specs.insert(name=spec_{st_alias}) sp_spec_evaluation_{st_alias}	
next
	 
' 2. Cross-equation performance report

delete(noerr) sp_spec_evaluation
spool sp_spec_evaluation

'2.1 Regression outputs
if @instr(@upper(st_exec_list),"REG_OUTPUT") then

	delete(noerr) sp_outputs
	spool sp_outputs
	
	call insert_specs("sp_outputs","tb_reg_output", st_use_names)	

	sp_spec_evaluation.insert(name=regression_outputs) sp_outputs
	delete(noerr) sp_outputs

	%obj_name =  "Regression outputs"
	%obj_desc = "- Coefficients: blue=negative; orange=positive \n - Tstats/pvals: green=significant,red=insignificant,yellow=marginal"  
	call comment_string(%obj_name,%obj_desc,"n", st_use_names,st_include_descriptions)
	sp_spec_evaluation.comment regression_outputs %comment

endif

' 2.2. Coefficient stability graphs
if @upper(st_outofsample)= "T" and @instr(@upper(st_exec_list),"STABILITY") then
	
	delete(noerr) sp_stability
	spool sp_stability
	call insert_specs("sp_stability","gp_coef_stability", st_use_names)
	
	sp_spec_evaluation.insert(name=coefficient_stability) sp_stability
	delete(noerr) sp_stability

	%obj_name =  "Coefficient stability graphs" 
	%obj_desc = "- Coefficients based on increasing estimation sample with 2 standard deviation error bands"  
	call comment_string(%obj_name,%obj_desc,"n",st_use_names,st_include_descriptions)
 	sp_spec_evaluation.comment coefficient_stability %comment

endif


' 2.2. Auto orders graphs
if @upper(st_outofsample)= "T" and @instr(@upper(st_exec_list),"STABILITY") then
	
	delete(noerr) sp_lag_orders
	spool sp_lag_orders
	call insert_specs("sp_lag_orders","gp_lag_orders", st_use_names)
	
	sp_spec_evaluation.insert(name=lag_orders) sp_lag_orders
	delete(noerr) sp_lag_orders

	%obj_name =  "Automatically selected lag orders" 
	%obj_desc = "- Automatically selected number of lags (of autoregressive and moving average components for ARMA models; of dependent and independet variables for ARDL models)" 
	call comment_string(%obj_name,%obj_desc,"n",st_use_names,st_include_descriptions)
 	sp_spec_evaluation.comment lag_orders %comment

endif



' 2.3 Forecast performance metrics

if @instr(@upper(st_exec_list),"METRICS") then

	delete(noerr) sp_performance_metrics
	spool sp_performance_metrics
	
	' Full sample
	for !pm = 1 to @wcount(st_performance_metrics)
		%pm = @word(st_performance_metrics,!pm)
		
		if sc_subsample_count>0 then
			call performance_tables_multi(%pm,3+1+!pm,%pm)	
		else
			call performance_tables_multi(%pm,3+!pm,%pm)	
		endif
	next

	%first_table = @word(st_performance_metrics,1)
	sp_performance_metrics.comment {%first_table} "~ Full sample"
	
	' Sub samples
	if sc_subsample_count>0 then
		for !subsample = 1 to sc_subsample_count
			for !pm = 1 to @wcount(st_performance_metrics)
				%pm = @word(st_performance_metrics,!pm)		

				!ssrow = 3+(@wcount(st_performance_metrics)+2)*!subsample+!pm+1
				call performance_tables_multi(%pm,!ssrow,%pm + "_"+ @mid(st_subsample{!SubSample}_start,3)+"_" + @mid(st_subsample{!SubSample}_end,3))	
			next

			%first_table = @word(st_performance_metrics,1) +  "_"+ @mid(st_subsample{!SubSample}_start,3)+"_" + @mid(st_subsample{!SubSample}_end,3)
			%comment = "~ Sub sample " + st_subsample{!subsample}
			sp_performance_metrics.comment {%first_table} %comment
		next
	endif
	
	'Inserting into spool
	sp_spec_evaluation.insert(name=performance_metrics) sp_performance_metrics
	delete(noerr) sp_performance_metrics

	%obj_name =  "Forecast performance metrics" 
	%obj_desc = "- Forecast metric based on all available forecast errors at given horizon \n - #=number of forecasts \n - Last column=average across horizons - \n - Sub-samples include only forecast that completely lie in given sub-sample"  
	call comment_string(%obj_name,%obj_desc,"n",st_use_names,st_include_descriptions)
	sp_spec_evaluation.comment performance_metrics %comment


endif

' 2.2 Forecast graphs

delete(noerr) sp_forecast_graphs
spool sp_forecast_graphs

' Summary
if @instr(@upper(st_exec_list),"GRAPHS_SUMMARY") then
	
	for !flength_id = 1 to sc_graph_horizons_n
		%fh = @word(st_graph_horizons,!flength_id)
		
		delete(noerr) sp_forecast_graphs_{%fh}
		spool sp_forecast_graphs_{%fh}
		
		for !spec_id = 1 to sc_spec_count
	
			call spec_alias	
			
			if @isobject("gp_forecasts_all_h"+ %fh + "_" + st_alias) then
				if @upper(st_use_names) = "T" then			
					%eq_name = @word(st_specification_list,!spec_id)
					gp_forecasts_all_h{%fh}_{st_alias}.addtext(t) Conditional forecasts - {%fh} step ahead - {%eq_name}
				else
					gp_forecasts_all_h{%fh}_{st_alias}.addtext(t) Conditional forecasts - {%fh} step ahead - Equation {st_alias}
				endif

				call insert_spec("sp_forecast_graphs_"+ %fh,"gp_forecasts_all_h" + %fh, st_use_names)
		
			endif
			
		next
		
		sp_forecast_graphs.insert(name=f_{%fh}) sp_forecast_graphs_{%fh}
		delete(noerr) sp_forecast_graphs_{%fh}
	next

	%obj_name =  "All forecast graphs" 
	%obj_desc = "- blue with squares = actual historical series \n - dashed without symbol = individual forecasts \n - other solid = user-included series"  
	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	%first_spool = "f_" + @word(st_graph_horizons,1)
	sp_forecast_graphs.comment {%first_spool}  %comment

endif


'Subsamples
if @instr(@upper(st_exec_list),"GRAPHS_SS") then
	for !ss = 1 to sc_subsample_count 
				
		spool sp_subsample{!ss}
		
		for !spec_id = 1 to sc_spec_count
	
			call spec_alias
			
			if @isobject("gp_forecast_SubSample"+ @str(!ss) + "_" + st_alias) then
				call insert_spec("sp_subsample" + @str(!ss),"gp_forecast_subsample" + @str(!ss), st_use_names)
			endif		

			if @isobject("gp_subsample"+ @str(!ss)+ "_fd_" + st_alias) then
				sp_subsample{!ss}.insert(name=spec_{st_alias}_decomposition) gp_subsample{!ss}_fd_{st_alias}
			endif
		next	
		
		%name = "F_" + @mid(st_SubSample{!ss}_start,3)+"_" + @mid(st_SubSample{!ss}_end,3)		
		sp_forecast_graphs.insert(name={%name}) sp_subsample{!ss}
		delete(noerr) sp_subsample{!ss}
	next

	%obj_name = " Subsample forecast graphs" 
	%obj_desc = "- blue with squares = actual historical series \n - orange without symbol = forecast \n - other solid = user-included series"  

	if @instr(@upper(st_exec_list),"DECOMPOSITION") then
		%obj_desc = %obj_desc + " \n \n SUBSAMPLE FORECAST DECOMPOSITION GRAPHS \n - Blue with squares = Dependent variable  (in transformation) \n - other lines = individual drivers (regressors in transformation multipled by coefficients)" 
	endif

	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	%first_spool = "F_" + @mid(st_SubSample1_start,3)+"_" + @mid(st_SubSample1_end,3)
	sp_forecast_graphs.comment  {%first_spool} %comment

endif

'Inserting into spool
if @instr(@upper(st_exec_list),"GRAPHS_SUMMARY") or @instr(@upper(st_exec_list),"GRAPHS_SS") then
	sp_spec_evaluation.insert(name=forecast_graphs) sp_forecast_graphs
	delete(noerr) sp_forecast_graphs
endif

' 2.3. Bias graphs  
if @instr(@upper(st_exec_list),"GRAPHS_BIAS") then
	delete(noerr) sp_bias_graphs
	spool sp_bias_graphs
	
	for !flength_id = 1 to sc_bias_horizons_n
		%fh = @word(st_bias_horizons,!flength_id)
		
		delete(noerr) sp_bias_graphs_{%fh}
		spool sp_bias_graphs_{%fh}
		
		for !spec_id = 1 to sc_spec_count
	
			call spec_alias	
			
			if @isobject("gp_forecast_bias_h"+ %fh + "_" + st_alias) then
				if @upper(st_use_names) = "T" then			
					%eq_name = @word(st_specification_list,!spec_id)
					gp_forecast_bias_h{%fh}_{st_alias}.addtext(t) Forecast bias - {%fh} step ahead - {%eq_name}
				else
					gp_forecast_bias_h{%fh}_{st_alias}.addtext(t) Forecast bias - {%fh} step ahead - Equation {st_alias}
				endif
				
				call insert_spec("sp_bias_graphs_"+ %fh,"gp_forecast_bias_h" + %fh, st_use_names)
			endif
			
		next
		
		sp_bias_graphs.insert(name=f{%fh}) sp_bias_graphs_{%fh}
		delete(noerr) sp_bias_graphs_{%fh}
	next
	
	'Inserting into spool
	sp_spec_evaluation.insert(name=bias_graphs) sp_bias_graphs
	delete(noerr) sp_bias_graphs

	%obj_name =  "Forecast bias graphs" 
	%obj_desc = "- points=actual vs. forecast value \n - orange line = linear fit \n - dashed line = 45-degree line"  
	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	sp_spec_evaluation.comment bias_graphs  %comment

endif

' 2.4. Scenario graphs
%scenario_graph_list = "" 
if @instr(@upper(st_exec_list),"SCENARIOS_LEVEL") then
	%scenario_graph_list = %scenario_graph_list + "level" + " "
endif

if @instr(@upper(st_exec_list),"SCENARIOS_TRANS") then
	%scenario_graph_list = %scenario_graph_list + "trans" + " "
endif

delete(noerr) sp_csf
spool sp_csf

if @instr(@upper(st_exec_list),"SCENARIOS_INDIVIDUAL") or @instr(@upper(st_exec_list),"SCENARIOS_ALL") then

	%scenario_loop_list = ""

	if @instr(@upper(st_exec_list),"SCENARIOS_INDIVIDUAL") then
		%scenario_loop_list = %scenario_loop_list + st_scenarios + "  "
	endif

	if @instr(@upper(st_exec_list),"SCENARIOS_ALL") then
		%scenario_loop_list = %scenario_loop_list + "all" + "  "
	endif

	for %s {%scenario_loop_list}
		
		delete(noerr) sp_{%s}
		spool sp_{%s}
			
		for %type {%scenario_graph_list}
			
			delete(noerr) sp_type
			spool sp_type
			
			for !spec_id = 1 to sc_spec_count
	
				call spec_alias	
		
				if @isobject("gp_csf_"+ %type + "_" +%s + "_" + st_alias) then
					
					%heading = gp_csf_{%type}_{%s}_{st_alias}.@attr("heading")
				
					if @upper(st_use_names) = "T" then			
						%eq_name = @word(st_specification_list,!spec_id)
						%heading = %heading + " -  " + %eq_name
					else
						%heading = %heading + " - Equation "+ st_alias
					endif
					
					gp_csf_{%type}_{%s}_{st_alias}.addtext(t) {%heading}
					
					call insert_spec("sp_type","gp_csf_" + %type + "_"+ %s, st_use_names)
				endif
		
			next
			
			if @upper(%type)="LEVEL" then		
				sp_{%s}.insert(name=level) sp_type
			else
				sp_{%s}.insert(name=transformation) sp_type
			endif	
					
			delete(noerr) sp_type
		next	
		
		sp_csf.insert(name={%s}) sp_{%s}
		delete(noerr) sp_{%s}
	next

	%obj_name =  "Individual conditional scenario forecast graphs" 
	%obj_desc = "- blue with squares = scenario forecast based on given specification \n - orange with dash = original scenario forecast taken from workfile \n - green with dash-dot   = baseline scenario forecast based on given specification \n - other solid = user-included series \n - (model foreast = forecast based on given specification and workfile values of RHS variables; original forecast = scenario forecast taken from workfile)"  
	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	%first_graph = @word(%scenario_loop_list,1)
	sp_csf.comment {%first_graph}  %comment

	%obj_name =  "All conditional scenario forecast graphs" 
	%obj_desc = "- Model scenario forecast (= forecast based on given specification and workfile values of RHS variables) for all scenarios "  
	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	sp_csf.comment all  %comment
	
	' Inserting spool
	sp_spec_evaluation.insert(name=conditional_scenarios) sp_csf
	delete(noerr) sp_csf

endif

' 2.5 Scenario decomposition graphs
spool sp_decomposition

if @instr(@upper(st_exec_list),"DECOMPOSITION") and @instr(@upper(st_exec_list),"SCENARIOS") then

	for %s {st_scenarios}
		
		spool sp_{%s}
			
		for %type fd fdd
			
			spool sp_type
			
			for !spec_id = 1 to sc_spec_count
	
				call spec_alias	
		
				if @isobject("gp_csf_"+ %type + "_" +%s + "_" + st_alias) then
					
					%heading = gp_csf_{%type}_{%s}_{st_alias}.@attr("description")
				
					if @upper(st_use_names) = "T" then			
						%eq_name = @word(st_specification_list,!spec_id)
						%heading = %heading + " -  " + %eq_name
					else
						%heading = %heading + " - Equation "+ st_alias
					endif
					
					gp_csf_{%type}_{%s}_{st_alias}.addtext(t) {%heading}
					
					call insert_spec("sp_type","gp_csf_" + %type + "_"+ %s, st_use_names)
				endif
		
			next
			
			if sp_type.@count>0 then
				if @upper(%type)="FD" then		
					sp_{%s}.insert(name=level) sp_type
				else
					sp_{%s}.insert(name=difference) sp_type
				endif	
			endif
					
			delete(noerr) sp_type
		next	
		
		sp_decomposition.insert(name={%s}) sp_{%s}
		delete(noerr) sp_{%s}
	next
	
	' Inserting spool
	sp_spec_evaluation.insert(name=scenario_decomposition) sp_decomposition
	delete(noerr) sp_csf sp_decomposition

	%obj_name =  "Scenario forecast decomposition graphs" 
	%obj_desc = "- Blue with squares = Conditional scenario forecast for dependent variable (in transformation)  \n - other lines = individual scenario drivers (regressors scenario values in transformation multipled by coefficients)"
	
	if @wcount(st_scenarios)>1 then
		%obj_desc = %obj_desc + "\n \n Scenario forecast decomposition graphs - Difference from baseline \n - Difference between scenario forecast drivers and baseline scenario drivers"	
	endif

	call comment_string(%obj_name,%obj_desc,"y",st_use_names,st_include_descriptions)
	sp_spec_evaluation.comment scenario_decomposition %comment

	delete(noerr) sp_decomposition 

endif


' 3. Cleaning up
if @upper(st_keep_objects)="F" then
	for !spec_id = 1 to sc_spec_count
		call spec_alias
		delete(noerr)  sp_spec_evaluation_{st_alias} gp_forecasts_all_h*_{st_alias} gp_forecast_subsample*_{st_alias} tb_performance_metrics*_{st_alias} tb_reg_output*_{st_alias} gp_coef_stability_{st_alias} gp_csf_*_{st_alias} gp_forecast_bias_*_{st_alias} gp_csf_fd_*_{st_alias} gp_coef_stability_{st_alias} gp_lag_orders_{st_alias} sp_spec_evaluation_{st_alias} 
	next
endif

delete(noerr) st_alias



endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine insert_specs(string %sub_spool_name,string %sub_object_name, string %sub_use_names)

for !spec_id = 1 to sc_spec_count
	call spec_alias
	
	if @isobject(%sub_object_name  + "_"+ st_alias) then
		call insert_spec(%sub_spool_name,%sub_object_name, %sub_use_names)
	endif
next

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine insert_spec(string %sub_spool_name,string %sub_object_name, string %sub_use_names)

if @upper(%sub_use_names)="T" then
	%name = @word(st_specification_list,!spec_id)
	%comment = "~ Equation " + @word(st_specification_list,!spec_id)
else
	%name = "spec" + "_"+ st_alias
	%comment = "~ Specification " + st_alias
endif			

{%sub_spool_name}.append(name=tempname)  {%sub_object_name}_{st_alias}
{%sub_spool_name}.name tempname {%name} 'Dealing with Eviews bug
{%sub_spool_name}.comment {%name} %comment
	

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine performance_tables_multi	(string %sub_metric, scalar !sub_source_row, string %sub_table_name)

delete(noerr) tb_{%sub_metric}
table tb_{%sub_metric}

'Creating table
tb_{%sub_metric}(2,1) = "Specification"
tb_{%sub_metric}(1,2) = "Forecast horizons (# of steps ahead)"

for !h = 1 to sc_forecast_horizons_n
	
	%h = @word(st_forecast_horizons,!h)
	tb_{%sub_metric}(2,1+!h) = @upper(%h)		
next

tb_{%sub_metric}(2,1+sc_forecast_horizons_n+1) = "Avg."


!last_col = sc_forecast_horizons_n+2
!last_row = sc_spec_count+3
tb_{%sub_metric}(!last_row,1) = ""	
tb_{%sub_metric}.setlines(2,1,!last_row,1) +r


tb_{%sub_metric}.setlines(1,2,1,{!last_col}) +b
tb_{%sub_metric}.setlines(3,1,3,{!last_col}) +d

tb_{%sub_metric}.setwidth(A) 12
	
' Inserting eq alias/name
for !spec_id = 1 to sc_spec_count

	if @upper(st_use_names) = "T" then			
		tb_{%sub_metric}(3+!spec_id,1) = @word(st_specification_list,!spec_id)
		tb_{%sub_metric}.setwidth(A) 20
	else
		call spec_alias
		tb_{%sub_metric}(3+!spec_id,1) = st_alias
	endif

next

'Inserting values
for !spec_id = 1 to sc_spec_count
	call spec_alias
	
	for !fh = 1 to sc_forecast_horizons_n+1 
		tb_{%sub_metric}(3+!spec_id,1+!fh) = tb_performance_metrics_{st_alias}(!sub_source_row,1+!fh) 
	next
next

' Color coding
!last_row = 3+sc_spec_count
!last_col = sc_forecast_horizons_n+2
!scale_n = @ceiling(sc_spec_count/(3*2))

if @upper(%sub_metric)="BIAS" then
	%av = "t"
else
	%av = "f"
endif

call colorcode("tb_"  + %sub_metric,"4-" + @str(!last_row),"2-"+ @str(!last_col),"green yellow red",!scale_n,"cols",%av)

'Inserting into spool
sp_performance_metrics.insert(name={%sub_table_name}) tb_{%sub_metric}
delete(noerr) tb_{%sub_metric}
		
endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine colorcode(string %sub_tbname, string %sub_rows, string %sub_cols,string %sub_colors, scalar !sub_scales_n, string %sub_by_type,string %sub_absolute_value) 

' 1. Implemeting settings

' Category number
!sub_group_n = @wcount(%sub_colors)

!sub_category_n = !sub_group_n*!sub_scales_n 

' Colors
%sub_color_list = ""

for !gr = 1 to !sub_group_n
	
	%color_code = "" 	

	%base_color = @word(%sub_colors,!gr)

	if @upper(%base_color)="GREEN" then

		%base_ccode = "@rgb(0,128,0)"
		
		!scale_code_min = 78
		!scale_code_max = 255
		!scale_code_step = @ceiling((!scale_code_max-!scale_code_min)/!sub_scales_n+1)		

		for !sc = 1 to !sub_scales_n

			if !gr = 1 then
				%scale_code =  @str(!scale_code_min+!scale_code_step*(!sc-1))
			else
				%scale_code =  @str(!scale_code_max-!scale_code_step*(!sc-1))
			endif

			%sub_color_list = %sub_color_list + @replace(%base_ccode,"128",%scale_code) + " "
	
		next
	endif

	if @upper(%base_color)="YELLOW" then

		%base_ccode = "@rgb(xxx,255,0)"
		
		!scale_code_min = 50
		!scale_code_max = 255
		!scale_code_step = @ceiling((!scale_code_max-!scale_code_min)/!sub_scales_n+1)		

		for !sc = 1 to !sub_scales_n

			if @upper( @word(%sub_colors,1))="GREEN" then
				%scale_code =  @str(!scale_code_max-!scale_code_step*(!sc-1))
			else
				%scale_code =  @str(!scale_code_min+!scale_code_step*(!sc-1))
			endif

			%sub_color_list = %sub_color_list + @replace(@replace(%base_ccode,"255",%scale_code),"xxx","255") + " "	
		next		
	endif

	if @upper(%base_color)="RED" then

		%base_ccode = "@rgb(255,0,0)"
		
		!scale_code_min = 100
		!scale_code_max = 255
		!scale_code_step = @ceiling((!scale_code_max-!scale_code_min)/!sub_scales_n+1)		

		for !sc = 1 to !sub_scales_n

			if !gr = 1 then
				%scale_code =  @str(!scale_code_min+!scale_code_step*(!sc-1))
			else
				%scale_code =  @str(!scale_code_max-!scale_code_step*(!sc-1))
			endif

			%sub_color_list = %sub_color_list + @replace(%base_ccode,"255",%scale_code) + " "
	
		next
	endif
next

' Rows and columns
if @instr(@upper(%sub_rows),"-")>0 then
	%sub_row_list = ""
	
	!row_first = @val(@left(%sub_rows,@instr(%sub_rows,"-")-1))
	!row_last = @val(@mid(%sub_rows,@instr(%sub_rows,"-")+1))
 
	for !sub_tr = !row_first to !row_last
		%sub_row_list = %sub_row_list + @str(!sub_tr) + " "
	next
else
	%sub_row_list = %sub_rows
endif

if @instr(@upper(%sub_cols),"-")>0 then
	%sub_col_list = ""
	
	!row_first = @val(@left(%sub_cols,@instr(%sub_cols,"-")-1))
	!row_last = @val(@mid(%sub_cols,@instr(%sub_cols,"-")+1))
 
	for !sub_tr = !row_first to !row_last
		%sub_col_list = %sub_col_list + @str(!sub_tr) + " "
	next
else
	%sub_col_list = %sub_cols
endif

' By-type
!bytype = 0

if @upper(%sub_by_type)="ROWS" then
	!bytype = 1
endif

if @upper(%sub_by_type)="COLS" then
	!bytype = 2
endif

' 2. Color coding
if !bytype=0 then
	call colorcode_execution(%sub_tbname, %sub_row_list,%sub_col_list, %sub_absolute_value)
endif

if !bytype=1 then
	for %sub_row {%sub_row_list}
		call colorcode_execution(%sub_tbname, %sub_row,%sub_col_list, %sub_absolute_value)
	next
endif

if !bytype=2 then
	for %sub_col {%sub_col_list}
		call colorcode_execution(%sub_tbname, %sub_row_list,%sub_col, %sub_absolute_value)
	next
endif

delete(noerr)  tb_category_info v_all_values

endsub

' $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

subroutine colorcode_execution(string %sub_tbname, string %sub_rlist,string %sub_clist, string %sub_absolute_value)

' 1. Creating vector of all values
!values_n = @wcount(%sub_rlist)*@wcount(%sub_clist)
vector(!values_n) v_all_values

!v = 0
for %sub_tr {%sub_rlist}
	for %sub_tc {%sub_clist}

		if @upper(%sub_absolute_value)="T" then
			!value = @abs(@val({%sub_tbname}({%sub_tr},{%sub_tc})))
		else
			!value = @val({%sub_tbname}({%sub_tr},{%sub_tc}))
		endif

		if @isna(!value)=0 then	
			!v = !v + 1 
			v_all_values(!v) = !value
		endif
	next
next

' 2. Calculating borders and colors
table tb_category_info

tb_category_info(1,1) = "Category #"
tb_category_info(1,2) = "Color"
tb_category_info(1,3) = "Lower border"
tb_category_info(1,4) = "Upper border"

tb_category_info(2,1) = "1"
tb_category_info(2,2) = @word(%sub_color_list,1)
tb_category_info(2,3) = @min(v_all_values)-0.0001
tb_category_info(2,4) = @quantile(v_all_values,1/!sub_category_n)

for !cg = 2 to !sub_category_n-1
	tb_category_info(1+!cg,1) = @str(!cg,"f.0")
	tb_category_info(1+!cg,2) = @word(%sub_color_list,!cg)
	tb_category_info(1+!cg,3) = @quantile(v_all_values,(!cg-1)/!sub_category_n)
	tb_category_info(1+!cg,4) = @quantile(v_all_values,(!cg)/!sub_category_n)
next

tb_category_info(1+!sub_category_n,1) = @str(!sub_category_n,"f.0")
tb_category_info(1+!sub_category_n,2) = @word(%sub_color_list,!sub_category_n)
tb_category_info(1+!sub_category_n,3) = tb_category_info(1+!sub_category_n-1,4)
tb_category_info(1+!sub_category_n,4) = @max(v_all_values)+0.0001

for !cg = 1 to !sub_category_n-1
	if @instr(tb_category_info(1+!cg,4),"NA")>0 then
		tb_category_info(1+!cg,4) = tb_category_info(1+!cg,3)
		tb_category_info(1+!cg+1,3) = tb_category_info(1+!cg,4)
	endif
next

' 3. Color-coding
for %sub_tr {%sub_rlist}
	for %sub_tc {%sub_clist}

		if @upper(%sub_absolute_value)="T" then
			!value = @abs(@val({%sub_tbname}({%sub_tr},{%sub_tc})))
		else
			!value = @val({%sub_tbname}({%sub_tr},{%sub_tc}))
		endif

		for !cg = 1 to !sub_category_n
			%lb = tb_category_info(1+!cg,3)
			%ub = tb_category_info(1+!cg,4)

			if @right(%lb,1)="." then
				%lb= @left(%lb,@length(%lb)-1)
			endif

			if @right(%ub,1)="." then
				%ub= @left(%ub,@length(%ub)-1)
			endif

			%color = tb_category_info(1+!cg,2)

			if !value>{%lb} and !value<={%ub} then
				{%sub_tbname}.setfillcolor({%sub_tr},{%sub_tc}) {%color}
				exitloop
			endif
		next
	next
next

endsub
	
' ##################################################################################################################





' #######################f###########################################################################################

subroutine speceval_store

 ' Name and mode
if sc_spec_count=1 then
	%output_file_name = st_spec_name + "_specification_evaluation"
	%pdf_mode = "c"
else
	%output_file_name = st_base_var + "_specification_evaluation"
	%pdf_mode = "c"
endif

' Comments
if @upper(st_save_output)="D" then
	%comments = "comment"
else
	%comments = "comment"
endif


'Prompt
if @upper(st_save_output)="USER" then
	%prompt = "prompt"
else
	%prompt = ""
endif

sp_spec_evaluation.save(t=pdf,mode={%pdf_mode},{%comments},{%prompt}) %output_file_name

endsub

' ##################################################################################################################


