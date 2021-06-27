//SPI slave implementation
/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */


module spislave (
	input wire clk,
	input wire rst,

	input wire mosi,
	output wire miso,
	input wire sck,
	input wire cs,
	
	output reg [7:0] mdata,
	input wire [7:0] sdata,
	output wire data_valid_read,
	output wire data_firstbyte
);


reg [2:0] bit_sel;
reg [7:0] rdata;
reg [7:0] wdata;
reg first_byte;
reg sampled_mosi;
reg curr_firstbyte;

//Note: This implements SPI mode 0 with positive CS.
//Out-data is written on the falling edge of the signal (or CS becoming active), in-data is
//read on the rising edge.

assign miso = wdata[7];

reg flag_next_toggle;
reg flag_first_toggle;
reg [2:0] flag_next_resamp;
reg [2:0] flag_first_resamp;

//Sample mosi on posedge of clock
always @(posedge sck) begin
	sampled_mosi <= mosi;
end

reg cs_was_low;

//This gives a clock that is high while CS is low.
wire shift_maybe = sck | (!cs);

always @(posedge shift_maybe) begin
	if (cs==0) begin
		cs_was_low = 1;
	end else begin
		cs_was_low = 0;
	end
end

//shift on negedge
//note shift_maybe is forced high during no cs, so we don't need to check for cs here.
always @(negedge shift_maybe or posedge rst) begin
	if (rst) begin
		bit_sel <= 0;
		flag_next_toggle <= 0;
		flag_first_toggle <= 0;
		rdata <= 0;
	end else begin
		rdata <= {rdata[6:0], sampled_mosi};
		wdata <= {wdata[6:0], 1'b0};
		if (cs_was_low) begin
			bit_sel <= 0; //this is going to be the 0th bit
			wdata <= sdata;
			first_byte <= 1;
		end else begin
			if (bit_sel == 7) begin
				//last bit
				mdata <= {rdata[6:0], sampled_mosi};
				wdata <= sdata;
				flag_next_toggle <= !flag_next_toggle;
				if (curr_firstbyte) flag_first_toggle <= !flag_first_toggle;
				curr_firstbyte <= 0;
				bit_sel <= 0;
				if (first_byte) flag_first_toggle = !flag_first_toggle;
				first_byte <= 0;
			end else begin
				bit_sel <= bit_sel+1;
			end
		end
	end
end

always @(posedge clk) begin
	if (rst) begin
		flag_next_resamp=0;
		flag_first_resamp=0;
	end else begin
		flag_next_resamp <= { flag_next_resamp[1:0], flag_next_toggle };
		flag_first_resamp <= { flag_first_resamp[1:0], flag_first_toggle };
	end
end

assign data_valid_read = flag_next_resamp[2] ^ flag_next_resamp[1];
assign data_firstbyte = flag_first_resamp[2] ^ flag_first_resamp[1];


endmodule

