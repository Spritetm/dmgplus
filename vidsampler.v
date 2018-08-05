module vidsampler (
	input wire rst,
	input wire rgb_clk,
	input wire rgb_de,
	input wire rgb_vsync,
	input wire [1:0] rgb_data,
	
	output wire vramclk,
	output wire [15:0] vramaddr,
	output wire [1:0] vramdata,
	output wire vramwe
);

reg [7:0] xpos;
reg [7:0] ypos;

assign vramclk = rgb_clk;
assign vramdata = rgb_data;
assign vramwe = rgb_de;
assign vramaddr[15:8] = ypos;
assign vramaddr[7:0] = xpos;

always @ (posedge rgb_clk or posedge rst) begin
	if (rst) begin
		xpos <= 0;
		ypos <= 0;
	end else begin
		if (rgb_de == 0) begin
			xpos <= 0;
			if (rgb_vsync == 1) begin
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
			end
		end
	end
end

endmodule
