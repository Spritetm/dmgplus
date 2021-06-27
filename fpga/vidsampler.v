/*
This samples & dithers video. It also does clock domain crossing for the video signal
from the dpi pixel clock domain to the vram clock domain.
*/
/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */



module vidsampler (
	input wire rst,
	input wire rgb_clk,
	input wire rgb_de,
	input wire rgb_vsync,
	input wire [3:0] rgb_data,
	
	input wire vramclk,
	output wire [15:0] vramaddr,
	output wire [1:0] vramdata,
	output reg vramwe
);

reg [7:0] xpos;
reg [7:0] ypos;

wire [4:0] rgbdithered;
wire [1:0] ditherval;
reg [1:0] frameno;
//The incoming RGB value is [0..11].
//We dither by adding a (time and pixel position dependent) value between 0 and 7 to the pixel.
//This results in a range of [0..18].

//Note that for a b->w gradient, the expected sequence is
//0, 1, 3, 4, 7, 8, 10, 11

assign ditherval = xpos[3:2] + xpos[1:0] + ypos[2:0] + frameno;
//uncomment to show dithered on right, undithered on left
//assign rgbdithered = (xpos > 80) ? (rgb_data + ditherval) : (rgb_data[3:0]);
assign rgbdithered = (rgb_data + ditherval);

reg [1:0] dithered;
always @(*) begin
	if (rgbdithered<1) begin
		dithered=0;
	end else if (rgbdithered>=17) begin
		dithered=3;
	end else begin
		dithered=(rgbdithered-1)/4;
	end
end

/* Clock domain crossing */
reg [15:0] vramaddr_rgbclk;
reg [1:0] vramdata_rgbclk;
reg vramwe_toggle_rgbclk;
always @(posedge rgb_clk) begin
	if (rst) begin
		vramaddr_rgbclk <= 0;
		vramwe_toggle_rgbclk <= 0;
	end else begin
		if (rgb_de) begin
			vramwe_toggle_rgbclk <= !vramwe_toggle_rgbclk;
			vramaddr_rgbclk[15:8] <= ypos;
			vramaddr_rgbclk[7:0] <= xpos;
			vramdata_rgbclk <= dithered;
		end
	end
end

reg [2:0] vramwe_toggle_xclk;
reg [15:0] vramaddr_xclk[0:1];
reg [1:0] vramdata_xclk[0:1];
assign vramaddr = vramaddr_xclk[1];
assign vramdata = vramdata_xclk[1];
always @(posedge vramclk) begin
	vramwe_toggle_xclk[0]<=vramwe_toggle_rgbclk;
	vramwe_toggle_xclk[2:1]<=vramwe_toggle_xclk[1:0];
	vramaddr_xclk[0]<=vramaddr_rgbclk;
	vramaddr_xclk[1]<=vramaddr_xclk[0];
	vramdata_xclk[0]<=vramdata_rgbclk;
	vramdata_xclk[1]<=vramdata_xclk[0];
	vramwe <= (vramwe_toggle_xclk[2]!=vramwe_toggle_xclk[1]);
end

always @ (posedge rgb_clk or posedge rst) begin
	if (rst) begin
		xpos <= 0;
		ypos <= 0;
		frameno <= 0;
	end else begin
		if (rgb_de == 0) begin
			xpos <= 0;
			if (rgb_vsync == 1) begin
				if (ypos != 0) frameno <= frameno + 1;
				ypos <= 0;
			end else begin
				if (xpos != 0) begin
					ypos <= ypos+1;
				end
			end
		end else begin
			if (xpos != 8'hFF) begin
				xpos <= xpos + 1;
			end else begin
				//erm wtf
				xpos <= 0;
				ypos <= ypos + 1;
				frameno <= frameno + 1;
			end
		end
	end
end

endmodule
