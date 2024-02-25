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
    cordic_uvm_transaction tx_cmp;

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

        real THRESHOLD = 0.001;
        shortreal cordic_sin = DEQUANTIZE_F(32'(tx_out.sin_output));  
        shortreal cordic_cos = DEQUANTIZE_F(32'(tx_out.cos_output));    
        shortreal real_sin = $sin(DEQUANTIZE_F(tx_cmp.radian_input));
        shortreal real_cos = $cos(DEQUANTIZE_F(tx_cmp.radian_input));

        if ((cordic_sin - real_sin) > THRESHOLD || (real_sin - cordic_sin) > THRESHOLD) begin
            `uvm_info("SB_CMP", tx_out.sprint(), UVM_LOW);
            `uvm_info("SB_CMP", tx_cmp.sprint(), UVM_LOW);
            `uvm_fatal("SB_CMP", $sformatf("Cordic sin exceeded error threshold for angle %8.4f: Cordic sin = %8.4f, sin = %8.4f", DEQUANTIZE_F(tx_cmp.radian_input), cordic_sin, real_sin));
        end

        if ((cordic_cos - real_cos) > THRESHOLD || (real_cos - cordic_cos) > THRESHOLD) begin
            `uvm_info("SB_CMP", tx_out.sprint(), UVM_LOW);
            `uvm_info("SB_CMP", tx_cmp.sprint(), UVM_LOW);
            `uvm_fatal("SB_CMP", $sformatf("Cordic cos exceeded error threshold for angle %8.4f: Cordic cos = %8.4f, cos = %8.4f", DEQUANTIZE_F(tx_cmp.radian_input), cordic_cos, real_cos));
        end

    endfunction: comparison
endclass: cordic_uvm_scoreboard
