import uvm_pkg::*;

interface  cordic_uvm_if;
    logic        clock;
    logic        reset;
    logic        radians_full;
    logic        radians_wr_en;
    logic [31:0] radians_din; 
    logic        sin_empty;
    logic        sin_rd_en;
    logic signed [15:0] sin_dout;
    logic        cos_empty;
    logic        cos_rd_en;
    logic signed [15:0] cos_dout;
endinterface
