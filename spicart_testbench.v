
`timescale 1us/1ns
module stimulus();

reg clk = 0, rst=0;
reg [7:0] cartif_in;
wire [7:0] cartif_out;
wire [15:0] cartif_addr;
wire cartif_rd, cartif_wr;
wire cartif_busy;

wire [15:0] cart_a;
wire [7:0] cart_da;
wire cart_ncs, cart_nwr, cart_clk;
wire cart_busdir;

reg spi_mosi;
wire spi_miso;
reg spi_sck;
reg spi_cs;

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


spicart i_spicart(
	.clk(clk),
	.rst(rst),
	.spi_mosi(spi_mosi),
	.spi_miso(spi_miso),
	.spi_sck(spi_sck),
	.spi_cs(spi_cs),
	.cart_dout(cartif_out),
	.cart_din(cartif_in),
	.cart_a(cartif_addr),
	.cart_wr(cartif_wr),
	.cart_rd(cartif_rd),
	.cart_busy(cartif_busy)
);
//clock toggle
always #0.5 clk = !clk;

reg [7:0] cart_d;
assign cart_da = cart_d;

always @(*) begin
	if (cart_busdir) begin
		cart_d = 'hzz;
	end else begin
		cart_d = cart_a[7:0];
	end
end

task spisend;
input [7:0] d;
integer i;
begin
	for (i=7; i>=0; --i) begin
		#0.1 spi_mosi <= d[i];
		spi_sck <= 0;
		#0.1 spi_sck <= 1;
	end
	#0.1 spi_sck <= 1;
end
endtask

initial begin
	$dumpfile("cart_iface_testbench.vcd");
	$dumpvars(0, stimulus);

	spi_cs <= 0;
	spi_mosi <= 0;
	spi_sck <= 0;
	rst = 1;
	#5 rst = 0;
	#2.5 spi_cs <= 1;
	spisend('h12);
	spisend('h34);
	spisend(0);
	spisend(0);
	spisend(0);
	spi_cs <= 0;
	#2 spi_cs <= 1;
	spisend('h80);
	spisend('h00);
	spisend(0);
	spisend(1);
	spisend(2);
	spisend(3);
	spi_cs <= 0;
	
	
	#10 $finish;
end

endmodule