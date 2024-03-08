import uvm_pkg::*;

interface  fm_radio_uvm_if;
    logic                   clock;
    logic                   reset;

    logic                   in_full;
    logic                   in_wr_en;
    logic [BYTE_SIZE-1:0]   data_in;

    logic [DATA_SIZE-1:0]   left_audio_out;
    logic                   left_audio_empty;
    logic                   left_audio_rd_en;

    logic [DATA_SIZE-1:0]   right_audio_out;
    logic                   right_audio_empty;
    logic                   right_audio_rd_en;
endinterface