subroutine reestimation_custom(string %sub_tfirst_reestimation,string %sub_tlast_reestimation)
		
statusline !fp

!two_regimes = 0

' 1. Estimating original equation
%est_command_reest = {st_spec_name}.@command

if @isobject("gr_"+ st_spec_name + "_regs")=0 then
	{st_spec_name}.makeregs gr_{st_spec_name}_regs
endif

!reg_n = gr_{st_spec_name}_regs.@count
call perfect_corr_identification(gr_{st_spec_name}_regs.@members, %tfirst_reestimation,  %tlast_reestimation, "perfectcor")

if @instr("  "  + @upper(%est_command_reest) + " "," C ")=0 and !reg_n=2  then
	%perfectcor = "f"  
endif

if %perfectcor = "t" then
	for !reg = 2 to  !reg_n
		if !perfectcor{!reg} = 1 then
			%reg_string = gr_{st_spec_name}_regs.@seriesname(!reg)
			%est_command_reest = @trim(@replace(" " + @upper(%est_command_reest) + " "," "+ @upper(%reg_string) + " "," "))
		endif			
	next
endif 	

smpl {%sub_tfirst_reestimation} {%sub_tlast_reestimation}
equation eq_nobreak.{%est_command_reest}

' 2. Testing
if @dtoo(%sub_tlast_reestimation)>@dtoo("2009M01") and @dtoo(%sub_tlast_reestimation)>(@dtoo("2008M10")+{st_spec_name}.@ncoef*2) then

	%eq_command_structural = {st_spec_name}.@command

	for %arma_term ar(1) ma(1)
		 %eq_command_structural = @replace(@upper(%eq_command_structural),@upper(%arma_term),"")
	next

	equation eq_structural.{%eq_command_structural}

	freeze(tb_test) eq_structural.chow 2008m10 @ c
	
	scalar sc_pval = @val(tb_test(6,5))

	if sc_pval<0.05 then
		!two_regimes = 1
	endif		

'	rename tb_test  tb_test_{!fp}
'	rename sc_pval sc_pval_{!fp}

	delete(noerr) tb_test sc_pval
endif

' 3. Estimating final equation

if !two_regimes = 0 then
	smpl {%sub_tfirst_reestimation} {%sub_tlast_reestimation}
	equation {st_spec_name}_reest.{%est_command_reest}
else
	smpl 2008M10 {%sub_tlast_reestimation}
	equation {st_spec_name}_reest.{%est_command_reest}
endif

' 4. Creating model
if !fp=1 then
	model m_speceval
	m_speceval.merge {st_spec_name}_reest
else
	m_speceval.update {st_spec_name}_reest
endif

copy {st_spec_name}_reest {st_spec_name}_reest{!fp}

endsub


