import uvm_pkg::*;

class edgedetect_uvm_configuration extends uvm_object;
    `uvm_object_utils(edgedetect_uvm_configuration)

    function new(string name = "");
        super.new(name);
    endfunction: new
endclass: edgedetect_uvm_configuration
