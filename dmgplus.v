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
reg [15:0] vram_wr_ad;
reg vram_w_clk;
reg vram_we;
reg [1:0] vram_w_data;
wire [1:0] vidsampler_data;
wire vidsampler_vram_w_clk;
wire [15:0] vidsampler_vram_wr_ad;
wire vidsampler_vram_we;

vidsampler vidsampler_inst (
	.rst(rst),
	.rgb_clk(rpi_pclk),
	.rgb_de(rpi_dataen),
	.rgb_vsync(rpi_vsync),
	.rgb_data(rpi_data),
	.vramclk(vidsampler_vram_w_clk),
	.vramaddr(vidsampler_vram_wr_ad),
	.vramdata(vidsampler_data),
	.vramwe(vidsampler_vram_we),
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
wire [15:0] spicart_rom_a;
reg [15:0] rom_a;
wire [7:0] rom_dout;
wire [7:0] rom_din;
wire ssgen_rom_rd;
wire spicart_rom_rd, spicart_rom_wr;
wire rom_bsy;
reg rom_rd, rom_wr;
reg [7:0] cart_d_out;
wire [7:0] cart_d_in;

cart_iface cart_iface_impl (
	.clk_8m(clk_8m),
	.rst(rst),
	.dout(rom_dout),
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


spicart spi_cart_impl(
	.clk(clk_8m),
	.rst(rst),
	.spi_mosi(spi_mosi),
	.spi_miso(spi_miso),
	.spi_sck(spi_sck),
	.spi_cs(spi_cs),

	.cart_dout(rom_dout),
	.cart_din(rom_din),
	.cart_a(spicart_rom_a),
	.cart_rd(spicart_rom_rd),
	.cart_wr(spicart_rom_wr),
	.cart_busy(rom_bsy)
);


/* Yosys doesn't do tristate nicely... instantiate it manually for the cart_d lines */
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
wire startup_rom_read_done;
startupscreen_gen startupscreen_inst (
	.clk_8m(clk_8m),
	.rst(rst),
	.lcd_xpos(lcd_xpos),
	.lcd_ypos(lcd_ypos),
	.lcd_data(startupscreen_gendata),
	.lcd_newframe(newframe),

	.rom_addr(ssgen_rom_a),
	.rom_data(rom_dout),
	.rom_rd(ssgen_rom_rd),
	.rom_bsy(rom_bsy),

	.pwm_out(pwm_out),
	.rom_read_done(startup_rom_read_done),
	.startup_done(startup_done)
);

wire dmgplus_splash_ena;
wire cart_is_dmgplus;
wire dmgplus_splash_rom_read_done;
wire dmgplus_splash_done;

wire [1:0] splash_data;
wire splash_vram_w_clk;
wire [15:0] splash_vram_wr_ad;
wire splash_vram_we;

reg [15:0] splgen_rom_a;
reg splgen_rom_rd;


dmgplus_splash_gen dmgplus_splash_gen_inst (
	.clk_8m(clk_8m),
	.rst(rst),

	.ena(dmgplus_splash_ena),
	.lcd_newframe(newframe),

	.rom_addr(splgen_rom_a),
	.rom_data(rom_dout),
	.rom_rd(splgen_rom_rd),
	.rom_bsy(rom_bsy),

	.vramclk(splash_vram_w_clk),
	.vramaddr(splash_vram_wr_ad),
	.vramdata(splash_data),
	.vramwe(splash_vram_we),

	.is_dmgplus(cart_is_dmgplus),
	.rom_read_done(dmgplus_splash_rom_read_done),
	.splash_done(dmgplus_splash_done)
);

//note: with this, splash delay will start counting almost immediately after power up
assign dmgplus_splash_ena = startup_rom_read_done;
//With this, counting starts after the startup screen, but this means the cart iface
//is unaccessible when the Pi already is booted into user space.
//assign dmgplus_splash_ena = startup_done;

//spicart iface mux
always @(*) begin
	if (!startup_rom_read_done) begin
		rom_rd = ssgen_rom_rd;
		rom_wr = 0;
		rom_a = ssgen_rom_a;
	end else if (!dmgplus_splash_rom_read_done) begin
		rom_rd = splgen_rom_rd;
		rom_wr = 0;
		rom_a = splgen_rom_a;
	end else begin
		rom_rd = spicart_rom_rd;
		rom_wr = spicart_rom_wr;
		rom_a = spicart_rom_a;
	end
end

//vram write mux
//note startup screen writes directly to the LCD iface
/*
Problem here: the write clock is gated, causing all sorts of fancy issues and corruption in both modes.
We can solve this by connecting it to one clock and cross domains from the other clock to this.
Theoretically, the RGB clock is 3.2MHz, so we can use something simple for this...
*/
always @(*) begin
	if (dmgplus_splash_done) begin
		vram_w_clk = vidsampler_vram_w_clk;
		vram_wr_ad = vidsampler_vram_wr_ad;
		vram_w_data = vidsampler_data;
		vram_we = vidsampler_vram_we;
	end else begin
		vram_w_clk = splash_vram_w_clk;
		vram_wr_ad = splash_vram_wr_ad;
		vram_w_data = splash_data;
		vram_we = splash_vram_we;
	end
end

assign pwm_l = pwm_out;
assign pwm_r = pwm_out;

assign vram_rd_ad[15:8] = lcd_ypos;
assign vram_rd_ad[7:0] = lcd_xpos;

//assign gendata = lcd_xpos[4:3] ^ lcd_ypos[4:3];
assign gendata = startup_done?vram_gendata:startupscreen_gendata;
//assign vram_w_data = vram_wr_ad[4:3];

assign lp_dout = 0;

endmodule
