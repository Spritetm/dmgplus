/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */


`timescale 1us/1ns
module stimulus();

reg clk = 0, rst=0;

reg dmgplus_splash_ena;
wire cart_is_dmgplus;
wire dmgplus_ss_rom_read_done;
wire dmgplus_ss_done;

wire [1:0] splash_data;
wire splash_vram_w_clk;
wire [15:0] splash_vram_wr_ad;
wire splash_vram_we;

wire [15:0] rom_a;
reg [7:0] rom_dout;
wire rom_rd;
reg rom_bsy;
reg newframe;

dmgplus_splash_gen dmgplus_splash_gen_inst (
	.clk_8m(clk),
	.rst(rst),

	.ena(dmgplus_splash_ena),
	.in_vblank(newframe),

	.rom_addr(rom_a),
	.rom_data(rom_dout),
	.rom_rd(rom_rd),
	.rom_bsy(rom_bsy),

	.vramclk(splash_vram_w_clk),
	.vramaddr(splash_vram_wr_ad),
	.vramdata(splash_data),
	.vramwe(splash_vram_we),

	.is_dmgplus(cart_is_dmgplus),
	.rom_read_done(dmgplus_ss_rom_read_done),
	.splash_done(dmgplus_ss_done)
);


//clock toggle
always #1 clk = !clk;

reg [7:0] cartmem [0:65535];

//rom emu
always @(posedge rom_rd) begin
	rom_bsy <= 1;
	#10 rom_dout <= cartmem[rom_a];
	#1 rom_bsy <= 0;
end

integer i;
initial begin
	rst = 1;
	newframe = 0;
	dmgplus_splash_ena = 0;
	$dumpfile("dmgplus_splash_testbench.vcd");
	$dumpvars(0, stimulus);
	$readmemh("doom.mem", cartmem);
	#10 rst = 0;
	#10 dmgplus_splash_ena = 1;
	for (i=0; i<800; i++) begin
		#10 newframe <= 1;
		#1 newframe <= 0;
	end
	$finish;
end

endmodule