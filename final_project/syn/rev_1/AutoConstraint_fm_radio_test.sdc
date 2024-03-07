
#Begin clock constraint
define_clock -name {fm_radio_test|clock} {p:fm_radio_test|clock} -period 26.226 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 13.113 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {add|state_derived_clock} {n:add|state_derived_clock} -period 26.226 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 13.113 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {gain_32s_10s_1|state_derived_clock[0]} {n:gain_32s_10s_1|state_derived_clock[0]} -period 26.226 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 13.113 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {multiply_32s_0|state_derived_clock[0]} {n:multiply_32s_0|state_derived_clock[0]} -period 26.226 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 13.113 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {gain_32s_10s_0|state_derived_clock[0]} {n:gain_32s_10s_0|state_derived_clock[0]} -period 26.226 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 13.113 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {multiply_32s_1|state_derived_clock[0]} {n:multiply_32s_1|state_derived_clock[0]} -period 26.226 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 13.113 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {div_32s_32s|state_derived_clock[5]} {n:div_32s_32s|state_derived_clock[5]} -period 26.226 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 13.113 -route 0.000 
#End clock constraint
