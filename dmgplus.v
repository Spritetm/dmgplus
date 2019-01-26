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
	output wire lp_dout,

	input wire spi_mosi,
	input wire spi_sck,
	input wire spi_cs,
	output wire spi_miso,

	output wire pwm_l,
	output wire pwm_r
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
//Mix in 1:0.5:0.25 rate, which is close-ish to the 1:0.5:0.16 rate we need
//This results in a rgb value of [0..11]. The ditherer in the video sampler will
//keep this in mind.
assign rpi_data=rpi_g[2:0]+rpi_r[1:0]+rpi_b[1];


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
wire [15:0] rom_a;
wire [7:0] rom_d;
wire [7:0] rom_din;
wire ssgen_rom_rd;
wire rom_bsy;
wire rom_rd, rom_wr;

cart_iface cart_iface_impl (
	.clk_8m(clk_8m),
	.rst(rst),
	.dout(rom_d),
	.din(rom_din),
	.addr(rom_a),
	.rd(rom_rd),
	.wr(rom_wr),
	.busy(rom_bsy),

	.cart_a(cart_a),
	.cart_d_out(cart_d_out),
	.cart_d_in(cart_d_in),
	.cart_nwr(cart_nwr),
	.cart_nrd(cart_nrd),
	.cart_ncs(cart_ncs),
	.cart_clk(cart_clk),
	.cart_busdir(cart_busdir)
);

wire [15:0] spicart_rom_a;
wire spicart_rom_rd, spicart_rom_wr;

spicart spi_cart_impl(
	.clk(clk_8m),
	.rst(rst),
	.spi_mosi(spi_mosi),
	.spi_miso(spi_miso),
	.spi_sck(spi_sck),
	.spi_cs(spi_cs),

	.cart_dout(rom_d),
	.cart_din(rom_din),
	.cart_a(spicart_rom_a),
	.cart_rd(spicart_rom_rd),
	.cart_wr(spicart_rom_wr),
	.cart_busy(rom_bsy)
);


/* Yosys doesn't do tristate nicely... instantiate it manually for the cart_d lines */
reg [7:0] cart_d_out;
wire [7:0] cart_d_in;
reg [7:0] cart_d_oe;
always @(*) begin
	if (cart_busdir) begin
		cart_d_oe = 'h00;
	end else begin
		cart_d_oe = 'hff;
	end
end

SB_IO #(
    .PIN_TYPE(6'b 1010_01),
    .PULLUP(1'b 0)
) cart_d_tris [7:0] (
    .PACKAGE_PIN(cart_d),
    .OUTPUT_ENABLE(cart_d_oe),
    .D_OUT_0(cart_d_out),
    .D_IN_0(cart_d_in)
);



wire pwm_out;
wire startup_done;
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
	.rom_bsy(rom_bsy),

	.pwm_out(pwm_out),
	.startup_done(startup_done)
);

always @(*) begin
	if (startup_done) begin
		rom_rd = spicart_rom_rd;
		rom_wr = spicart_rom_wr;
		rom_a = spicart_rom_a;
	end else begin
		rom_rd = ssgen_rom_rd;
		rom_wr = ssgen_rom_wr;
		rom_a = ssgen_rom_a;
	end
end


assign pwm_l = pwm_out;
assign pwm_r = pwm_out;

assign vram_rd_ad[15:8] = lcd_ypos;
assign vram_rd_ad[7:0] = lcd_xpos;

//assign gendata = lcd_xpos[4:3] ^ lcd_ypos[4:3];
assign gendata = startup_done?vram_gendata:startupscreen_gendata;
assign vram_w_data = vidsampler_data;
//assign vram_w_data = vram_wr_ad[4:3];

assign lp_dout = 0;

endmodule
