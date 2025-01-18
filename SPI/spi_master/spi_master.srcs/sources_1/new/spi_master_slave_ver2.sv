module spi_master_slave_ver2 (
    clk,           
    reset,
	slave_rx_start,
	slave_tx_start,
	input_reg_data,
    dout_miso, 	
    cs_bar,       
    sclk,
	din_mosi,	
    output_reg_data,
    rx_valid,
	tx_done
);

	// I/o
	input	logic clk;           				// Internal clock
	input	logic reset;		
	input 	logic slave_rx_start;       		// rx_start spi transfer
	input 	logic slave_tx_start;       		// tx_start spi transfer
	input 	logic [31:0] input_reg_data; 		// 32-bit register output_reg_data write into slave
	input	logic dout_miso;        			// master In, Slave Out (Data from the ADC)
	output	logic cs_bar;       				// chip select, active low (to the ADC)
	output	logic sclk;         				// spi clock - 10 MHz
	output 	logic din_mosi;         			// spi output_reg_data out - ADC output_reg_data in
	output	logic [31:0] output_reg_data;  		// output_reg_data 
	output	logic rx_valid;         			// output_reg_data rx valid signal
	output 	logic tx_done;         				// spi tx completed flag
	

    // Param
    localparam integer CLK_DIV = 10; 					// Divide the system clock to gen sclk
    localparam integer CLK_DIV_BITS = $clog2(CLK_DIV);
    localparam integer WAIT_BITS = $clog2(5*CLK_DIV);
    localparam integer DATA_WIDTH = 32; 				// 32-bit SPI frame
    localparam integer DATA_WIDTH_BITS = $clog2(DATA_WIDTH); 				// 32-bit SPI frame

	// State machine
    typedef enum logic [1:0] {
        IDLE,
        TRANSFER,
        FINISH, 
		WAIT
    } state_t;

    state_t state;

    // Reg
    logic [DATA_WIDTH-1:0] rx_shift_reg;
    logic [DATA_WIDTH-1:0] tx_shift_reg;
    logic [DATA_WIDTH_BITS:0] rx_bit_cnt; 							// 6-bit to count 32 bits
    logic [DATA_WIDTH_BITS:0] tx_bit_cnt; 							// 6-bit to count 32 bits
    logic sclk_en;
    logic tx_ena;
    logic rx_ena;
    logic rx_state_flag;
    logic tx_state_flag;
    logic [WAIT_BITS-1:0] wait_cnt;
    logic [CLK_DIV_BITS-1:0] clk_div_cnt;

    // Clock gen
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_div_cnt <= CLK_DIV - 1;
            sclk <= 1;
        end 
		else if (sclk_en) begin
            if (clk_div_cnt == CLK_DIV - 1) begin
                clk_div_cnt <= 0;
                sclk <= ~sclk;
            end 
			else begin
                clk_div_cnt <= clk_div_cnt + 1;
            end
        end 
		else begin
            clk_div_cnt <= 0;
            sclk <= 1;
        end
    end

	// State Machine
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_bit_cnt <= 0;
            tx_bit_cnt <= 0;
            wait_cnt <= 0;
            cs_bar <= 1; 			
            sclk_en <= 0;
            rx_shift_reg <= 0;
            tx_shift_reg <= 0;
			tx_ena <= 0;
			rx_ena <= 0;
            rx_valid <= 0;
			tx_done <= 0;
			rx_state_flag <= 0;
			tx_state_flag <= 0;
			output_reg_data <= 0;
			din_mosi <= 0;
			
			state <= IDLE;
        end
		
		else begin
			case (state)
				IDLE: begin
					if (slave_rx_start | slave_tx_start) begin
						cs_bar <= 1; 		
						sclk_en <= 1; 
						rx_bit_cnt <= 0;
						tx_bit_cnt <= 0;
						wait_cnt <= 0;
						rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], dout_miso};
						tx_shift_reg <= input_reg_data;
						rx_valid <= 0;
						tx_done <= 0;
						rx_state_flag <= 0;
						tx_state_flag <= 0;
						
						if (slave_tx_start) tx_ena <= 1;
						else tx_ena <= 0;
						
						if (slave_rx_start) rx_ena <= 1;
						else rx_ena <= 0;
					
						state <= TRANSFER;
					end
					else begin
						state <= IDLE;
					end
				end

				TRANSFER: begin
					cs_bar <= 0; 		
					sclk_en <= 1;
					rx_valid <= 0;
					tx_done <= 0;
					
					if (sclk == 0 && clk_div_cnt == 1 && tx_ena) begin
						if (tx_bit_cnt == DATA_WIDTH ) begin
							tx_state_flag <= 1;
						end 
						else begin
							tx_bit_cnt <= tx_bit_cnt + 1;
							din_mosi <= tx_shift_reg[(DATA_WIDTH - 1) - tx_bit_cnt]; // Load output_reg_data on the low level of sclk
							tx_state_flag <= 0;					
						end
                    end
					
					if (sclk == 1 && clk_div_cnt == 0) begin
						rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], dout_miso}; // Shift in output_reg_data from ADC	
						if (rx_bit_cnt == DATA_WIDTH) begin
							rx_state_flag <= 1;
						end
						else begin
							rx_bit_cnt <= rx_bit_cnt + 1;
							rx_state_flag <= 0;
						end
					end
					
					if (rx_state_flag || tx_state_flag) begin
						state <= FINISH;
					end
					else begin
						state <= TRANSFER;
					end	
				end

				FINISH: begin
					if (sclk == 0 && clk_div_cnt == CLK_DIV-1) begin
						rx_bit_cnt <= 0;
						tx_bit_cnt <= 0;
						wait_cnt <= 0;
						tx_ena <= 0;
						sclk_en <= 1;
						cs_bar <= 0; 
						rx_valid <= 1;
						tx_done <= 1;
						output_reg_data <= rx_shift_reg[DATA_WIDTH-1:0];
						din_mosi <= 0;
						tx_shift_reg <= 0;
						rx_state_flag <= 0;
						tx_state_flag <= 0;
						
						state <= WAIT;
					end
					else begin
						state <= FINISH;
					end
				end				

				// Add the additional wait time between the output_reg_data frames for better reception of output_reg_data to the ADC
				WAIT: begin
					sclk_en <= 0; 
					cs_bar <= 1; 
					wait_cnt <= wait_cnt + 1;
					if (wait_cnt == 5*CLK_DIV-1) begin
						wait_cnt <= 0;
						state <= IDLE;
					end
					else begin
						state <= WAIT;
					end
                end
				
				default: state <= IDLE;
			endcase
		end
    end
endmodule
