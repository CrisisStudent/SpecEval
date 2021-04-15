wfclose(noerr) .\data_for_application4.wf1
wfopen .\data_for_application4.wf1

pageselect quarterly

%spi_first = spi.@first
%spi_last = spi.@last

smpl {%spi_first} {%spi_last}
graph fg_spi_level.line spi
fg_spi_level.addtext(t,sb) Level

smpl {%spi_first} {%spi_last}
graph fg_spi_loglevel.line spi
fg_spi_loglevel.axis(l) log
fg_spi_loglevel.addtext(t,sb) Log-level

smpl {%spi_first} {%spi_last}
graph fg_spi_ratio1.line spi/cpi
fg_spi_ratio1.addtext(t,sb) Ratio - SPI to CPI

smpl {%spi_first} {%spi_last}
graph fg_spi_ratio2.line spi/gdp
fg_spi_ratio2.addtext(t,sb) Ratio - SPI to GDP

graph fg_spi.merge fg_spi_level fg_spi_loglevel fg_spi_ratio1 fg_spi_ratio2
fg_spi.align(2,1,1)
fg_spi.display

smpl @all
equation eq_spi_ar1.ls spi/gdp c spi(-1)/gdp(-1)

eq_spi_ar1.speceval(oos="f")

eq_spi_ar1.speceval(oos="f",trans="log")

eq_spi_ar1.speceval(oos="f",trans="ratio",graph_bench="gdp")

equation eq_spi_ar2.ls spi/gdp c spi(-1)/gdp(-1) spi(-2)/gdp(-2)
equation eq_spi_regarma10.ls spi/gdp c spi(-1)/gdp(-1) ar(1)
equation eq_spi_regarma01.ls spi/gdp c spi(-1)/gdp(-1) ma(1)
equation eq_spi_regarma11.ls spi/gdp c spi(-1)/gdp(-1) ar(1) ma(1)

eq_spi_ar1.speceval(spec_list="eq_spi*",use_names="t",oos="f")


eq_spi_ar1.speceval(scenarios="bl su sd",tfirst_sgraph="1970q1")
eq_spi_ar1.speceval(scenarios="bl su sd",tfirst_sgraph="1970q1",trans="log")
eq_spi_ar1.speceval(scenarios="bl su sd",tfirst_sgraph="1970q1",trans="ratio",graph_bench="gdp")


