import uvm_pkg::*;


class udp_reader_uvm_transaction extends uvm_sequence_item;
    logic [7:0] packet_byte;
    // Need to pass these signals through the transaction object
    logic tx_in_sof;
    logic tx_in_eof;

    function new(string name = "");
        super.new(name);
    endfunction: new

    `uvm_object_utils_begin(udp_reader_uvm_transaction)
    `uvm_field_int(packet_byte, UVM_ALL_ON)
    `uvm_field_int(tx_in_sof, UVM_ALL_ON)
    `uvm_field_int(tx_in_eof, UVM_ALL_ON)
    `uvm_object_utils_end
endclass: udp_reader_uvm_transaction


class udp_reader_uvm_sequence extends uvm_sequence#(udp_reader_uvm_transaction);
    `uvm_object_utils(udp_reader_uvm_sequence)

    function new(string name = "");
        super.new(name);
    endfunction: new

    task body();        
        udp_reader_uvm_transaction tx;
        int in_file, i=0, j=0, n_bytes = 0;
        logic [0:PCAP_FILE_HEADER_BYTES-1] [7:0] file_header;
        logic [0:PCAP_PACKET_HEADER_BYTES-1] [7:0] packet_header;
        int packet_size;
        logic [7:0] data_byte;

        `uvm_info("SEQ_RUN", $sformatf("Loading file %s...", FILE_IN_NAME), UVM_LOW);

        in_file = $fopen(FILE_IN_NAME, "rb");
        if ( !in_file ) begin
            `uvm_fatal("SEQ_RUN", $sformatf("Failed to open file %s...", FILE_IN_NAME));
        end

        // Skip PCAP Global header
        i = $fread(file_header, in_file, 0, PCAP_FILE_HEADER_BYTES);
        if ( !i ) begin
            `uvm_fatal("SEQ_RUN", $sformatf("Failed read PCAP header data from %s...", FILE_IN_NAME));
        end

        while ( !$feof(in_file)) begin
            packet_header = {(PCAP_PACKET_HEADER_BYTES){8'h00}};
            i += $fread(packet_header, in_file, i, PCAP_PACKET_HEADER_BYTES);
            packet_size = {<<8{packet_header[8:11]}};
            `uvm_info("SEQ_RUN", $sformatf("Packet size: %d", packet_size), UVM_LOW);

            j = 0;
            while (j < packet_size) begin
                tx = udp_reader_uvm_transaction::type_id::create(.name("tx"), .contxt(get_full_name()));
                start_item(tx);
                i += $fread(data_byte, in_file, i , 1);
                tx.packet_byte = data_byte;
                tx.tx_in_sof = (j == 0) ? 1'b1 : 1'b0;
                tx.tx_in_eof = (j == packet_size - 1) ? 1'b1 : 1'b0;
                //`uvm_info("SEQ_RUN", tx.sprint(), UVM_LOW);
                finish_item(tx);
                j++;
            end
        end

        `uvm_info("SEQ_RUN", $sformatf("Closing file %s...", FILE_IN_NAME), UVM_LOW);
        $fclose(in_file);
    endtask: body
endclass: udp_reader_uvm_sequence

typedef uvm_sequencer#(udp_reader_uvm_transaction) udp_reader_uvm_sequencer;
