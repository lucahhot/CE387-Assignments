module udp_reader (
    input   logic        clock,
    input   logic        reset,
    output  logic        in_rd_en,
    input   logic        in_empty,
    input   logic [7:0]  in_dout,
    input   logic        in_rd_sof,
    input   logic        in_rd_eof,
    output  logic        out_wr_en,
    input   logic        out_full,
    output  logic [7:0]  out_din,
    output  logic        error, // This output is when an error occurs
    output  logic        checksum_valid // When checksum is valid, assert this signal to let output FIFO start bursting out data
);

// Parameters for byte amounts for each header component
parameter ETH_DST_ADDR_BYTES = 6;
parameter ETH_SRC_ADDR_BYTES = 6; 
parameter ETH_PROTOCOL_BYTES = 2; 
parameter IP_VERSION_BYTES = 1; 
parameter IP_HEADER_BYTES = 1; 
parameter IP_TYPE_BYTES = 1; 
parameter IP_LENGTH_BYTES = 2; 
parameter IP_ID_BYTES = 2; 
parameter IP_FLAG_BYTES = 2; 
parameter IP_TIME_BYTES = 1; 
parameter IP_PROTOCOL_BYTES = 1; 
parameter IP_CHECKSUM_BYTES = 2; 
parameter IP_SRC_ADDR_BYTES = 4; 
parameter IP_DST_ADDR_BYTES = 4; 
parameter UDP_DST_PORT_BYTES = 2; 
parameter UDP_SRC_PORT_BYTES = 2; 
parameter UDP_LENGTH_BYTES = 2; 
parameter UDP_CHECKSUM_BYTES = 2;
// Parameters for header checking
parameter IP_PROTOCOL_DEF = 16'h0800;
parameter IP_VERSION_DEF = 4'h4;
parameter UDP_PROTOCOL_DEF = 8'h11;

// Defining all the FSM states
typedef enum logic [4:0] {
    WAIT_FOR_SOF_STATE,
    ETH_DST_ADDR_STATE,
    ETH_SRC_ADDR_STATE,
    ETH_PROTOCOL_STATE,
    IP_VERSION_STATE,
    IP_TYPE_STATE,
    IP_LENGTH_STATE,
    IP_ID_STATE,
    IP_FLAG_STATE,
    IP_TIME_STATE,
    IP_PROTOCOL_STATE,
    IP_CHECKSUM_STATE,
    IP_SRC_ADDR_STATE,
    IP_DST_ADDR_STATE,
    UDP_DST_PORT_STATE,
    UPD_SRC_PORT_STATE,
    UDP_LENGTH_STATE,
    UDP_CHECKSUM_STATE,
    UDP_DATA_STATE,
    ERROR_STATE
} state_types;

state_types state, next_state;

// Variable to keep track of how many bytes being read for each UDP field (will never exceed 6 bytes as the larges UDP field is 6 bytes long)
logic [2:0] num_bytes, num_bytes_c;

// Registers to hold checksum data while it is being accumulated across different clock cycles
logic [31:0] checksum_buffer, checksum_buffer_c;

// Register to hold udp_data_length (different from udp_length)
logic [8 * UDP_LENGTH_BYTES - 1 : 0] udp_data_length, udp_data_length_c;

// Flag to start folding checksum_buffer after EOF has been reached
logic start_folding, start_folding_c;

// Flag to start bursting out data
logic start_bursting, start_bursting_c;

// Counter to count amount of bytes the output FIFO to burst after checksum_valid has been asserted (to keep track of how long it should be asserted for)
// Making it twice the length of a single UDP data packet in case two packets need to be bursted out consecutively and the burst count doesn't get a chance
// to reset to 0 before being set to udp_data_length again
logic [8 * 2 * UDP_LENGTH_BYTES - 1 : 0] burst_count, burst_count_c; 

// Flag to indicate bursting overlap between consecutive packets
logic burst_overlap, burst_overlap_c;

// Registers to hold data from the header (most of it isn't actually used but the C code does this)
logic [8 * ETH_DST_ADDR_BYTES - 1 : 0] eth_dst_addr, eth_dst_addr_c;
logic [8 * ETH_SRC_ADDR_STATE - 1 : 0] eth_src_addr, eth_src_addr_c;
logic [8 * ETH_PROTOCOL_BYTES - 1 : 0] eth_protocol, eth_protocol_c;
logic [8 * IP_VERSION_BYTES - 1 : 0] ip_version, ip_version_c;
logic [8 * IP_TYPE_BYTES - 1 : 0] ip_type, ip_type_c;
logic [8 * IP_LENGTH_BYTES - 1 : 0] ip_length, ip_length_c;
logic [8 * IP_ID_BYTES - 1 : 0] ip_id, ip_id_c;
logic [8 * IP_FLAG_BYTES - 1 : 0] ip_flag, ip_flag_c;
logic [8 * IP_TIME_BYTES - 1 : 0] ip_time, ip_time_c;
logic [8 * IP_PROTOCOL_BYTES - 1 : 0] ip_protocol, ip_protocol_c;
logic [8 * IP_CHECKSUM_BYTES - 1 : 0] ip_checksum, ip_checksum_c;
logic [8 * IP_SRC_ADDR_BYTES - 1 : 0] ip_src_addr, ip_src_addr_c;
logic [8 * IP_DST_ADDR_BYTES - 1 : 0] ip_dst_addr, ip_dst_addr_c;
logic [8 * UDP_DST_PORT_BYTES - 1 : 0] udp_dst_port, udp_dst_port_c;
logic [8 * UDP_SRC_PORT_BYTES - 1 : 0] udp_src_port, udp_src_port_c;
logic [8 * UDP_LENGTH_BYTES - 1 : 0] udp_length, udp_length_c;
logic [8 * UDP_CHECKSUM_BYTES - 1 : 0] udp_checksum, udp_checksum_c;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= WAIT_FOR_SOF_STATE;
        num_bytes <= '0;
        checksum_buffer <= '0;
        eth_dst_addr <= '0;
        eth_src_addr <= '0;
        eth_protocol <= '0;
        ip_version <= '0;
        ip_type <= '0;
        ip_length <= '0;
        ip_id <= '0;
        ip_flag <= '0;
        ip_time <= '0;
        ip_protocol <= '0;
        ip_checksum <= '0;
        ip_src_addr <= '0;
        ip_dst_addr <= '0;
        udp_dst_port <= '0;
        udp_src_port <= '0;
        udp_length <= '0;
        udp_length <= '0;
        udp_checksum <= '0;
        udp_data_length <= '0;
        start_folding <= '0;
        start_bursting <= '0;
        burst_count <= '0;
        burst_overlap <= '0;
    end else begin
        state <= next_state;
        num_bytes <= num_bytes_c;
        checksum_buffer <= checksum_buffer_c;
        eth_dst_addr <= eth_dst_addr_c;
        eth_src_addr <= eth_src_addr_c;
        eth_protocol <= eth_protocol_c;
        ip_version <= ip_version_c;
        ip_type <= ip_type_c;
        ip_length <= ip_length_c;
        ip_id <= ip_id_c;
        ip_flag <= ip_flag_c;
        ip_time <= ip_time_c;
        ip_protocol <= ip_protocol_c;
        ip_checksum <= ip_checksum_c;
        ip_src_addr <= ip_src_addr_c;
        ip_dst_addr <= ip_dst_addr_c;
        udp_dst_port <= udp_dst_port_c;
        udp_src_port <= udp_src_port_c;
        udp_length <= udp_length_c;
        udp_length <= udp_length_c;
        udp_checksum <= udp_checksum_c;
        udp_data_length <= udp_data_length_c;
        start_folding <= start_folding_c;
        start_bursting <= start_bursting_c;
        burst_count <= burst_count_c;
        burst_overlap <= burst_overlap_c;
    end
end

always_comb begin
    next_state = state;
    num_bytes_c = num_bytes;
    checksum_buffer_c = checksum_buffer;
    eth_dst_addr_c = eth_dst_addr;
    eth_src_addr_c = eth_src_addr;
    eth_protocol_c = eth_protocol;
    ip_version_c = ip_version;
    ip_type_c = ip_type;
    ip_length_c = ip_length;
    ip_id_c = ip_id;
    ip_flag_c = ip_flag;
    ip_time_c = ip_time;
    ip_protocol_c = ip_protocol;
    ip_checksum_c = ip_checksum;
    ip_src_addr_c = ip_src_addr;
    ip_dst_addr_c = ip_dst_addr;
    udp_dst_port_c = udp_dst_port;
    udp_src_port_c = udp_src_port;
    udp_length_c = udp_length;
    udp_length_c = udp_length;
    udp_checksum_c = udp_checksum;
    udp_data_length_c = udp_data_length;
    start_folding_c = start_folding;
    start_bursting_c = start_bursting;
    burst_count_c = burst_count;
    burst_overlap_c = burst_overlap;

    // Default outputs:
    in_rd_en = 1'b0;
    out_wr_en = 1'b0;
    out_din = 8'h00;
    error = 1'b0; // Top level udp_reader should only need 1 cycle of error being high to clear the output FIFO buffer
    checksum_valid = 1'b0; // FIFO burst logic should override this and assert high if it is still bursting out data

    // Folding logic after EOF (might happen concurrently with new UDP header info coming in)
    if (start_folding == 1'b1) begin
        if (checksum_buffer >> 16 != 0)
            checksum_buffer_c = (checksum_buffer & 32'(16'hFFFF)) + ($unsigned(checksum_buffer) >> 16);
        else if (~checksum_buffer[15:0] != udp_checksum) begin
            // If calculated checksum does not match checksum value from UDP header
            error = 1'b1;
            start_folding_c = 1'b0;
            checksum_buffer_c = 0;
        end else begin
            start_folding_c = 1'b0;
            checksum_buffer_c = 0;
            // Allow the output FIFO to start bursting out data
            start_bursting_c = 1'b1;
            // Set new burst count here
            burst_count_c = udp_data_length;
            // If start_bursting is already equal to 1 (still bursting out the previous packet), assert burst_overlap to 
            // add udp_data_length to the current burst_count_c in the below if statement or else it gets overridden and
            // the packet will never be bursted out of the output FIFO buffer
            if (start_bursting == 1'b1)
                burst_overlap_c = 1'b1;
        end
    end

    // Count down the amount of bytes for the output FIFO to burst out and keep checksum_valid high during this time
    if (start_bursting == 1'b1) begin
        if (burst_count > 0) begin
            // If there is a burst overlap, make sure to add udp_data_length to the burst count
            if (burst_overlap == 1'b1) begin
                burst_count_c = burst_count - 1'b1 + udp_data_length;
                burst_overlap_c = 1'b0;
            end else
                burst_count_c = burst_count - 1'b1;
            checksum_valid = 1'b1;
        // checksum_valid is already 0 at this point so no need to explicitly reset it
        end else
            start_bursting_c = 1'b0;
    end

    case (state) 

        WAIT_FOR_SOF_STATE: begin
            // Wait for the start of a frame
            if ((in_rd_sof == 1'b1) && (in_empty == 1'b0)) begin
                next_state = ETH_DST_ADDR_STATE;
            end else if (in_empty == 1'b0) 
                in_rd_en = 1'b1;
        end

        ETH_DST_ADDR_STATE: begin
            if (in_empty == 1'b0) begin
                // Concatenate new input to bottom 8-bits of previous value (data comes in in big endian format)
                eth_dst_addr_c = ($unsigned(eth_dst_addr) << 8) | (ETH_DST_ADDR_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % ETH_DST_ADDR_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == ETH_DST_ADDR_BYTES - 1) begin
                    next_state = ETH_SRC_ADDR_STATE;
                    num_bytes_c = '0;
                end
            end
        end

        ETH_SRC_ADDR_STATE: begin
            if (in_empty == 1'b0) begin
                eth_src_addr_c = ($unsigned(eth_src_addr) << 8) | (ETH_SRC_ADDR_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % ETH_SRC_ADDR_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == ETH_SRC_ADDR_BYTES - 1) begin
                    next_state = ETH_PROTOCOL_STATE;
                    num_bytes_c = '0;
                end
            end
        end

        ETH_PROTOCOL_STATE: begin
            if (in_empty == 1'b0) begin
                eth_protocol_c = ($unsigned(eth_protocol) << 8) | (ETH_PROTOCOL_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % ETH_PROTOCOL_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == ETH_PROTOCOL_BYTES - 1) begin
                    // Check eth_protocol against IP_PROTOCOL_DEF
                    if (eth_protocol_c != IP_PROTOCOL_DEF)
                        next_state = ERROR_STATE;
                    else begin
                        next_state = IP_VERSION_STATE;
                        num_bytes_c = '0;
                    end
                end
            end
        end

        IP_VERSION_STATE: begin
            if (in_empty == 1'b0) begin
                ip_version_c = ($unsigned(ip_version) << 8) | (IP_VERSION_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_VERSION_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_VERSION_BYTES - 1) begin
                    if (ip_version_c >> 4 != IP_VERSION_DEF) 
                        next_state = ERROR_STATE;
                    else begin
                        next_state = IP_TYPE_STATE;
                        num_bytes_c = '0;
                    end
                end
            end
        end

        IP_TYPE_STATE: begin
            if (in_empty == 1'b0) begin
                ip_type_c = ($unsigned(ip_type) << 8) | (IP_TYPE_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_TYPE_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_TYPE_BYTES - 1) begin
                    next_state = IP_LENGTH_STATE;
                    num_bytes_c = '0;
                end
            end
        end

        IP_LENGTH_STATE: begin
            if (in_empty == 1'b0) begin
                ip_length_c = ($unsigned(ip_length) << 8) | (IP_LENGTH_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_LENGTH_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_LENGTH_BYTES - 1) begin
                    next_state = IP_ID_STATE;
                    num_bytes_c = '0;
                    // Add IP_LENGTH to the checksum buffer
                    checksum_buffer_c = checksum_buffer + 32'(ip_length_c - 20);
                end
            end
        end

        IP_ID_STATE: begin
            if (in_empty == 1'b0) begin
                ip_id_c = ($unsigned(ip_id) << 8) | (IP_ID_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_ID_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_ID_BYTES - 1) begin
                    next_state = IP_FLAG_STATE;
                    num_bytes_c = '0;
                end
            end
        end

        IP_FLAG_STATE: begin
            if (in_empty == 1'b0) begin
                ip_flag_c = ($unsigned(ip_flag) << 8) | (IP_FLAG_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_FLAG_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_FLAG_BYTES - 1) begin
                    next_state = IP_TIME_STATE;
                    num_bytes_c = '0;
                end
            end
        end

        IP_TIME_STATE: begin
            if (in_empty == 1'b0) begin
                ip_time_c = ($unsigned(ip_time) << 8) | (IP_TIME_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_TIME_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_TIME_BYTES - 1) begin
                    next_state = IP_PROTOCOL_STATE;
                    num_bytes_c = '0;
                end
            end
        end

        IP_PROTOCOL_STATE: begin
            if (in_empty == 1'b0) begin
                ip_protocol_c = ($unsigned(ip_protocol) << 8) | (IP_PROTOCOL_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_PROTOCOL_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_PROTOCOL_BYTES - 1) begin
                    if (ip_protocol_c != UDP_PROTOCOL_DEF) 
                        next_state = ERROR_STATE;
                    else begin
                        next_state = IP_CHECKSUM_STATE;
                        num_bytes_c = '0;
                        // Add IP_PROTOCOL to the checksum buffer
                        checksum_buffer_c = checksum_buffer + 32'(ip_protocol_c);
                    end
                end
            end
        end

        IP_CHECKSUM_STATE: begin
            if (in_empty == 1'b0) begin
                ip_checksum_c = ($unsigned(ip_checksum) << 8) | (IP_CHECKSUM_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_CHECKSUM_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_CHECKSUM_BYTES - 1) begin
                    next_state = IP_SRC_ADDR_STATE;
                    num_bytes_c = '0;
                end
            end
        end

        IP_SRC_ADDR_STATE: begin
            if (in_empty == 1'b0) begin
                ip_src_addr_c = ($unsigned(ip_src_addr) << 8) | (IP_SRC_ADDR_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_SRC_ADDR_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_SRC_ADDR_BYTES - 1) begin
                    next_state = IP_DST_ADDR_STATE;
                    num_bytes_c = '0;
                end
        
                // If this is the first byte, shift left by 8 (like in the C code)
                if (num_bytes % 2 == 0) 
                    checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout) << 8);
                // If not, just add it to the checksum buffer
                else 
                    checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout));
            end
        end

        IP_DST_ADDR_STATE: begin
            if (in_empty == 1'b0) begin
                ip_dst_addr_c = ($unsigned(ip_dst_addr) << 8) | (IP_DST_ADDR_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_DST_ADDR_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_DST_ADDR_BYTES - 1) begin
                    next_state = UDP_DST_PORT_STATE;
                    num_bytes_c = '0;
                end

                // If this is the first byte, shift left by 8 (like in the C code)
                if (num_bytes % 2 == 0) 
                    checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout) << 8);
                // If not, just add it to the checksum buffer
                else 
                    checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout));
                
            end
        end

        UDP_DST_PORT_STATE: begin
            if (in_empty == 1'b0) begin
                udp_dst_port_c = ($unsigned(udp_dst_port) << 8) | (UDP_DST_PORT_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % UDP_DST_PORT_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == UDP_DST_PORT_BYTES - 1) begin
                    next_state = UPD_SRC_PORT_STATE;
                    num_bytes_c = '0;
                end

                // If this is the first byte, shift left by 8 (like in the C code)
                if (num_bytes % 2 == 0) 
                    checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout) << 8);
                // If not, just add it to the checksum buffer
                else 
                    checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout));
                
            end
        end

        UPD_SRC_PORT_STATE: begin
            if (in_empty == 1'b0) begin
                udp_src_port_c = ($unsigned(udp_src_port) << 8) | (UDP_SRC_PORT_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % UDP_SRC_PORT_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == UDP_SRC_PORT_BYTES - 1) begin
                    next_state = UDP_LENGTH_STATE;
                    num_bytes_c = '0;
                end

                // If this is the first byte, shift left by 8 (like in the C code)
                if (num_bytes % 2 == 0) 
                    checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout) << 8);
                // If not, just add it to the checksum buffer
                else 
                    checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout));
                
            end
        end

        UDP_LENGTH_STATE: begin
            if (in_empty == 1'b0) begin
                udp_length_c = ($unsigned(udp_length) << 8) | (UDP_LENGTH_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % UDP_LENGTH_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == UDP_LENGTH_BYTES - 1) begin
                    next_state = UDP_CHECKSUM_STATE;
                    num_bytes_c = '0;
                    // This data length value to be used to go through the UDP data after the UDP header (different from udp_length)
                    udp_data_length_c = udp_length_c - (UDP_CHECKSUM_BYTES + UDP_LENGTH_BYTES + UDP_DST_PORT_BYTES + UDP_SRC_PORT_BYTES);
                end

                // If this is the first byte, shift left by 8 (like in the C code)
                if (num_bytes % 2 == 0) 
                    checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout) << 8);
                // If not, just add it to the checksum buffer
                else 
                    checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout));
                
            end
        end

        UDP_CHECKSUM_STATE: begin
            if (in_empty == 1'b0) begin
                udp_checksum_c = ($unsigned(udp_checksum) << 8) | (UDP_CHECKSUM_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % UDP_CHECKSUM_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == UDP_CHECKSUM_BYTES - 1) begin
                    next_state = UDP_DATA_STATE;
                    num_bytes_c = '0;
                end
            end
        end

        // Data is coming in here, output to out_din (where it'll be held in a temporary FIFO), and add the values
        // to checksum_buffer to check at the end
        UDP_DATA_STATE: begin
            if (in_empty == 1'b0) begin
                out_din = in_dout;
                out_wr_en = 1'b1;
                in_rd_en = 1'b1;
                num_bytes_c = (num_bytes + 1) % 2; // Will just alternate between 0 and 1 since we only care about knowing if a byte is even or odd
                // If we have not reached the end of the file then make 16 bit words out of every 2 adjacent 8 bit words
                // and calculate the sum of all 16 bit words
                if (~in_rd_eof) begin
                    // Adding data bytes to the checksum_buffer
                    if (num_bytes == 0)
                        checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout) << 8);
                    else
                        checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout));
                    // Loop through the same state
                    next_state = UDP_DATA_STATE;
                end else begin
                    // After we reach EOF, we add the last byte of data to checksum_buffer (no point adding the extra padded 0 byte even if udp_data_length is odd)
                    if (num_bytes == 0)
                        checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout) << 8);
                    else
                        checksum_buffer_c = checksum_buffer + 16'($unsigned(in_dout));
                    // Next cycle we will be waiting for a new packet so switch to WAIT_FOR_SOF
                    // The folding process of checksum will happen in parallel along with the one's complement at the end
                    next_state = WAIT_FOR_SOF_STATE;
                    // Set flag to start folding
                    start_folding_c = 1'b1;
                    // in_rd_en will be automatically set to 0 in the next cycle so there will be no reading of data until SOF is detected in WAIT_FOR_SOF
                end
            end
        end

        // Error state is header information is wrong
        ERROR_STATE: begin
            // Assert the error signal high and go back to WAIT_FOR_SOF
            error = 1'b1;
            next_state = WAIT_FOR_SOF_STATE;
        end

        default: begin
            next_state = WAIT_FOR_SOF_STATE;
            num_bytes_c = 'X;
            eth_dst_addr_c = 'X;
            eth_src_addr_c = 'X;
            eth_protocol_c = 'X;
            ip_version_c = 'X;
            ip_type_c = 'X;
            ip_length_c = 'X;
            ip_id_c = 'X;
            ip_flag_c = 'X;
            ip_time_c = 'X;
            ip_protocol_c = 'X;
            ip_checksum_c = 'X;
            ip_src_addr_c = 'X;
            ip_dst_addr_c = 'X;
            udp_dst_port_c = 'X;
            udp_src_port_c = 'X;
            udp_length_c = 'X;
            udp_length_c = 'X;
            udp_checksum_c = 'X;            
            udp_data_length_c = 'X;
            start_folding_c = 'X;
            start_bursting_c = 'X;
            burst_count_c = 'X;
            burst_overlap_c = 'X;
            
            in_rd_en = 1'b0;
            out_wr_en = 1'b0;
            out_din = 8'h00;
            error = 1'b0; 
        end

    endcase
end

endmodule