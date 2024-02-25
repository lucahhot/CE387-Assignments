import uvm_pkg::*;


class cordic_uvm_transaction extends uvm_sequence_item;
    logic signed [31:0] radian_input;

    function new(string name = "");
        super.new(name);
    endfunction: new

    `uvm_object_utils_begin(cordic_uvm_transaction)
    `uvm_field_int(radian_input, UVM_ALL_ON)
    `uvm_object_utils_end
endclass: cordic_uvm_transaction

class cordic_results_uvm_transaction extends uvm_sequence_item;
    logic signed [15:0] sin_output;
    logic signed [15:0] cos_output;

    function new(string name = "");
        super.new(name);
    endfunction: new

    `uvm_object_utils_begin(cordic_results_uvm_transaction)
    `uvm_field_int(sin_output, UVM_ALL_ON)
    `uvm_field_int(cos_output, UVM_ALL_ON)
    `uvm_object_utils_end
endclass: cordic_results_uvm_transaction


class cordic_uvm_sequence extends uvm_sequence#(cordic_uvm_transaction);
    `uvm_object_utils(cordic_uvm_sequence)

    function new(string name = "");
        super.new(name);
    endfunction: new

    task body();        
        cordic_uvm_transaction tx;
        shortreal p;
        logic signed [2*CORDIC_DATA_WIDTH-1:0] p_fixed;

        for (int i = -360; i <= 360; i++) begin
            p = i * M_PI / 180;
            p_fixed = QUANTIZE_F(p);
            tx = cordic_uvm_transaction::type_id::create(.name("tx"), .contxt(get_full_name()));
            start_item(tx);
            tx.radian_input = p_fixed;
            finish_item(tx);
        end

    endtask: body
endclass: cordic_uvm_sequence

typedef uvm_sequencer#(cordic_uvm_transaction) cordic_uvm_sequencer;
