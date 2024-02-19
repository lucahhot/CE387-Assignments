import uvm_pkg::*;

class udp_reader_uvm_driver extends uvm_driver#(udp_reader_uvm_transaction);

    `uvm_component_utils(udp_reader_uvm_driver)

    virtual udp_reader_uvm_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_resource_db#(virtual udp_reader_uvm_if)::read_by_name
            (.scope("ifs"), .name("vif"), .val(vif)));
    endfunction: build_phase

    virtual task run_phase(uvm_phase phase);
        drive();
    endtask: run_phase

    virtual task drive();
        udp_reader_uvm_transaction tx;

        // wait for reset
        @(posedge vif.reset)
        @(negedge vif.reset)

        vif.in_din = 8'b0;
        vif.in_wr_en = 1'b0;
        vif.in_sof = 1'b0;
        vif.in_eof = 1'b0;
    

        forever begin
            @(negedge vif.clock) 
            begin                
                if (vif.in_full == 1'b0) begin
                    seq_item_port.get_next_item(tx);
                    vif.in_din = tx.packet_byte;
                    vif.in_wr_en = 1'b1;
                    vif.in_sof = tx.tx_in_sof;
                    vif.in_eof = tx.tx_in_eof;
                    seq_item_port.item_done();
                end else begin
                    vif.in_wr_en = 1'b0;
                    vif.in_din = 8'b0;
                    vif.in_sof = 1'b0;
                    vif.in_eof = 1'b0;
                end
            end
        end
    endtask: drive

endclass
