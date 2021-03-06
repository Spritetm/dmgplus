//Simple emulation of a Ice40 LUT thing used for tristate output
/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */

module SB_IO (
	inout PACKAGE_PIN,
	input OUTPUT_ENABLE,
	input D_OUT_0,
	output D_IN_0
);

parameter [6:0] PIN_TYPE =  'h0;
parameter PULLUP = 0;

reg pin;

always @(*) begin
	if (OUTPUT_ENABLE) begin
		pin = D_OUT_0;
	end else begin
		pin = 'hz;
	end
end

assign PACKAGE_PIN = pin;
assign 	D_IN_0 = PACKAGE_PIN;

endmodule
