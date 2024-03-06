import uvm_pkg::*;


class fm_radio_uvm_transaction extends uvm_sequence_item;
    logic signed [7:0] data_in;

    function new(string name = "");
        super.new(name);
    endfunction: new

    `uvm_object_utils_begin(fm_radio_uvm_transaction)
    `uvm_field_int(data_in, UVM_ALL_ON)
    `uvm_object_utils_end
endclass: fm_radio_uvm_transaction

class fm_radio_results_uvm_transaction extends uvm_sequence_item;
    logic signed [31:0] audio_left_output;
    logic signed [31:0] audio_right_output;

    function new(string name = "");
        super.new(name);
    endfunction: new

    `uvm_object_utils_begin(fm_radio_results_uvm_transaction)
    `uvm_field_int(audio_left_output, UVM_ALL_ON)
    `uvm_field_int(audio_right_output, UVM_ALL_ON)
    `uvm_object_utils_end
endclass: fm_radio_results_uvm_transaction


class fm_radio_uvm_sequence extends uvm_sequence#(fm_radio_uvm_transaction);
    `uvm_object_utils(fm_radio_uvm_sequence)

    function new(string name = "");
        super.new(name);
    endfunction: new

    task body();        
        fm_radio_uvm_transaction tx;
        int in_file;
        int i, j;
        logic [7:0] data_byte;

        `uvm_info("SEQ_RUN", $sformatf("Loading file %s...", FILE_IN_FILE), UVM_LOW);

        in_file = $fopen(FILE_IN_FILE, "rb");
        if ( !in_file ) begin
            `uvm_fatal("SEQ_RUN", $sformatf("Failed to open file %s...", FILE_IN_FILE));
        end

        int = 0;
        while (i < 100) begin
            tx = fm_radio_uvm_transaction::type_id::create(.name("tx"), .contxt(get_full_name()));
            start_item(tx);
            j = $fscanf(in_file, "%h", data_byte);
            tx.data_in = data_byte;
            finish_item(tx);
            i++;
        end
    `uvm_info("SEQ_RUN", $sformatf("Closing file %s...", FILE_IN_FILE), UVM_LOW);
    $fclose(in_file);
    endtask: body
endclass: fm_radio_uvm_sequence

typedef uvm_sequencer#(fm_radio_uvm_transaction) fm_radio_uvm_sequencer;
