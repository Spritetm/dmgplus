//Startupscreen generator. This controls the LCD and sound generator to produce the scrolling-down
//Nintendo cartridge startup screen.
/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */

module startupscreen_gen (
	input wire clk_8m,
	input wire rst,

	input wire [8:0] lcd_xpos,
	input wire [7:0] lcd_ypos,
	output reg [1:0] lcd_data,
	input wire lcd_newframe,

	output wire [15:0] rom_addr,
	input wire [7:0] rom_data,
	output reg rom_rd,
	input wire rom_bsy,

	output wire pwm_out,
	output reg rom_read_done,
	output wire startup_done,

	input is_dmgplus
);


reg [10:0] sound_freq;
reg sound_start;
sndgen sndgen_inst(
	.clk_8m(clk_8m),
	.rst(rst),
	.start_sound(sound_start),
	.freq(sound_freq),
	.pwm(pwm_out)
);

/*
Logo is stored weirdly on cart... http://i.imgur.com/BikSgOo.png
We flatten it while reading.
*/

reg logo_data[0:47][0:7];
reg [9:0] vblanks;
reg [7:0] scroll;
reg [7:0] rsign[7:0];

reg [8:0] i;
reg [3:0] j;
initial begin
	//Store (R) sign
	rsign[0]<='b00111100;
	rsign[1]<='b01000010;
	rsign[2]<='b10011101;
	rsign[3]<='b10100101;
	rsign[4]<='b10011101;
	rsign[5]<='b10100101;
	rsign[6]<='b01000010;
	rsign[7]<='b00111100;
	//Fill logo data with nifty pattern so we can see if cart reading works
	i=0;
	for (i=0; i<48; i=i+1) begin
		for (j=0; j<8; j=j+1) begin
			logo_data[i][j] <= (i^j)&1;
		end
	end
end


//Routine to read rom from cart
reg [15:0] cart_raddr;
reg [2:0] logo_wbit;
reg [7:0] logo_rdat;

assign rom_addr = cart_raddr;

reg logow_row;
reg [5:0] logow_xpos;
reg [2:0] logow_ypos;
reg[15:0] logo_addr;

always @(*) begin
	if (cart_raddr > 'd283) begin
		logo_addr = cart_raddr - 'd284;
		logow_row = 1;
	end else begin
		logo_addr = cart_raddr - 'd260;
		logow_row = 0;
	end
	logow_xpos = 4*logo_addr[4:1] + logo_wbit[1:0];
	logow_ypos = 4*logow_row + 2*logo_addr[0] + logo_wbit[2];
end

/*
The following logic reads the logo area from the cart into logo_data so it can be used by the scrolling logic.
rom_read_done will be set once everything is read. It does this by reading a byte at a time, then taking 8
clock cycles to decode the bits.
*/

reg need_read_byte;
always @(posedge clk_8m) begin
	if (rst) begin
		cart_raddr <= 'd260; //logo start
		logo_wbit <= 0;
		need_read_byte <= 1;
		rom_rd <= 0;
		rom_read_done <= 0;
	end else begin
		rom_rd <= 0;
		if (rom_read_done) begin
			//all done
		end else if (logo_wbit==0 && need_read_byte) begin
			rom_rd <= 1;
			need_read_byte <= 0;
		end else if (rom_bsy) begin
			//wait
		end else if (logo_wbit==0 && !need_read_byte) begin
			logo_data[logow_xpos][logow_ypos] <= rom_data[7];
			if (cart_raddr == 308) begin
				//all done
				rom_read_done <= 1;
			end else begin
				logo_rdat <= rom_data;
				logo_wbit <= 1;
			end
		end else if (logo_wbit!=0) begin
			logo_wbit <= (logo_wbit==7)?0:logo_wbit+1;
			logo_data[logow_xpos][logow_ypos] <= logo_rdat[7-logo_wbit];
			if (logo_wbit == 7) begin	//done with this byte
				cart_raddr <= cart_raddr + 1;
				logo_wbit <= 0;
				need_read_byte <= 1;
			end else begin
				logo_wbit <= logo_wbit + 1;
			end
		end
	end
end


reg [7:0] ypos_in_logo;
reg [7:0] xpos_in_logo;
reg [7:0] logo_bit;

always @(*) begin
	ypos_in_logo <= lcd_ypos - scroll + 'd34;
	xpos_in_logo <= lcd_xpos - 24;
	lcd_data[0] <= ~logo_bit;
	lcd_data[1] <= ~logo_bit;
	if (vblanks < 100*2) begin
		scroll <= vblanks/2;
	end else begin
		scroll <= 100;
	end
end

wire all_done;
//If not DMGPlus, delay 'Nintendo' logo a bit for gnuboy to properly start.
//If DMGPlus, the splash loader will display, so we can keep original timing.
assign all_done = is_dmgplus ? (vblanks == 132*2) : (vblanks == 220*2);
assign startup_done = all_done;

always @(*) begin
	sound_start = 0;
	sound_freq = 0;
	if (lcd_newframe) begin
		if (vblanks == 'h62*2) begin
			sound_start = 1;
			sound_freq = 'h783;
		end else if (vblanks == 'h64 * 2) begin
			sound_start = 1;
			sound_freq = 'h7c1;
		end
	end
end

always @(posedge clk_8m) begin
	if (rst) begin
		vblanks <= 'b0;
	end else begin
		if (lcd_newframe && !all_done) begin
			vblanks <= vblanks + 1;
		end
		if (xpos_in_logo >= 0 && xpos_in_logo < 48*2 &&
					ypos_in_logo >=0 && ypos_in_logo < 8*2) begin
			logo_bit <= logo_data[xpos_in_logo/2][ypos_in_logo/2];
		end else if (xpos_in_logo >= 48*2 && xpos_in_logo < 48*2+8 &&
					ypos_in_logo >=0 && ypos_in_logo < 8) begin
			logo_bit <= rsign[ypos_in_logo][xpos_in_logo-48*2];
		end else begin
			logo_bit <= 0;
		end
	end
end

endmodule