wfclose(noerr) .\data_for_application6.wf1
wfopen .\data_for_application6.wf1

pageselect quarterly

%maturities = "1y 2y 3y 5y 7y 9y 10y"
%maturities = "1y 2y 5y 10y"

%graph_string = ""
for %m  {%maturities}
	%graph_string = %graph_string + "yield"+ %m + " "
next

graph fg_yields.line {%graph_string}

for !m = 1 to @wcount(%maturities)
	%m = @word(%maturities,!m)
	fg_yields.setelem(!m) legend({%m})
next

smpl @all
equation eq_2y.ls yield2y-yield1y c yield5y-yield1y
equation eq_5y.ls yield5y-yield2y c yield10y-yield2y

eq_2y.speceval(trans=spread,horizons_graph="4",graph_bench="yield1y")
eq_2y.speceval(eq_list_add="eq_5y",horizons_graph="4",trans=spread,graph_bench="yield1y")

equation eq_2y_ar1.ls yield2y-yield1y c yield5y-yield1y ar(1)

eq_2y.speceval(spec_list="eq_2y_ar1",eq_list_add="eq_5y",horizons_graph="4 8",trans=spread,graph_bench="yield1y",alias_list="simple ar1")

equation eq_5y_ar1.ls yield5y-yield2y c yield10y-yield2y ar(1)

eq_2y.speceval(spec_list="eq_2y_ar1",eq_list_add="eq_5y[alias]",horizons_graph="4 8",trans=spread,graph_bench="yield1y",alias_list="simple ar1")

series spread1y = yield1y-eonia

equation eq_spread1y.ls spread1y c spread1y(-1)

string id_yield1y = "yield1y = spread1y + eonia"

eq_2y.speceval(eq_list_add="eq_spread1y id_yield1y eq_5y",horizons_graph="4",trans=spread,graph_bench="yield1y")

model m_yields
m_yields.merge eq_5y eq_spread1y
m_yields.append yield1y = spread1y + eonia

eq_2y.speceval(eq_list_add="spread1y yield1y yield5y",model_name_add="m_yields",horizons_graph="4",trans=spread,graph_bench="yield1y")


eq_2y.speceval(eq_list_add="spread1y yield1y yield5y",model_name_add="m_yields",horizons_graph="4",exec_list="normal scenarios_individual" ,scenarios="bl",graph_add_scenarios="eonia yield1y",keep_settings="t")

eq_2y.speceval(eq_list_add="spread1y yield1y yield5y",model_name_add="m_yields",horizons_graph="4",exec_list="normal scenarios_individual" ,scenarios="bl",graph_add_scenarios="eonia yield1y[csf]",keep_settings="t")


