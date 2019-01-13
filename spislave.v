module spislave (
	input wire clk,
	input wire rst,

	input wire mosi,
	output wire miso,
	input wire sck,
	input wire cs,
	
	output reg [7:0] mdata,
	input wire [7:0] sdata,
	output wire data_valid_read,
	output reg data_firstbyte
);


reg [3:0] bit_sel;
reg [7:0] rdata;
reg [7:0] wdata;
reg first_byte;
reg sampled_mosi;
reg curr_firstbyte;

//Note: This implements SPI mode 0 with positive CS.
//Out-data is written on the falling edge of the signal (or CS becoming active), in-data is
//read on the rising edge.

//Sample mosi on posedge of clock
always @(posedge sck) begin
	sampled_mosi <= mosi;
end

assign miso = wdata[7];

reg flag_next_toggle;
reg [2:0] flag_next_resamp;

always @(negedge sck, negedge cs, posedge rst) begin
	if (cs == 0 || rst == 1) begin
		//deselected, abort transaction in progress
		bit_sel <= 0;
		curr_firstbyte <= 1;
		mdata <= 'h00;
		data_firstbyte <= 0;
		rdata <= 'h00;
		wdata <= 'h00;
		first_byte <= 0;
		flag_next_toggle <= 0;
		curr_firstbyte <= 0;
		flag_next_resamp <= 'b000;
	end else if (sck == 1) begin
		//selected, sck went high, output next bit
		rdata <= {rdata[6:0], mosi};
		wdata <= {wdata[6:0], 1'b0};
		if (bit_sel == 7) begin
			mdata <= rdata;
			wdata <= sdata;
			flag_next_toggle <= !flag_next_toggle;
			data_firstbyte <= curr_firstbyte;
			curr_firstbyte <= 0;
		end
		bit_sel <= bit_sel+1;
	end
end

always @(posedge clk) begin
	flag_next_resamp <= { flag_next_resamp[1:0], flag_next_toggle };
end
assign data_valid_read = flag_next_resamp[2];


endmodule

