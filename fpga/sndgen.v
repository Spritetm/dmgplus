/*
Partial reproduction of sound hardware of channel 1 of a DMG. Only enough is implemented to
semi-faithfully reproduce the 'pli-ding!' startup sound.
*/
/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */

module sndgen (
	input wire clk_8m,
	input wire rst,

	input wire start_sound,
	input wire [10:0] freq,
	
	output wire pwm
);


//Set to F initially, decreased every (3/64)th second.
reg [3:0] volume;
reg [10:0] myfreq;


always @(posedge clk_8m) begin
	if (rst) begin
		myfreq <= ~'h700;
	end else if (start_sound) begin
		myfreq <= ~freq;
	end
end


//Channel 1 freq: 0x783 / 0x7c1, restart sound (freq=131072/(2048-x) Hz)

//Main clock
reg [5:0] mainclk_div;
wire mainclk_tick = (mainclk_div == 0); //131072 KHz
always @(posedge clk_8m) begin
	if (rst || start_sound) begin
		mainclk_div <= 'd0;
	end else begin
		if (mainclk_div == 0) begin
			mainclk_div <= 'd60;
		end else begin
			mainclk_div <= mainclk_div - 1;
		end
	end
end

//Volume sweep
reg [12:0] sweep_clk;
always @(posedge clk_8m) begin
	if (rst) begin
		sweep_clk <= 0;
		volume <= 0;
	end else if (start_sound) begin
		sweep_clk <= 'd6147;
		volume <= 'hf;
	end else if (mainclk_tick) begin
		if (sweep_clk != 0) begin
			sweep_clk <= sweep_clk - 1;
		end else begin
			sweep_clk <= 'd6147;
			if (volume != 0) begin
				volume <= volume - 1;
			end
		end
	end
end

//Freq gen
reg [10:0] freq_cnt;
always @(posedge clk_8m) begin
	if (rst || start_sound) begin
		freq_cnt <= 0;
	end else if (mainclk_tick) begin
		if (freq_cnt != 0) begin
			freq_cnt <= freq_cnt - 1;
		end else begin
			freq_cnt <= myfreq;
		end
	end
end

reg[3:0] pwmdiv;
reg pwmout;
always @(posedge clk_8m) begin
	if (rst) begin
		pwmdiv <= 0;
		pwmout <= 0;
	end else begin
		pwmdiv <= pwmdiv + 1;
		if (pwmdiv == volume) begin
			pwmout <= 0;
		end else if (pwmdiv == 0) begin
			pwmout <= 1;
		end
	end
end

wire freqout;
assign freqout = (freq_cnt < (myfreq/2)) ? 1 : 0;
//main_clk doesn't go _entirely_ to 64, so this is slightly off... eh, /care.
assign pwm = pwmout & freqout;

endmodule