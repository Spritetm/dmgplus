
`timescale 1us/1ns
module stimulus();

reg clk = 0, rst=0;
reg mosi, sck, cs;
wire miso;
wire [7:0] data_master;
reg [7:0] data_slave;
wire data_valid_read, data_firstbyte;

spislave i_spislave(
	.clk(clk),
	.rst(rst),
	.mosi(mosi),
	.miso(miso),
	.sck(sck),
	.cs(cs),
	.mdata(data_master),
	.sdata(data_slave),
	.data_valid_read(data_valid_read),
	.data_firstbyte(data_firstbyte)
);

//clock toggle
always #1 clk = !clk;

reg [2:0] data[127:0];

integer i;
initial begin
	$readmemb("spislave_testbench.txt", data);
	$dumpfile("spislave_testbench.vcd");
	$dumpvars(0, stimulus);
	$dumpvars(0, stimulus);
	data_slave = 'h8a;
	sck = 0;
	mosi = 0;
	cs = 0;
	rst = 1;
	#5 rst = 0;
	for (i=0; i<128; i++) begin
		#2 sck = data[i][2];
		mosi = data[i][1];
		cs = data[i][0];
	end
	#10 $finish;
end

endmodule