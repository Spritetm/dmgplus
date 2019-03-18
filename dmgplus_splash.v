
//This code reads out the cart; location 0x100-0x103 stores 'DMG+' if this is a
//dummy cart. If this is detected, the is_dmgplus line will go high and the cart
//will read the data from 0x134 into VRAM. Data at loc 0xfe-0xff will be an 16-bit
//delay value indicating how many cycles to wait before raising the splash_done
//line. (This gets raised immediately for a non-dmg+ cart.)

module dmgplus_splash_gen (
	input wire clk_8m,
	input wire rst,

	input wire ena,
	input wire lcd_newframe,

	//ROM iface
	output reg [15:0] rom_addr,
	input wire [7:0] rom_data,
	output reg rom_rd,
	input wire rom_bsy,

	//VRAM iface
	output wire vramclk,
	output wire [15:0] vramaddr,
	output reg [1:0] vramdata,
	output reg vramwe,

	//Status lines
	output reg is_dmgplus,
	output reg rom_read_done,
	output reg splash_done
);

assign vramclk = clk_8m;

//This logic reads 0x100-0x103 and checks if it contains 'DMG+'; it also loads the VRAM
//with the contents of 0x134 and further.
reg check_sig_done;
reg need_read_byte;
reg [1:0] pixelno;
reg [7:0] xpos;
reg [7:0] ypos;
reg [15:0] delay_frames;
always @(posedge clk_8m) begin
	if (rst || !ena) begin
		check_sig_done <= 0;
		rom_read_done <= 0;
		is_dmgplus <= 1;
		need_read_byte <= 1;
		pixelno <= 'b00;
		splash_done <= 0;
		rom_addr <= 'hfe;
		xpos <= -1;
		ypos <= -1;
	end else begin
		rom_rd <= 0;
		vramwe <= 0;
		if (rom_read_done) begin
			//delay splash_done as indicated by header
			if (!is_dmgplus) begin
				splash_done <= 1;
			end else begin
				if (lcd_newframe) begin
					delay_frames <= delay_frames - 1;
				end
				if (delay_frames == 0) begin
					splash_done <= 1;
				end
			end
		end else if (need_read_byte) begin
			rom_rd <= 1;
			need_read_byte <= 0;
		end else if (rom_bsy) begin
			//wait until byte is read
		end else if (!check_sig_done) begin
			if (rom_addr[2:0]==6) delay_frames[7:0] <= rom_data;
			if (rom_addr[2:0]==7) delay_frames[15:8] <= rom_data;
			if (rom_addr[2:0]==0 && rom_data!='h44) is_dmgplus <= 0;
			if (rom_addr[2:0]==1 && rom_data!='h4D) is_dmgplus <= 0;
			if (rom_addr[2:0]==2 && rom_data!='h47) is_dmgplus <= 0;
			if (rom_addr[2:0]==3 && rom_data!='h2B) is_dmgplus <= 0;
			if (!is_dmgplus) begin
				//No dmgplus cart; abort.
				rom_read_done <= 1;
			end
			if (rom_addr[2:0]==3) begin
				check_sig_done <= 1;
				rom_addr <= 'h134;
			end else begin
				rom_addr <= rom_addr + 1;
			end
			need_read_byte <= 1;
		end else begin //check_sig_done
			if (pixelno == 0) begin
				pixelno <= 1;
				vramdata <= rom_data[7:6];
			end else if (pixelno == 1) begin
				pixelno <= 2;
				vramdata <= rom_data[5:4];
			end else if (pixelno == 2) begin
				pixelno <= 3;
				vramdata <= rom_data[3:2];
			end else if (pixelno == 3) begin
				pixelno <= 0;
				vramdata <= rom_data[1:0];
				rom_addr <= rom_addr + 1;
`ifdef __ICARUS__
				//simulation: stop at 2 lines
				if (ypos < 2) begin
`else
				if (ypos < 143) begin
`endif
					need_read_byte <= 1;
				end else begin
					rom_read_done <= 1;
				end
			end
			vramwe <= 1;
			if (xpos < 159) begin
				xpos <= xpos + 1;
			end else begin
				xpos <= 0;
				ypos <= ypos + 1;
			end
		end
	end
end

assign vramaddr[15:8] = ypos;
assign vramaddr[7:0] = xpos;


endmodule