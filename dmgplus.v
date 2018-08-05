module dmgplus_top (
	input wire clk_12m,
	input wire rstn,
	input wire [3:0] dipsw,
	output wire [7:0] led,

	output wire lcd_hsync,
	output wire lcd_vsync,
	output wire lcd_altsig,
	output wire lcd_clk,
	output wire lcd_d0,
	output wire lcd_d1,
	output wire lcd_datal,
	output wire lcd_control,

	input wire rgb_de,
	input wire rgb_clk,
	input wire rgb_hsync,
	input wire rgb_vsync,
	input wire rgb_r0,
	input wire rgb_g0,
	input wire rgb_g1,
	input wire rgb_b0
);

wire rst;
wire [8:0] lcd_xpos;
wire [7:0] lcd_ypos;
wire [1:0] gendata;

dmg_lcd_ctl dmg_lcd_ctl_inst (
	.clk_8m(clk_12m),
	.rst(rst),
	.hsync(lcd_hsync),
	.vsync(lcd_vsync),
	.altsig(lcd_altsig),
	.clk(lcd_clk),
	.d0(lcd_d0),
	.d1(lcd_d1),
	.datal(lcd_datal),
	.control(lcd_control),
	.xpos_out(lcd_xpos),
	.ypos_out(lcd_ypos),
	.data_in(gendata)
);

wire [1:0] rgb_data;
assign rgb_data[0] = rgb_g0;
assign rgb_data[1] = rgb_r0;

wire [15:0] vram_rd_ad;
wire [15:0] vram_wr_ad;

wire vram_w_clk;
wire vram_we;
reg [1:0] vram_w_data;
wire [1:0] vidsampler_data;

vidsampler vidsampler_inst (
	.rst(rst),
	.rgb_clk(rgb_clk),
	.rgb_de(rgb_de),
	.rgb_vsync(rgb_vsync),
//	.rgb_hsync(rgb_hsync),
	.rgb_data(rgb_data),
	.vramclk(vram_w_clk),
	.vramaddr(vram_wr_ad),
	.vramdata(vidsampler_data),
	.vramwe(vram_we)
);

vram vram_inst (
	.WrAddress(vram_wr_ad),
	.Data(vram_w_data),
	.WE(vram_we),
	.WrClock(vram_w_clk),
	.WrClockEn(1'b1),
	.RdAddress(vram_rd_ad),
	.Q(gendata),
	.RdClock(clk_12m),
	.RdClockEn(1'b1),
	.Reset(rst)
);

assign rst = ~rstn;
assign led = ~vram_wr_ad[15:8];
assign vram_rd_ad[15:8] = lcd_ypos;
assign vram_rd_ad[7:0] = lcd_xpos;

always @* begin
	if (dipsw[1:0] == 2'd0) begin
		vram_w_data = vidsampler_data;
	end else if (dipsw[1:0] == 2'd1) begin
		vram_w_data = 2'b11;
	end else if (dipsw[1:0] == 2'd2) begin
		vram_w_data = 2'b00;
	end else if (dipsw[1:0] == 2'd3) begin
		vram_w_data = vram_wr_ad[12:11]^vram_wr_ad[4:3];
	end
end


endmodule
