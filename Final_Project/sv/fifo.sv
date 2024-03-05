

// Define
//`define				FPGA_EMU
`define				STANDARD
//`define				FWFT

//Module
module fifo #(
	parameter		FIFO_DATA_WIDTH		= 32,					// Data width
					FIFO_BUFFER_SIZE		= 1024,					// FIFO depth
					ALMOST_WR		= 2,					// Almost full asserted advance value
					ALMOST_RD		= 2						// Almost empty asserted advance value

)(
	// Clock and reset
	input									wr_clk,			// Write clock
	input									rd_clk,			// Read clock
	input									rst_n,			// Async reset					
	// Write interface
	input									wr_en,			// Write enable
	input		 [FIFO_DATA_WIDTH-1:0]			din,			// Write data
	// Read interface
	input									rd_en,			// Read enable
	output logic [FIFO_DATA_WIDTH-1:0]			dout,			// Read data
	// Status	
	output logic							full,			// Full flag
	output logic							empty,			// Empty flag
	output logic							almost_full,	// Almost full flag
	output logic							almost_empty,	// Almost empty flag
	output logic							wr_ack,			// Write valid
	output logic							valid,			// Read valid
	output logic [$clog2(FIFO_BUFFER_SIZE-1):0]	wr_count,		// Write count
	output logic [$clog2(FIFO_BUFFER_SIZE-1):0]	rd_count		// Read count
);
	//=========================================================================
	// The time unit and precision of the internal declaration
	timeunit		1ns;
	timeprecision	1ps;

	//=========================================================
	// Parameter
	localparam		TCO			= 1.6,						// Simulate the delay of the register
					ADDR_WIDTH	= $clog2(FIFO_BUFFER_SIZE-1),	// Address width
					MULTIPLE	= 2**($clog2(FIFO_DATA_WIDTH)-$clog2(FIFO_DATA_WIDTH));	// The write data width is a multiple of the read data width


	//=========================================================
	//Signal
	reg 	[FIFO_DATA_WIDTH-1:0]		mem [FIFO_BUFFER_SIZE];		// Memory bank

	logic	[ADDR_WIDTH-1:0]		wr_addr;				// Write address
	logic  	[ADDR_WIDTH-1:0]		rd_addr;				// Read address
	logic	[ADDR_WIDTH:0]			wr_ptr;					// Write pointer
	logic  	[ADDR_WIDTH:0]			rd_ptr;					// Read pointer
	logic	[ADDR_WIDTH:0]			wr_ptr_gray;			// Write pointer gray
	logic  	[ADDR_WIDTH:0]			rd_ptr_gray;			// Read pointer gray
	logic	[ADDR_WIDTH:0]			wr_ptr_gray_ff [2];		// Write pointer gray register
	logic  	[ADDR_WIDTH:0]			rd_ptr_gray_ff [2];		// Read pointer gray register
	logic	[ADDR_WIDTH:0]			wr_ptr_bin;				// Write pointer in reed domian
	logic  	[ADDR_WIDTH:0]			rd_ptr_bin;				// Read pointer in write domian

	logic							wr_mask;				// Write mask
	logic							rd_mask;				// Read mask


	logic	[$clog2(MULTIPLE):0]	cnt_mul;				// Multiplier Counter


	//=========================================================
	// Status
	assign 	full			= wr_ptr_gray == (rd_ptr_gray_ff[1] ^ {2'b11,{(ADDR_WIDTH-1){1'b0}}});
	assign 	empty			= rd_ptr_gray == wr_ptr_gray_ff[1];

	always_comb begin
		wr_ptr_bin[ADDR_WIDTH]	= wr_ptr_gray_ff[1][ADDR_WIDTH];
		rd_ptr_bin[ADDR_WIDTH]	= rd_ptr_gray_ff[1][ADDR_WIDTH];
		for(int i=(ADDR_WIDTH-1);i>=0;i--)begin:gray2bin
			wr_ptr_bin[i]	= wr_ptr_gray_ff[1][i] ^ wr_ptr_bin[i+1];
			rd_ptr_bin[i]	= rd_ptr_gray_ff[1][i] ^ rd_ptr_bin[i+1];
		end
	end

	assign	wr_count 		= wr_ptr - rd_ptr_bin;
	assign	rd_count 		= wr_ptr_bin - rd_ptr;

	assign	almost_full		= wr_count >= (FIFO_BUFFER_SIZE - ALMOST_WR); 
	assign	almost_empty	= rd_count <  (ALMOST_RD + 1);

	always_ff@(posedge wr_clk, negedge rst_n)begin
		if(!rst_n)begin
			wr_ack	<= #TCO '0;
		end
		else if(!wr_mask)begin
			wr_ack 	<= #TCO wr_en;
		end
		else begin
			wr_ack	<= #TCO '0;
		end
	end

	`ifdef	FWFT
	assign	valid	= ~empty;
	`elsif	STANDARD
	always_ff@(posedge rd_clk)begin
		if(empty)
			valid	<= #TCO '0;
		else if(rd_en)
			valid	<= #TCO '1;
		else
			valid	<= #TCO '0;
	end
	`endif


	//=========================================================
	// Write side
	assign	wr_mask	= ~ (wr_en & (~full));

	always_ff@(posedge wr_clk, negedge rst_n)begin
		if(!rst_n)begin
			wr_ptr	<= #TCO '0;
		end
		else if(!wr_mask)begin
			wr_ptr	<= #TCO wr_ptr + 1'b1;
		end
	end

	assign	wr_addr = wr_ptr[ADDR_WIDTH-1-:ADDR_WIDTH];


	//=========================================================
	// Write pointer sync
	assign	wr_ptr_gray	= (wr_ptr >> 1) ^ wr_ptr;

	always_ff@(posedge rd_clk, negedge rst_n)begin
		if(!rst_n)begin
			wr_ptr_gray_ff[0]	<= #TCO '0;
			wr_ptr_gray_ff[1]	<= #TCO '0;
		end
		else begin
			wr_ptr_gray_ff[0]	<= #TCO wr_ptr_gray;
			wr_ptr_gray_ff[1]	<= #TCO wr_ptr_gray_ff[0];
		end
	end


	//=========================================================
	// Read side
	assign  rd_mask = ~(rd_en & (~empty));

	always_ff@(posedge rd_clk, negedge rst_n)begin
		if(!rst_n)begin
			cnt_mul	<= #TCO 1;
		end
		else if(!rd_mask)begin
			cnt_mul	<= #TCO cnt_mul + 2'b10;
		end
    end

	always_ff@(posedge rd_clk, negedge rst_n)begin
		if(!rst_n)begin
			rd_ptr	<= #TCO '0;
		end
		else if(!rd_mask && &cnt_mul)begin
			rd_ptr	<= #TCO rd_ptr + 1'b1;
		end
	end

	assign	rd_addr = rd_ptr[ADDR_WIDTH-1-:ADDR_WIDTH];


	//=========================================================
	// Write pointer sync
	assign	rd_ptr_gray	= (rd_ptr >> 1) ^ rd_ptr;

	always_ff@(posedge wr_clk, negedge rst_n)begin
		if(!rst_n)begin
			rd_ptr_gray_ff[0]	<= #TCO '0;
			rd_ptr_gray_ff[1]	<= #TCO '0;
		end
		else begin
			rd_ptr_gray_ff[0]	<= #TCO rd_ptr_gray;
			rd_ptr_gray_ff[1]	<= #TCO rd_ptr_gray_ff[0];
		end
	end


	//=========================================================
	// FIFO storage
	`ifdef FPGA_EMU
	always_ff@(posedge wr_clk)begin
		if(!wr_mask)
			mem[wr_addr] <= #TCO din;
	end
	`else
    always_ff@(posedge wr_clk, negedge rst_n)begin
		if(!rst_n)begin
			for(int i=0;i<FIFO_BUFFER_SIZE;i++)begin
				mem[i]	<= #TCO '0;
			end
		end
		else if(!wr_mask) begin
			mem[wr_addr]	<= #TCO din;
		end
	end
	`endif

	`ifdef	FWFT
	assign  dout	= mem[rd_addr][((cnt_mul>>1)*FIFO_DATA_WIDTH+FIFO_DATA_WIDTH-1)-:FIFO_DATA_WIDTH];
	`elsif	STANDARD
	always_ff@(posedge rd_clk)begin
		if(!empty)
			dout	<= #TCO mem[rd_addr][((cnt_mul>>1)*FIFO_DATA_WIDTH+FIFO_DATA_WIDTH-1)-:FIFO_DATA_WIDTH];
		else
			dout	<= #TCO 'z;
	end
	`endif
	
endmodule
