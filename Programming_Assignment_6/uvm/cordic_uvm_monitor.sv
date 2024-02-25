import uvm_pkg::*;


// Reads data from output fifo to scoreboard
class cordic_uvm_monitor_output extends uvm_monitor;
    `uvm_component_utils(cordic_uvm_monitor_output)

    uvm_analysis_port#(cordic_results_uvm_transaction) mon_ap_output;

    virtual cordic_uvm_if vif;
    int out_file;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_resource_db#(virtual cordic_uvm_if)::read_by_name
            (.scope("ifs"), .name("vif"), .val(vif)));
        mon_ap_output = new(.name("mon_ap_output"), .parent(this));

        out_file = $fopen(FILE_OUT_NAME, "wb");
        if ( !out_file ) begin
            `uvm_fatal("MON_OUT_BUILD", $sformatf("Failed to open output file %s...", FILE_OUT_NAME));
        end
    endfunction: build_phase

    virtual task run_phase(uvm_phase phase);
        cordic_results_uvm_transaction tx_out;
        shortreal sin_out, cos_out;
        // wait for reset
        @(posedge vif.reset)
        @(negedge vif.reset)

        tx_out = cordic_results_uvm_transaction::type_id::create(.name("tx_out"), .contxt(get_full_name()));

        vif.sin_rd_en = 1'b0;
        vif.cos_rd_en = 1'b0;

        forever begin
            @(negedge vif.clock)
            begin
                if (vif.sin_empty == 1'b0 && vif.cos_empty == 1'b0) begin
                    sin_out = DEQUANTIZE_F(32'(vif.sin_dout));  
                    cos_out = DEQUANTIZE_F(32'(vif.cos_dout)); 
                    $fwrite(out_file, "Cordic sin = %8.4f, Cordic cos = %8.4f\n",sin_out,cos_out);
                    tx_out.sin_output = vif.sin_dout;
                    tx_out.cos_output = vif.cos_dout;
                    mon_ap_output.write(tx_out);
                    vif.sin_rd_en = 1'b1;
                    vif.cos_rd_en = 1'b1;
                end else begin
                    vif.sin_rd_en = 1'b0;
                    vif.cos_rd_en = 1'b0;
                end
            end
        end
    endtask: run_phase

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        `uvm_info("MON_OUT_FINAL", $sformatf("Closing file %s...", FILE_OUT_NAME), UVM_LOW);
        $fclose(out_file);
    endfunction: final_phase

endclass: cordic_uvm_monitor_output


// Reads data from compare file to scoreboard
class cordic_uvm_monitor_compare extends uvm_monitor;
    `uvm_component_utils(cordic_uvm_monitor_compare)

    uvm_analysis_port#(cordic_uvm_transaction) mon_ap_compare;
    virtual cordic_uvm_if vif;
    int cmp_file, n_bytes;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_resource_db#(virtual cordic_uvm_if)::read_by_name
            (.scope("ifs"), .name("vif"), .val(vif)));
        mon_ap_compare = new(.name("mon_ap_compare"), .parent(this));

        // cmp_file = $fopen(SIN_CMP_NAME, "rb");
        // if ( !cmp_file ) begin
        //     `uvm_fatal("MON_CMP_BUILD", $sformatf("Failed to open file %s...", SIN_CMP_NAME));
        // end

    endfunction: build_phase

    virtual task run_phase(uvm_phase phase);
        int i=0;
        shortreal p;
        cordic_uvm_transaction tx_cmp;

        // extend the run_phase 20 clock cycles
        phase.phase_done.set_drain_time(this, (CLOCK_PERIOD*20));

        // notify that run_phase has started
        phase.raise_objection(.obj(this));

        // wait for reset
        @(posedge vif.reset)
        @(negedge vif.reset)

        tx_cmp = cordic_uvm_transaction::type_id::create(.name("tx_cmp"), .contxt(get_full_name()));

        for (int i = 0; i < 16; i++)
            @(negedge vif.clock);

        // syncronize file read with fifo data
        i = -360;
        while (i <= 360) begin
            @(negedge vif.clock)
            if (vif.sin_empty == 1'b0 && vif.cos_empty == 1'b0) begin
                p = i * M_PI / 180;
                tx_cmp.radian_input = QUANTIZE_F(p);
                mon_ap_compare.write(tx_cmp);
                i++;
            end
        end

        // notify that run_phase has completed
        phase.drop_objection(.obj(this));
    endtask: run_phase

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        // `uvm_info("MON_CMP_FINAL", $sformatf("Closing file %s...", SIN_CMP_NAME), UVM_LOW);
        // $fclose(cmp_file);
    endfunction: final_phase

endclass: cordic_uvm_monitor_compare
