import uvm_pkg::*;

class udp_reader_uvm_configuration extends uvm_object;
    `uvm_object_utils(udp_reader_uvm_configuration)

    function new(string name = "");
        super.new(name);
    endfunction: new
endclass: udp_reader_uvm_configuration
