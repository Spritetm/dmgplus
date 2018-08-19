module vidsampler (
	input wire rst,
	input wire rgb_clk,
	input wire rgb_de,
	input wire rgb_vsync,
	input wire [3:0] rgb_data,
	input wire do_dither,
	
	output wire vramclk,
	output wire [15:0] vramaddr,
	output wire [1:0] vramdata,
	output wire vramwe
);

reg [7:0] xpos;
reg [7:0] ypos;

wire [4:0] rgbdithered;
wire [1:0] ditherval;
reg [1:0] frameno;
assign ditherval = xpos[1:0] + ypos[1:0] + frameno;
assign rgbdithered = rgb_data + (ditherval) + 'd2;
assign vramdata = do_dither ? rgbdithered[4:3] : rgb_data[3:2];

assign vramclk = rgb_clk;
assign vramwe = rgb_de;
assign vramaddr[15:8] = ypos;
assign vramaddr[7:0] = xpos;

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
