import uvm_pkg::*;


class cordic_uvm_agent extends uvm_agent;

    `uvm_component_utils(cordic_uvm_agent)

    uvm_analysis_port#(cordic_results_uvm_transaction) agent_ap_output;
    uvm_analysis_port#(cordic_uvm_transaction) agent_ap_compare;

    cordic_uvm_sequencer        seqr;
    cordic_uvm_driver            drvr;
    cordic_uvm_monitor_output    mon_out;
    cordic_uvm_monitor_compare    mon_cmp;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent_ap_output  = new(.name("agent_ap_output"), .parent(this));
        agent_ap_compare = new(.name("agent_ap_compare"),  .parent(this));

        seqr    = cordic_uvm_sequencer::type_id::create(.name("seqr"), .parent(this));
        drvr    = cordic_uvm_driver::type_id::create(.name("drvr"), .parent(this));
        mon_out    = cordic_uvm_monitor_output::type_id::create(.name("mon_out"), .parent(this));
        mon_cmp    = cordic_uvm_monitor_compare::type_id::create(.name("mon_cmp"), .parent(this));
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);        
        drvr.seq_item_port.connect(seqr.seq_item_export);
        mon_out.mon_ap_output.connect(agent_ap_output);
        mon_cmp.mon_ap_compare.connect(agent_ap_compare);
    endfunction: connect_phase

endclass: cordic_uvm_agent
