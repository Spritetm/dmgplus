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
	input wire [7:0] cart_d_in,
	output reg [7:0] cart_d_out,
	output reg cart_ncs,
	output reg cart_nrd,
	output reg cart_nwr,
	output wire cart_clk,
	output wire cart_busdir
);

reg [1:0] cycle;
reg [15:0] cur_addr;
assign cart_a = cur_addr;
assign cart_busdir = ~cart_nrd;
assign busy = (cycle!='b00) | rd | wr;

/*
Note: According to https://dhole.github.io/post/gameboy_cartridge_emu_1/ , the GB Z80
has 1MHz memory cycles. We take a risk here by assuming the memory will also work at
2MHz.

Also note: we should make our accesses more like
https://gekkio.fi/blog/2018-02-05-errata-for-reverse-engineering-fine-details-of-game-boy-hardware.html
that is, keep /rd constantly low, use /cs to moderate reads, use a smaller /wr to write.
*/

always @(posedge clk_8m) begin
	if (rst) begin
		cycle <= 0;
		cart_ncs <= 1;
		cart_nwr <= 1;
		cart_nrd <= 1;
		cart_d_out <= 0;
		dout <= 'hff;
	end else begin
		if (cycle == 0 && (rd || wr)) begin
			cycle <= 1;
			cart_ncs <= 0;
			cur_addr <= addr;
			if (rd) begin
				//Read
				cart_nrd <= 0;
			end else begin
				//Write
				cart_d_out <= din;
				cart_nrd <= 1;
				cart_nwr <= 0; //note: write is longer when this is enabled
			end
		end else if (cycle==1) begin
			if (cart_nrd == 1) cart_nwr <= 0;
			cycle <= 2;
		end else if (cycle==2) begin
			cart_nwr <= 1; //note: nwr is lengthened by disabling this
			cycle <= 3;
			dout <= cart_d_in;
		end else if (cycle==3) begin
			cart_nwr <= 1;
			cart_ncs <= 1;
			cycle <= 0;
		end else if (cycle != 0) begin
			//fallback for if we ever add more cycles
			cycle <= cycle + 1;
		end
	end
end


//handle cart clock - should be 1MHz (and actually aligned with the bus accesses - I'm not
//sure if any cart actually cares about those though, so that's not implemented)
reg [2:0] cartclk_div;
always @(posedge clk_8m) begin
	if (rst) begin
		cartclk_div <= 'h0;
	end else begin
		cartclk_div <= cartclk_div + 'h1;
	end
end
assign cart_clk = cartclk_div[2];

endmodule