//DMG LCD controller, standalone version

module dmg_lcd_ctl (
	input wire rst,
	input wire clk_8m,
	
	output reg d0,
	output reg d1,
	output reg hsync,
	output reg vsync,
	output reg datal,
	output reg altsig,
	output reg clk,
	output reg control,

	output wire [8:0] xpos_out,
	output wire [7:0] ypos_out,
	input wire [1:0] data_in
);

reg [8:0] xpos;
reg [7:0] ypos;
reg int_clk;
reg [8:0] next_xpos;
reg [7:0] next_ypos;
reg is_even_frame, next_is_even_frame;

parameter VTOT='d170;
parameter HTOT='d500;

always @ (*) begin
	next_is_even_frame <= is_even_frame;
	if (xpos < HTOT) begin
		next_xpos <= xpos + 'h1;
		next_ypos <= ypos;
	end else begin
		next_xpos <= 0;
		if (ypos < VTOT) begin
			next_ypos <= ypos + 'h1;
		end else begin
			next_ypos <= 0;
			next_is_even_frame <= ~is_even_frame;
		end
	end
end

//Counters
always @ (posedge clk_8m or posedge rst) begin
	if (rst) begin 
		xpos <= 'h0;
		ypos <= 'h0;
		int_clk <= 0;
		is_even_frame <= 0;
	end else begin
		if (int_clk) begin
			int_clk <= 0;
		end else begin
			int_clk <= 1;
			ypos <= next_ypos;
			xpos <= next_xpos;
			is_even_frame <= next_is_even_frame;
		end
	end
end

parameter HPIXELSTART='d80;
parameter HPIXELEND='d240;
parameter VPIXELEND='d160;
parameter HSYNCSTART='d62;
parameter HSYNCCLK='d70;
parameter HSYNCEND='d78;
parameter DLATSTART='d485;
parameter DLATEND='d486;
parameter VSYNCOFF='d4;

reg [1:0] data_in_smp;
always @(posedge clk) begin
	data_in_smp <= data_in;
end

always @ (*) begin
	//pixel clock
	if (ypos < VPIXELEND && (xpos >= HPIXELSTART && xpos < HPIXELEND)) begin
		clk <= int_clk; 
	end else if (xpos==HSYNCCLK || xpos==HSYNCCLK+1) begin
		clk <= 1;
	end else begin
		clk <= 0;
	end
	//hsync
	if (xpos >= HSYNCSTART && xpos < HSYNCEND) hsync <= 1; else hsync <= 0;
	//vsync signal enable for first line
	vsync <= 0;
	if (ypos == 0 && xpos>VSYNCOFF) vsync <= 1;
	if (ypos == 1 && xpos<=VSYNCOFF) vsync <= 1;
	//control output... it's complicated
	if (xpos < 'd10 ||
		(xpos > 'd30 && xpos < 'd35) || 
		(xpos > 'd180 && xpos < 'd185) ||
		(xpos > 'd320 && xpos < 'd326) ||
		xpos >= DLATSTART) control <= 1; else control <= 0;
	//data latch
	if (xpos >= DLATSTART && xpos < DLATEND) datal <= 1; else datal <= 0;
	
	//pixel data
	if (xpos >= HPIXELSTART && xpos < HPIXELEND && ypos < VPIXELEND) begin
		d0 <= ~data_in_smp[0];
		d1 <= ~data_in_smp[1];
	end else begin
		d0 <= 0;
		d1 <= 0;
	end
end

assign xpos_out = xpos-HPIXELSTART;
assign ypos_out = ypos;
assign altsig = ypos[0] ^ is_even_frame;

endmodule
