//Dual-port video ram
/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */


module vram (WrAddress, RdAddress, Data, WE, RdClock, RdClockEn, Reset, 
    WrClock, WrClockEn, Q);
    input wire [15:0] WrAddress;
    input wire [15:0] RdAddress;
    input wire [1:0] Data;
    input wire WE;
    input wire RdClock;
    input wire RdClockEn;
    input wire Reset;
    input wire WrClock;
    input wire WrClockEn;
    output reg [1:0] Q;

	reg [1:0] mem[0:65535];
	always @(posedge RdClock) begin
		if (RdClockEn) Q<=mem[RdAddress];
	end

	always @(posedge WrClock) begin
		if (WrClockEn && WE) begin
			mem[WrAddress] <= Data;
		end
	end

endmodule
