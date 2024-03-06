import uvm_pkg::*;

`uvm_analysis_imp_decl(_output)
`uvm_analysis_imp_decl(_compare)

class cordic_uvm_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(cordic_uvm_scoreboard)

    uvm_analysis_export #(cordic_results_uvm_transaction) sb_export_output;
    uvm_analysis_export #(cordic_uvm_transaction) sb_export_compare;

    uvm_tlm_analysis_fifo #(cordic_results_uvm_transaction) output_fifo;
    uvm_tlm_analysis_fifo #(cordic_uvm_transaction) compare_fifo;

    cordic_results_uvm_transaction tx_out;
    cordic_results_transaction tx_cmp;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        tx_out    = new("tx_out");
        tx_cmp = new("tx_cmp");
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sb_export_output    = new("sb_export_output", this);
        sb_export_compare   = new("sb_export_compare", this);

           output_fifo        = new("output_fifo", this);
        compare_fifo    = new("compare_fifo", this);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        sb_export_output.connect(output_fifo.analysis_export);
        sb_export_compare.connect(compare_fifo.analysis_export);
    endfunction: connect_phase

    virtual task run();
        forever begin
            output_fifo.get(tx_out);
            compare_fifo.get(tx_cmp);            
            comparison();
        end
    endtask: run

    virtual function void comparison();

        real THRESHOLD = 1;

        if ((tx_out.audio_left_output - tx_cmp.audio_left_output) > THRESHOLD || (tx_cmp.audio_left_output - tx_out.audio_left_output) > THRESHOLD) begin
            `uvm_info("SB_CMP", tx_out.sprint(), UVM_LOW);
            `uvm_info("SB_CMP", tx_cmp.sprint(), UVM_LOW);
            `uvm_fatal("SB_CMP", $sformatf("Audio left output exceeded error threshold: fm_radio audio_left_output = %x, real output = %x", tx_out.audio_left_output, tx_cmp.audio_left_output));
        end

        if ((tx_out.audio_right_output - tx_cmp.audio_right_output) > THRESHOLD || (tx_cmp.audio_right_output - tx_out.audio_right_output) > THRESHOLD) begin
            `uvm_info("SB_CMP", tx_out.sprint(), UVM_LOW);
            `uvm_info("SB_CMP", tx_cmp.sprint(), UVM_LOW);
            `uvm_fatal("SB_CMP", $sformatf("Audio right output exceeded error threshold: fm_radio audio_right_output = %x, real output = %x", tx_out.audio_right_output, tx_cmp.audio_right_output));
        end

    endfunction: comparison
endclass: cordic_uvm_scoreboard
