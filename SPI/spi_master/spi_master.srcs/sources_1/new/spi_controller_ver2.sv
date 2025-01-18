module spi_controller_ver2(
	clk,
	reset,
	rx_start,
	tx_start,
    adc_dout_miso, 	
    adc_cs_bar,       
    adc_sclk,
	adc_din,
	channel_id,
	data,
	rx_valid,
	tx_done
);

	// I/o
	input 	logic	clk;
	input 	logic	reset;
	input 	logic	rx_start;
	input 	logic	tx_start;
    input 	logic	adc_dout_miso; 	
    output	logic	adc_cs_bar;       
    output	logic	adc_sclk;
	output	logic	adc_din;
	output	logic	[3:0] channel_id;
	output	logic	[11:0] data;
	output	logic	rx_valid;
	output	logic	tx_done;

	// Param
	localparam integer NUM_FRAMES = 16;
	localparam integer NUM_SET = 3;
	
	// Init
	logic [15:0] adc_mode_control [0:NUM_SET-1] = '{16'h0040, 16'h0020, 16'h2784}; // channels
	logic tx_done_prev;
	logic [1:0] current_set_idx;
	
	// Internal 
	// logic [3:0] frame_count;
	// logic rx_valid_prev;
	// logic rx_start_internal;
	
	
	// Instantiate SPI master slave module
	spi_master_slave_ver2 spi_master_slave_inst (
		.clk(clk),          
		.reset(reset),
		.rx_start(rx_start),
		.tx_start(tx_start),
	    .adc_reg_data(adc_mode_control[current_set_idx]),
	    .adc_dout_miso(adc_dout_miso),
        .adc_cs_bar(adc_cs_bar),  
        .adc_sclk(adc_sclk),
        .adc_din(adc_din),	
        .channel_id(channel_id), 
        .data(data),
        .rx_valid(rx_valid),
        .tx_done(tx_done)
	);
	
	// always_ff @(posedge clk or posedge reset) begin
		// if (reset) begin
			// adc_reg_data_in <= 16'h0000;
		// end
		// else begin
			// tx_start_prev = tx_start;
			// if (tx_start != tx_start_prev) begin
				// adc_reg_data_in <= 16'h2784;    // 16'h2784     // The last nibble 4 is to set chan_id 0/1, also based on ext/int clk mode
			// end
			// else begin
				// adc_reg_data_in <= 16'h2784;    // 16'h2784     // To verify and try both 0 & 4 are tested for the last nibble.
			// end
		// end
	// end
	
	always_ff @(negedge clk or negedge reset) begin
		if (reset) begin
			current_set_idx <= 0;
			tx_done_prev <= 0;
		end
		else begin
			if (tx_start) begin
				if (tx_done && !tx_done_prev) begin
					current_set_idx <= current_set_idx + 1;

					if (current_set_idx == NUM_SET - 1) begin
						current_set_idx <= 2;  // Loop back to the first set
					end
				end
				tx_done_prev = tx_done;
			end
			else begin
				current_set_idx <= 0;
			end
		end
	end
	
endmodule


