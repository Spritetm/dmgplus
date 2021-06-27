
`timescale 1us/1ns
module stimulus();

reg clk = 0, rst=0;
reg [7:0] cartif_in;
wire [7:0] cartif_out;
reg [15:0] cartif_addr;
reg cartif_rd, cartif_wr;
wire cartif_busy;

wire [15:0] cart_a;
wire [7:0] cart_da;
wire cart_ncs, cart_nwr, cart_clk;
wire cart_busdir;


cart_iface i_cart_iface(
	.clk_8m(clk),
	.rst(rst),
	.dout(cartif_out),
	.din(cartif_in),
	.addr(cartif_addr),
	.rd(cartif_rd),
	.wr(cartif_wr),
	.busy(cartif_busy),
	.cart_a(cart_a),
	.cart_d(cart_da),
	.cart_ncs(cart_ncs),
	.cart_nrd(cart_nrd),
	.cart_nwr(cart_nwr),
	.cart_clk(cart_clk),
	.cart_busdir(cart_busdir)
);

//clock toggle
always #0.5 clk = !clk;

reg [7:0] cart_d;
assign cart_da = cart_d;

integer i;
initial begin
	$dumpfile("cart_iface_testbench.vcd");
	$dumpvars(0, stimulus);
	cartif_in='h0;
	cartif_addr='h0;
	cartif_rd=0;
	cartif_wr=0;
	cart_d = 'hzz;
	rst = 1;
	#5 rst = 0;
	#2.5 cart_d = 'haa;
	
	cartif_in = 0;
	cartif_addr = 'haa55;
	cartif_rd = 1;
	#1 cartif_rd = 0;
	while (cartif_busy) #1;

	cartif_in = 0;
	cartif_addr = 'h1234;
	cartif_rd = 1;
	#1 cartif_rd = 0;
	while (cartif_busy) #1;

	cartif_in = 'ha5;
	cartif_addr = 'ha5a5;
	cartif_wr = 1;
	#1 cartif_wr = 0;
	while (cartif_busy) #1;

	#10 $finish;
end

endmodule