
`timescale 1us/1ns
module stimulus();

reg clk = 0, rst=0;
wire [7:0] cartif_in;
wire [7:0] cartif_out;
wire [15:0] cartif_addr;
wire cartif_rd, cartif_wr;
wire cartif_busy;

wire [15:0] cart_a;
wire [7:0] cart_d_out;
reg [7:0] cart_d_in;
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
	.cart_d_in(cart_d_in),
	.cart_d_out(cart_d_out),
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


always @(*) begin
	if (!cart_busdir) begin
		cart_d_in = 'hff;
	end else begin
		cart_d_in = cart_a[7:0];
	end
end

task spisend;
input [7:0] d;
integer i;
begin
	for (i=7; i>=0; --i) begin
		#1.3 spi_mosi <= d[i];
		spi_sck <= 0;
		#1.3 spi_sck <= 1;
	end
	#1.3 spi_sck <= 0;
end
endtask

initial begin
	$dumpfile("spicart_testbench.vcd");
	$dumpvars(0, stimulus);

	spi_cs <= 0;
	spi_mosi <= 0;
	spi_sck <= 0;
	rst = 0;
	#1 rst = 1;
	#5 rst = 0;
	#2.5 spi_cs <= 1;
	spisend('h40);
	spisend('h00);
	spisend(0);
	spisend(0);
	spisend(0);
	#2 spi_cs <= 0;
	#2 spi_cs <= 1;
	#2 spisend('hA0);
	spisend('h00);
	spisend('h50);
//	spisend('h51);
//	spisend('h52);
//	spisend('h53);
	#2 spi_cs <= 0;
	
	
	#10 $finish;
end

endmodule