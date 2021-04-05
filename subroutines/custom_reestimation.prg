subroutine reestimation_custom(string %sub_tfirst_reestimation,string %sub_tlast_reestimation)

' This is example of custom reestimation procedure
' The reestimation creates model object with estiamted equation

%random_walk = st_EqVar + " = "+ st_EqVar + "(-1)"

if @isobject("m_speceval")=0 then
	model m_speceval
endif

if !fp=1 then
	m_speceval.append {%random_walk}
else
	m_spaceval.drop {st_EqVar}
	m_speceval.append {%random_walk}
endif

endsub


