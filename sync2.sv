// 2 stage flip flop to reduce metastability on key inputs

module sync2(Clock, reset, async, sync);
	input logic Clock, reset, async;
	output logic sync; // second FF
	
	logic ff1;// first FF
	
	always_ff @(posedge Clock or posedge reset)begin
		if (reset) begin
			ff1 <= 1'b1;
			sync <= 1'b1;
		end
		else begin
			ff1 <= async; // stage 1 FF
			sync <= ff1; // stage 2 FF
		end
	end

endmodule 