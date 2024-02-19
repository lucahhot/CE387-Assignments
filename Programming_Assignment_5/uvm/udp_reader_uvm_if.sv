import uvm_pkg::*;

interface udp_reader_uvm_if;
    logic        clock;
    logic        reset;
    logic        in_full;
    logic        in_wr_en;
    logic [7:0]  in_din;
    logic        in_sof;
    logic        in_eof;  
    logic        out_empty;
    logic        out_rd_en;
    logic  [7:0] out_dout;
endinterface
