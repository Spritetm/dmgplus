//Simple emulation of a Ice40 LUT thing used for tristate output

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
