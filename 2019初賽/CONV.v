
`timescale 1ns/10ps
module  CONV(
	input				clk,
	input				reset,
	output	reg			busy,	
	input				ready,	
			
	output	reg [11:0]	iaddr,
	input	signed	[19:0]	idata,	
	
	output	reg			cwr,
	output	reg [11:0]	caddr_wr,
	output	reg [19:0]	cdata_wr,
	
	output	reg 		crd,
	output	reg [11:0]	caddr_rd,
	input		[19:0]	cdata_rd,
	
	output	reg  [2:0]	csel
	);
reg signed[19:0]data;
reg [3:0]count, count1;
reg [2:0]state, next_state;
reg [9:0]ignore;
reg signed[19:0]max;
parameter IDLE = 0 ,Read = 1 ,Write = 2, Max_read = 3, Max_write = 4, DONE = 5, bias = 6;

wire signed[19:0]kernel[0:8];
assign kernel[0] = 20'h0A89E;
assign kernel[1] = 20'h092D5;
assign kernel[2] = 20'h06D43;
assign kernel[3] = 20'h01004;
assign kernel[4] = 20'hF8F71;
assign kernel[5] = 20'hF6E54;
assign kernel[6] = 20'hFA6D7;
assign kernel[7] = 20'hFC834;
assign kernel[8] = 20'hFAC19;

always@(posedge clk or posedge reset)begin
		if(reset)
				data <= 0;
		else if(state == Read)
				data <= idata;
end
reg flag;
always@(posedge clk or posedge reset)begin
		if(reset)
				flag <= 0;
		else if(count == 0 && state == Read)
						flag <= 1;
		else if(next_state == Write)
				flag <= 0;
		else
				flag <= flag;
end

always@(posedge clk or posedge reset)begin
		if(reset)
				count1 <= 0;
		else if(state == Read)
				count1 <= count1 + 1;
		else
				count1 <= 0;
end
always@(posedge clk or posedge reset) begin
		if(reset)	
				count <= 0;
		else if(flag) 
				count <= count + 1;
		else if(state == Max_read)
				count <= count + 1;
		else
				count <= 0;
end

always@(*) begin
		case(state)
				IDLE:		next_state = ready ? Read : IDLE;
				Read:		next_state = (count == 10) ? Write : Read;
				Write:      next_state = bias;
				bias:		next_state = (caddr_wr == 12'd4095) ? Max_read : Read;
				Max_read:	next_state = (count == 4) ? Max_write : Max_read;
				Max_write:  next_state = (caddr_wr == 10'd1023) ? DONE : Max_read;
				DONE:		next_state = DONE;
				default:	next_state = IDLE;
		endcase
end

always@(posedge clk or posedge reset) begin
		if(reset)
				state <= IDLE;
		else
				state <= next_state;
end

always@(posedge clk or posedge reset) begin
		if(reset)
				caddr_wr <= 0;
	    else if(state == bias) 
				caddr_wr <= caddr_wr + 1;
		else if(state == Max_write)
				caddr_wr <= caddr_wr + 1;
end
always@(*)begin
		ignore[0] = 1;
		ignore[1] = (caddr_wr[5:0] == 6'b000000 || caddr_wr<64);
		ignore[2] = (caddr_wr<64);
		ignore[3] = (caddr_wr<64 || caddr_wr[5:0]==6'b111111);
		ignore[4] = (caddr_wr[5:0] == 6'b000000);
		ignore[5] = 0;
		ignore[6] = (caddr_wr[5:0] == 6'b111111);
		ignore[7] = (caddr_wr[5:0] == 6'b000000 || caddr_wr>4031);
		ignore[8] = (caddr_wr>4031);
		ignore[9] = (caddr_wr[5:0] == 6'b111111 || caddr_wr>4031);
end

always@(posedge clk or posedge reset) begin
		if(reset)
				iaddr <= 0;
		else if(state==Read)begin
				case(count1)
						0:iaddr <= caddr_wr - 65;
						1:iaddr <= caddr_wr - 64;
						2:iaddr <= caddr_wr - 63;
						3:iaddr <= caddr_wr - 1;
						4:iaddr <= caddr_wr;
						5:iaddr <= caddr_wr + 1;
						6:iaddr <= caddr_wr + 63;
						7:iaddr <= caddr_wr + 64;
						8:iaddr <= caddr_wr + 65;
						default: iaddr <= caddr_wr;
				endcase
		end
end

reg signed [42:0]mul;
reg  signed [42:0]sum;
reg  signed [42:0]sum_temp;

always@(posedge clk or posedge reset)begin
		if(reset)
				sum_temp <= 0;
		else if(next_state == Write && state == Read)
				sum_temp <= sum + 43'h0013100000 + {{3{mul[39]}},mul};
		else if(state == Read)
				sum_temp <= 0;
		else
				sum_temp <= sum_temp;
end

always@(posedge clk or posedge reset)begin
		if(reset)
				sum <= 0;
		else if(state == Read)
				sum <= sum + mul;
		else if(state == bias)
				sum <= 0;
		else
				sum <= sum;
end

always@(posedge clk or posedge reset)begin
		if(reset)
				mul <= 0;
		else if(state == Read || state == Write) begin
				if(!ignore[count])
						mul <= data * kernel[count-1];
				else
						mul <= 0;
		end
		else
				mul <= 0;
end
always@(posedge clk or posedge reset)begin
		if(reset)
				cdata_wr <= 0;
		else if(next_state == bias)begin
				cdata_wr <= (sum_temp[42]) ? 0 : 
											(sum[15] ? (sum_temp[35:16] + 1) : sum_temp[35:16]);
		end
		else if(next_state == Max_write)begin
				cdata_wr <= (max > cdata_rd) ? max : cdata_rd;
		end	
		else
				cdata_wr <= 0;
end


always@(posedge clk or posedge reset) begin
		if(reset)
				cwr <= 0;
		else if(next_state== bias)
				cwr <= 1;
		else if(next_state == Max_write)
				cwr <= 1;
		else
			cwr<=0;
end

always@(posedge clk or posedge reset)begin
		if(reset)
				crd <= 0;
		else if(next_state == Max_read)
				crd <= 1;
		else
				crd <= 0;
end

always@(posedge clk or posedge reset)begin
		if(reset)
				caddr_rd <= 0;
		else if(state == Max_read)begin
				case(count)
						0: caddr_rd <= caddr_rd + 65;
						1: caddr_rd <= caddr_rd - 1;
						2: caddr_rd <= caddr_rd - 63;
						3: caddr_rd <= caddr_rd - 1;
						default: caddr_rd <= caddr_rd;
				endcase
		end
		else if(state == Max_write)
				caddr_rd <= (caddr_wr[4:0] == 31) ? (caddr_rd + 66):caddr_rd + 2;
		else
				caddr_rd <= caddr_rd;
end

always@(posedge clk or posedge reset)begin
		if(reset)
				max <= 0;
		else if(state == Max_read)
				max <= (cdata_rd > max) ? cdata_rd : max;
		else
				max <= 0;
end

always@(posedge clk or posedge reset) begin
		if(reset) 
				busy <= 0;
		else if(ready) 
				busy <= 1;
		else if(state == DONE) 
				busy <= 0;
end

always@(posedge clk or posedge reset) begin
		if(reset) 
				csel <= 0;
		else if(next_state== bias || next_state == Max_read)
				csel <= 3'b001;
		else if(next_state == Max_write)
				csel <= 3'b011;		
		else
				csel <= 0;
end


endmodule

