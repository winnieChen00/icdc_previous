

module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg valid;
/////////////////////////////////////////
parameter IDLE=0;
parameter wr_str=1;
parameter wr_pat=2;
parameter check=3;
reg [1:0] state,next_state;
reg [7:0]str[0:31];
reg [7:0]pattern[0:8];
reg [4:0]string_l;
reg [3:0]pattern_l;
reg [4:0]i;
reg [8:0]check_char;
reg [8:0]one;
reg c;
integer k,j;
always@(posedge clk or posedge reset) begin
	if(reset)
		state<=IDLE;
	else
		state<=next_state;
end
always@(*) begin
	case(state)
		IDLE: next_state=wr_str;
		wr_str:begin
			if(isstring) next_state=wr_str;
			else next_state=wr_pat;
		end
		wr_pat:begin
			if(ispattern) next_state=wr_pat;
			else next_state=check;
		end
		check:begin
			if(ispattern) next_state=wr_pat;			
			else if(isstring) next_state=wr_str;
			else next_state=check;
		end
		default: next_state=IDLE;
	endcase
end

always@(posedge clk ) begin
	if(state==IDLE) string_l<=5'h0;
	else if(state==check && isstring)string_l<=0;
	else if(isstring && state!=IDLE) string_l<=string_l+1;
	else string_l<=string_l;
end

always@(posedge clk ) begin
	if(state==IDLE) pattern_l<=0;
	else if(ispattern) pattern_l<=pattern_l+1;
	else if((i==string_l && i>0) || c)pattern_l<=0;

end
always@(posedge clk)begin
	if(reset) begin
		for(j=0;j<32;j=j+1)
			str[j]<=0;
	end
	if(isstring && (state==check || state==IDLE))begin
		str[0]<=chardata;
	end
	else if(isstring)begin
		str[string_l+1]<=chardata;
	end
end
always@(posedge clk)begin
	if(ispattern)begin
		pattern[pattern_l]<=chardata;
	end
end
always@(posedge clk)begin
		if(state==wr_pat) begin
			i<=0;
		end
		else if(next_state==check) begin
			if(c)
				i<=0;
			else 
				i<=i+1;
		end
		else
			i<=i;
end
always@(posedge clk or posedge reset)begin
	if(reset) valid<=0;
	else if(valid) begin
		valid<=0;
	end
	else if(next_state==check) begin
		if(c)begin
			valid<=1;
		end
		else if(i==string_l) begin
			valid<=1;
		end
		else begin
			valid<=0;
		end
	end
	else
		valid<=0;
end
always@(*) begin
		for(k=0;k<9;k=k+1) begin
			if(k<pattern_l) begin
				if(pattern[k] == str[i+k])check_char[k]=1'b1;
				else if(pattern[k]==8'h2e)check_char[k]=1'b1;
				else if(pattern[k]==8'h5e && str[i+k]==8'h20) check_char[k]=1'b1;//^
				else if(pattern[k]==8'h24 && (str[i+k]==8'h20 || i+pattern_l==string_l+2)) check_char[k]=1'b1;//$
				else check_char[k]=0;
			end
			else begin
				if(i!=string_l) begin
					check_char[k]=1;
				end
				else begin
					check_char[k]=0;
				end
			end
		end
	c=&check_char;
end

always@(posedge clk or posedge reset) begin
	if(reset)
		match<=0;
	else if(c)begin
		match<=1;
	end
	else if(pattern_l==1)begin
		match<=1;
	end
	else if(i==string_l)
		match<=0;
	else
		match<=0;
end
always@(posedge clk or posedge reset) begin
	if(reset)
		match_index<=0;
	else if(c)begin
		if(pattern[0]==8'h5e)
			match_index<=i+1;
		else if(pattern_l==0)
			match_index<=i-1;
		else
			match_index<=i;
	end
end

endmodule
