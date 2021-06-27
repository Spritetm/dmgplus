//Interface for the Raspberry Pi to interface with the GB cartridge using SPI.
/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */

module spicart (
	input clk,
	input rst,
	
	input spi_mosi,
	output spi_miso,
	input spi_sck,
	input spi_cs,
	
	input [7:0] cart_dout,
	output [7:0] cart_din,
	output reg [15:0] cart_a,
	output cart_wr,
	output cart_rd,
	input cart_busy
);

wire [7:0] data_master;
wire [7:0] data_slave;
wire data_valid_read, data_firstbyte;
reg cart_wr;
reg cart_rd;

spislave i_spislave(
	.clk(clk),
	.rst(rst),
	.mosi(spi_mosi),
	.miso(spi_miso),
	.sck(spi_sck),
	.cs(spi_cs),
	.mdata(data_master),
	.sdata(data_slave),
	.data_valid_read(data_valid_read),
	.data_firstbyte(data_firstbyte)
);

reg[1:0] bytectr;
reg is_write;

assign cart_din = data_master; //won't actually write until cart_wr is triggered
assign data_slave = cart_dout;

always @(posedge clk) begin
	if (rst) begin
		bytectr <= 0;
		is_write <= 0;
		cart_wr <= 0;
		cart_rd <= 0;
		cart_a <= 0;
	end else begin
		cart_wr <= 0;
		cart_rd <= 0;
		if (data_valid_read) begin
			if (data_firstbyte) begin
				bytectr <= 0;
				cart_a[15:8] <= data_master[6:0];
				is_write <= data_master[7];
			end else begin
				if (bytectr == 0) begin
					cart_a[7:0] <= data_master;
				end else if (is_write) begin
					//need to start to write only after we have the 1st data byte.
					cart_wr <= 1;
				end 
				if (!is_write) begin
					//but we must start reading _before_ the 1st data byte
					cart_rd <= 1;
				end
				//Don't roll over
				if (bytectr!=3) bytectr<=bytectr+1;
			end
		end
		if (cart_wr || cart_rd) begin
			//prepare for next addr;
			cart_a <= cart_a + 1;
		end
	end
end


endmodule
