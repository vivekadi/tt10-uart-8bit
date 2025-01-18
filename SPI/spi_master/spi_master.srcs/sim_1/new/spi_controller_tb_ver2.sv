module spi_controller_tb_ver2;

    // Param
    localparam CLK_PERIOD = 10; // 100 MHz system clock

    // Signals
    logic clk;
    logic reset;
    logic rx_start;
    logic tx_start;
    logic adc_dout_miso;
    logic adc_cs_bar;   
    logic adc_sclk;
	logic adc_din;
	logic [3:0] channel_id;
	logic [11:0] data;
	logic rx_valid;
	logic tx_done;

    // Inst SPI master salve module
    spi_controller_ver2 uut (
        .clk(clk),
        .reset(reset),
        .rx_start(rx_start),
        .tx_start(tx_start),
        .adc_dout_miso(adc_dout_miso),
        .adc_cs_bar(adc_cs_bar),   
        .adc_sclk(adc_sclk),
        .adc_din(adc_din),
	    .channel_id(channel_id),
	    .data(data),
	    .rx_valid(rx_valid),
	    .tx_done(tx_done)
	);

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

	logic [15:0] test_data [0:3];
    integer i;


    // Test sequence
    initial begin
	
		// Initialize test data
		for (i = 0; i <=3; i++) begin
            test_data[i] = {i[3:0], 12'h111}; // Channel ID is i, data is 0xABC
        end
	
        // Initialize signals
        reset = 1;
        rx_start = 0;
        tx_start = 0;
		adc_dout_miso = 0;
		
        // remove reset
        #200;
        reset = 0;
		
		#200;
		@(posedge clk);
		tx_start = 1;
		
		
//		rx_start = 0;
//		for (i = 0; i <=3; i++) begin
//			// Send first 12-bit dac_data value
//			// @(posedge clk);
			
//			// @(posedge clk);
			
			
//			// Simulate MISO data from the ADC
//			repeat (16) begin
//				@(posedge adc_cs_bar or posedge adc_sclk); // Wait for rise edge of sclk
//				adc_dout_miso = test_data[i][15]; // Send MSB first
//				test_data[i] = test_data[i] << 1; // Shift to next bit
//			end

//			// Wait for data to be received
//			@(posedge clk);
//			while (!rx_valid) @(posedge clk);
//		end	
//		rx_start = 0;
		
		


    end
endmodule
