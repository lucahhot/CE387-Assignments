import uvm_pkg::*;

class cordic_uvm_configuration extends uvm_object;
    `uvm_object_utils(cordic_uvm_configuration)

    function new(string name = "");
        super.new(name);
    endfunction: new
endclass: cordic_uvm_configuration
