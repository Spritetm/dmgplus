module cart_iface (
	input wire clk_8m,
	input wire rst,
	
	output reg [7:0] dout,
	input wire [7:0] din,
	input wire [15:0] addr,
	input wire rd,
	input wire wr,
	output wire busy,
	
	output wire [15:0] cart_a,
	inout wire [7:0] cart_d,
	output reg cart_ncs,
	output reg cart_nrd,
	output reg cart_nwr,
	output reg cart_clk,
	output wire cart_busdir
);

/* Yosys doesn't do tristate nicely... instantiate it manually for the cart_d lines */
wire [7:0] cart_d_out;
reg [7:0] cart_d_in;
wire [7:0] cart_d_oe;
SB_IO #(
    .PIN_TYPE(6'b 1010_01),
    .PULLUP(1'b 0)
) cart_d [7:0] (
    .PACKAGE_PIN(cart_d),
    .OUTPUT_ENABLE(cart_d_oe),
    .D_OUT_0(cart_d_out),
    .D_IN_0(cart_d_in)
);



reg [1:0] cycle;
reg [15:0] cur_addr;
assign cart_a = cur_addr;
assign cart_d_oe = cart_nrd ? 8'hff : 8'h00;
assign cart_busdir = ~cart_nrd;
assign busy = (cycle!='b00) | rd | wr;

/*
Note: According to https://dhole.github.io/post/gameboy_cartridge_emu_1/ , the GB Z80
has 1MHz memory cycles. We take a risk here by assuming the memory will also work at
2MHz.
*/

always @(posedge clk_8m) begin
	if (rst) begin
		cycle <= 0;
		cart_ncs <= 1;
		cart_nwr <= 1;
		cart_nrd <= 1;
	end else begin
		if (cycle == 0 && (rd || wr)) begin
			cycle <= 1;
			cart_ncs <= 0;
			cur_addr <= addr;
			cart_d_out <= din;
			if (rd) begin
				//Read
				cart_nrd <= 0;
			end else begin
				//Write
				cart_nwr <= 0;
			end
		end else if (cycle==3) begin
			cart_nrd <= 1;
			cart_nwr <= 1;
			cart_ncs <= 1;
			cycle <= 0;
			dout <= cart_d_in;
		end else if (cycle != 0) begin
			cycle <= cycle + 1;
		end
	end
end


//handle cart clock - should be 1MHz (and actually aligned with the bus accesses - I'm not
//sure if any cart actually cares about those though, so that's not implemented)
reg cartclk_div[2:0];
always @(posedge clk_8m) begin
	if (rst) begin
		cartclk_div <= 0;
	end else begin
		cartclk_div <= cartclk_div + 1;
	end
end
assign cart_clk = cartclk_div[2];

endmodule