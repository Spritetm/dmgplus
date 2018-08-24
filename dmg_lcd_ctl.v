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

//Note: Clock is 8MHz, int_clk is 4MHz, meaning a cycle time of 0.25uS.

parameter VFPORCH='d10; //lines from inversion of altline to vsync / pixels start
parameter VTOT='d143+VFPORCH; //total amount of lines
parameter VPIXELEND='d160;
parameter HTOT='d435; //total time in one line, in clk cycles
parameter HPIXELSTART='d88; //start of pixel output, in clks
parameter HPIXELEND=HPIXELSTART+'d160; //end of pixel output, in clks
parameter HSYNCSTART='d73;
parameter HSYNCCLK='d80; //pos of single clk pulse during hsync
parameter HSYNCEND='d87;
parameter DLATSTART='d430;
parameter DLATEND='d434; //1uS
parameter VSYNCOFF='d2;

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

reg d0_c;
reg d1_c;
reg hsync_c;
reg vsync_c;
reg datal_c;
reg altsig_c;
reg clk_c;
reg control_c;

always @ (posedge clk_8m) begin
	do <= d0_c;
	d1 <= d1_c;
	hsync <= hsync_c;
	vsync <= vsync_c;
	datal <= datal_c;
	altsig <= altsig_c;
	clk <= clk_c;
	control <= control_c;
end


//Note: Clock is 8MHz, int_clk is 4MHz, meaning a cycle time of 0.25uS.

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

reg [1:0] data_in_smp;
always @(posedge clk) begin
	data_in_smp <= data_in;
end

always @ (*) begin
	//pixel clock
	if (ypos < VFPORCH) begin
		clk_c <= 0; //no pixels here
	end else if (ypos < VPIXELEND && (xpos >= HPIXELSTART && xpos < HPIXELEND)) begin
		clk_c <= int_clk; 
	end else if (xpos==HSYNCCLK) begin
		clk_c <= int_clk;
	end else begin
		clk_c <= 0;
	end
	//hsync
	if (ypos >= VFPORCH && xpos >= HSYNCSTART && xpos < HSYNCEND) begin
		hsync_c <= 1; 
	end else begin
		hsync_c <= 0;
	end
	//vsync signal enable for first line
	vsync_c <= 0;
	if (ypos == VFPORCH && xpos>=VSYNCOFF) vsync_c <= 1;
	if (ypos == VFPORCH+1 && xpos<VSYNCOFF) vsync_c <= 1;
	//control output... it's complicated
	if (xpos < 'd4 ||
		(xpos >= 'd26 && xpos < 'd30) || 
		(xpos >= 'd171 && xpos < 'd175) ||
		(xpos >= 'd317 && xpos < 'd320) ||
		xpos >= DLATSTART) control_c <= 1; else control_c <= 0;
	//data latch
	if (xpos >= DLATSTART && xpos < DLATEND) datal_c <= 1; else datal_c <= 0;
	
	//pixel data
	if (ypos >= VFPORCH && xpos >= HPIXELSTART && xpos < HPIXELEND && ypos < VPIXELEND) begin
//		d0_c <= ~data_in_smp[0];
//		d1_c <= ~data_in_smp[1];
		d1_c <= xpos[4]^ypos[4];
		d0_c <= xpos[3]^ypos[3];
	end else begin
		d0_c <= 0;
		d1_c <= 0;
	end
end

assign xpos_out = xpos-HPIXELSTART;
assign ypos_out = ypos-VFPORCH;
assign altsig_c = ypos[0] ^ is_even_frame;

endmodule
