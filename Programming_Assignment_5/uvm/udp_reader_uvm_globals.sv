`ifndef __GLOBALS__
`define __GLOBALS__

// UVM Globals
localparam string FILE_IN_NAME = "../source/test.pcap";
localparam string FILE_OUT_NAME = "../source/test_output.txt";
localparam string FILE_CMP_NAME = "../source/test.txt";
localparam int PCAP_FILE_HEADER_BYTES = 24;
localparam int PCAP_PACKET_HEADER_BYTES = 16;
localparam int FIFO_DATA_WIDTH = 8;
localparam int FIFO_BUFFER_SIZE = 1024;
localparam int UDP_DATA_BYTES = (FIFO_BUFFER_SIZE*3 + 907);
localparam int CLOCK_PERIOD = 10;

`endif
