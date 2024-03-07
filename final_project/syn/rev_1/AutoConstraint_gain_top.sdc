
#Begin clock constraint
define_clock -name {gain_top|clock} {p:gain_top|clock} -period 7.545 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 3.772 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {gain_32s_10s|state_derived_clock[0]} {n:gain_32s_10s|state_derived_clock[0]} -period 7.545 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 3.772 -route 0.000 
#End clock constraint
