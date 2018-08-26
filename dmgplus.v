module dmgplus_top (
	output wire lcd_hsync,
	output wire lcd_vsync,
	output wire lcd_altsig,
	output wire lcd_clk,
	output wire [1:0] lcd_d,
	output wire lcd_datal,
	output wire lcd_control,
	
	input wire rpi_dataen,
	input wire rpi_pclk,
	input wire rpi_vsync,
	input wire [1:0] rpi_r,
	input wire [2:0] rpi_g,
	input wire [1:0] rpi_b,
	
	output wire [15:0] cart_a,
	inout wire [7:0] cart_d,
	input wire cart_nrst,
	output wire cart_ncs,
	output wire cart_nrd,
	output wire cart_nwr,
	output wire cart_clk,
	output wire cart_busdir,

	inout wire lp_clk,
	inout wire lp_gp,
	input wire lp_din,
	output wire lp_dout
);


wire clk_8m;

//Flipping heck, the ICE40HX has no internal oscillator, and the design doesn't have an external one.
//Hack up a ring osc to do the job for now.
wire [69:0] buffers_in, buffers_out;
wire chain_in, chain_out;
assign buffers_in = {buffers_out[68:0], chain_in};
assign chain_out = buffers_out[69];
assign chain_in = !chain_out;
SB_LUT4 #(
	.LUT_INIT(16'd2)
) buffers [69:0] (
	.O(buffers_out),
	.I0(buffers_in),
	.I1(1'b0),
	.I2(1'b0),
	.I3(1'b0)
);
assign clk_8m = chain_out;

/* simple reset signal generator */
wire rst;
reg [3:0] rststate = 0;
assign rst = !(&rststate);
always @(posedge clk_8m) rststate <= rststate + rst;


wire [8:0] lcd_xpos;
wire [7:0] lcd_ypos;
wire [1:0] vram_gendata;
wire [1:0] startupscreen_gendata;
wire[1:0] gendata;
wire newframe;

dmg_lcd_ctl dmg_lcd_ctl_inst (
	.clk_8m(clk_8m),
	.rst(rst),
	.hsync(lcd_hsync),
	.vsync(lcd_vsync),
	.altsig(lcd_altsig),
	.clk(lcd_clk),
	.d0(lcd_d[0]),
	.d1(lcd_d[1]),
	.datal(lcd_datal),
	.control(lcd_control),
	.xpos_out(lcd_xpos),
	.ypos_out(lcd_ypos),
	.data_in(gendata),
	.newframe(newframe)
);

wire [3:0] rpi_data;
//assign rgb_data = (rgb_g0?3'd4:0)|(rgb_g1?3'd2:0)|(rgb_r0?3'd1:0)|(rgb_b0?3'd1:0);
assign rpi_data[3]=(rpi_g[2]);
assign rpi_data[2]=(rpi_g[1]);
assign rpi_data[1]=(rpi_g[0]);
assign rpi_data[0]=(rpi_r[1])|(rpi_b[1]);


wire [15:0] vram_rd_ad;
wire [15:0] vram_wr_ad;
wire vram_w_clk;
wire vram_we;
reg [1:0] vram_w_data;
wire [1:0] vidsampler_data;

vidsampler vidsampler_inst (
	.rst(rst),
	.rgb_clk(rpi_pclk),
	.rgb_de(rpi_dataen),
	.rgb_vsync(rpi_vsync),
	.rgb_data(rpi_data),
	.vramclk(vram_w_clk),
	.vramaddr(vram_wr_ad),
	.vramdata(vidsampler_data),
	.vramwe(vram_we),
	.do_dither(1)
);

vram vram_inst (
	.WrAddress(vram_wr_ad),
	.Data(vram_w_data),
	.WE(vram_we),
	.WrClock(vram_w_clk),
	.WrClockEn(1'b1),
	.RdAddress(vram_rd_ad),
	.Q(vram_gendata),
	.RdClock(clk_8m),
	.RdClockEn(1'b1),
	.Reset(rst)
);

wire [15:0] ssgen_rom_a;
wire [7:0] rom_d;
wire ssgen_rom_rd;
wire rom_bsy;

cart_iface cart_iface_impl (
	.clk_8m(clk_8m),
	.rst(rst),
	.dout(rom_d),
	.din('b0),
	.addr(ssgen_rom_a),
	.rd(ssgen_rom_rd),
	.wr(0),
	.busy(rom_bsy),

	.cart_a(cart_a),
	.cart_d(cart_d),
	.cart_nwr(cart_nwr),
	.cart_nrd(cart_nrd),
	.cart_ncs(cart_ncs),
	.cart_clk(cart_clk),
	.cart_busdir(cart_busdir)
);


startupscreen_gen startupscreen_inst (
	.clk_8m(clk_8m),
	.rst(rst),
	.lcd_xpos(lcd_xpos),
	.lcd_ypos(lcd_ypos),
	.lcd_data(startupscreen_gendata),
	.lcd_newframe(newframe),

	.rom_addr(ssgen_rom_a),
	.rom_data(rom_d),
	.rom_rd(ssgen_rom_rd),
	.rom_bsy(rom_bsy)
);


assign vram_rd_ad[15:8] = lcd_ypos;
assign vram_rd_ad[7:0] = lcd_xpos;

//assign gendata = lcd_xpos[4:3] ^ lcd_ypos[4:3];
assign gendata = startupscreen_gendata;
assign vram_w_data = vidsampler_data;
//assign vram_w_data = vram_wr_ad[4:3];

endmodule
