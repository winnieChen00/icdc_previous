module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       oem_finish, oem_dataout, oem_addr,
	       odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr);

input		clk, reset;
input		load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;
output		reg so_data, so_valid;

output  reg oem_finish, odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr;
output reg [4:0] oem_addr;
output reg [7:0] oem_dataout;

//==============================================================================

reg [31:0] x;
reg state,next_state;
reg[5:0] count;
wire [5:0] length;
reg [14:0]number;
reg [3:0]write;
reg po_end;

assign length = (pi_length+1)<<3;
always@(posedge clk or posedge reset) begin
		if(reset)
				state <= 0;
		else
				state<=next_state;
end
always@(*) begin
	if(load) next_state=1;
	else if(count==length-1) next_state=0;
	else next_state=state;
end


always@(*) begin
	case(pi_length)
		2'b00:begin
			if(pi_low) x[31:24] = pi_data[15:8];
			else x[31:24] = pi_data[7:0];
			x[23:0] = 24'b0;
		end
		2'b01:begin
			x[31:16] = pi_data[15:0];
			x[15:0] = 16'b0;
		end
		2'b10:begin
			if(pi_fill) x[31:8] = {pi_data[15:0],8'b0};
			else x[31:8] = {8'b0,pi_data[15:0]};
			x[7:0]=8'b0;
		end
		2'b11:begin
			if(pi_fill) x[31:0] = {pi_data[15:0],16'b0};
			else x[31:0] = {16'b0,pi_data[15:0]};
		end
		//default: x[31:0]=32'b0;
	endcase
end
always@(posedge clk or posedge reset) begin
	if(reset)
			so_data <= 0;
	else begin
		if(pi_msb) so_data <= x[31-count];
		else so_data <=x [32-length+count];
	end
end
always@(posedge clk or posedge reset) begin
	if(reset)
		count <= 0;
	else if(state)
		count<=count+1;
	else
		count<=0;
end
always@(posedge clk or posedge reset) begin
	if(reset)
			so_valid <= 0;
	else if(state)
		so_valid <= 1;
	else
		so_valid <= 0;
end

////////////////////////////////////////////////////////////////////////
always@(posedge clk or posedge reset) begin
	if(reset)number<=0;
	else if(so_valid && count[2:0]==3'b0)
		number<=number+1;
	else if(po_end==1)
		number<=number+1;
end
always@(posedge clk ) begin
	if(reset)po_end<=0;
	else if(pi_end && count==length)
		po_end<=1;
end
always@(*) begin
	oem_addr=number[5:1];
end
always@(posedge clk or posedge reset) begin
	if(reset)oem_finish<=0;
	else if(number==254 && so_valid==0)
		oem_finish<=1;
end
always@(posedge clk or posedge reset) begin
	if(reset)
			oem_dataout <= 0;
	else if(state) begin
		if(pi_msb) oem_dataout[7-count[2:0]] <= x[31-count];
		else oem_dataout[7-count[2:0]] <=x [32-length+count];
	end
	else oem_dataout<=8'b0;
end

always@(*) begin
	if(reset)
			{odd1_wr,even1_wr}=2'b0;
	else if(number<=63) begin
		if(so_valid && count[2:0]==3'b0) begin
			even1_wr=number[3]^number[0];
			odd1_wr=!number[3]^number[0];
		end
		else if( (pi_end && count==length) || po_end) begin
				odd1_wr=number[0];
				even1_wr=!number[0];
		end
		else begin
			{odd1_wr,even1_wr}=2'b0;
		end
	end
	else begin
		{odd1_wr,even1_wr}=2'b0;
	end
end
always@(*) begin
	if(reset)
			{odd2_wr,even2_wr}=2'b0;
	else if(number>63 && number<=127) begin
		if(so_valid && count[2:0]==3'b0) begin
			even2_wr=number[3]^number[0];
			odd2_wr=!number[3]^number[0];
		end
		else if( (pi_end && count==length)|| po_end) begin
			odd2_wr=number[0];
			even2_wr=!number[0];
		end
		else begin
			{odd2_wr,even2_wr}=2'b0;
		end
	end
	else begin
		{odd2_wr,even2_wr}=2'b0;
	end
end
always@(*) begin
	if(reset)
		{odd3_wr,even3_wr}=2'b0;
	else if(number>=127 && number<=191) begin
		if(so_valid &&count[2:0]==3'b0) begin
			even3_wr=number[3]^number[0];
			odd3_wr=!number[3]^number[0];
		end
		else if( (pi_end && count==length) || po_end) begin
				odd3_wr=number[0];
				even3_wr=!number[0];
		end
		else 		{odd3_wr,even3_wr}=2'b0;
	end
	else begin
		{odd3_wr,even3_wr}=2'b0;
	end
end
always@(*) begin
	if(reset)
		{odd4_wr,even4_wr}=2'b0;
	else if(number>=191 && number<=255) begin	
		if(so_valid && count[2:0]==3'b0) begin
			even4_wr=number[3]^number[0];
			odd4_wr=!number[3]^number[0];
		end
		else if( (pi_end && count==length) || po_end) begin
			odd4_wr=number[0];
			even4_wr=!number[0];
		end
		else 		{odd4_wr,even4_wr}=2'b0;
	end
	else begin
		{odd4_wr,even4_wr}=2'b0;
	end
end
endmodule
