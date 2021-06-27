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
