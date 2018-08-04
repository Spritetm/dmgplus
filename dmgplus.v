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
	output wire lcd_control
);

wire rst;
wire [7:0] lcd_xpos;
wire [7:0] lcd_ypos;

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
	.cur_xpos(lcd_xpos),
	.cur_ypos(lcd_ypos)
);

assign rst = ~rstn;

assign led = lcd_ypos;

endmodule
