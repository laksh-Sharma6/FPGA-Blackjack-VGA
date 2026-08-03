`timescale 1 ps / 1 ps
module score_calc_tb();

	logic clk;
	logic [3:0] ranks [6];
	logic [2:0] count;
	logic [4:0] score;

	// instantiate DUT
	score_calc dut (
		.ranks(ranks),
		.count(count),
		.score(score)
	);

	parameter CLOCK_PERIOD = 100;

	// clock generation
	initial begin
		clk = 0;
		forever #(CLOCK_PERIOD/2) clk = ~clk;
	end

	initial begin
		// initial values
		count = 3'd0;
		ranks[0] = 4'd0;
		ranks[1] = 4'd0;
		ranks[2] = 4'd0;
		ranks[3] = 4'd0;
		ranks[4] = 4'd0;
		ranks[5] = 4'd0;

		@(posedge clk);

		// Test 1: empty hand
		// input: count = 0
		// expected: score = 0
		count = 3'd0;
		@(posedge clk);

		// Test 2: normal numbered cards
		// input: 2 + 3 + 4
		// rank encoding: 1=Two, 2=Three, 3=Four
		// expected: score = 9
		ranks[0] = 4'd1;
		ranks[1] = 4'd2;
		ranks[2] = 4'd3;
		ranks[3] = 4'd0;
		ranks[4] = 4'd0;
		ranks[5] = 4'd0;
		count = 3'd3;
		@(posedge clk);

		// Test 3: face cards count as 10
		// input: King + Queen + Jack
		// rank encoding: 12=King, 11=Queen, 10=Jack
		// expected: score = 30
		ranks[0] = 4'd12;
		ranks[1] = 4'd11;
		ranks[2] = 4'd10;
		ranks[3] = 4'd0;
		ranks[4] = 4'd0;
		ranks[5] = 4'd0;
		count = 3'd3;
		@(posedge clk);

		// Test 4: ten card counts as 10
		// input: 10 + Jack
		// rank encoding: 9=Ten, 10=Jack
		// expected: score = 20
		ranks[0] = 4'd9;
		ranks[1] = 4'd10;
		ranks[2] = 4'd0;
		ranks[3] = 4'd0;
		ranks[4] = 4'd0;
		ranks[5] = 4'd0;
		count = 3'd2;
		@(posedge clk);

		// Test 5: ace counts as 11 when it does not bust
		// input: Ace + 9
		// rank encoding: 0=Ace, 8=Nine
		// expected: score = 20
		ranks[0] = 4'd0;
		ranks[1] = 4'd8;
		ranks[2] = 4'd0;
		ranks[3] = 4'd0;
		ranks[4] = 4'd0;
		ranks[5] = 4'd0;
		count = 3'd2;
		@(posedge clk);

		// Test 6: ace changes from 11 to 1 to avoid bust
		// input: Ace + 9 + 5
		// rank encoding: 0=Ace, 8=Nine, 4=Five
		// expected: score = 15
		ranks[0] = 4'd0;
		ranks[1] = 4'd8;
		ranks[2] = 4'd4;
		ranks[3] = 4'd0;
		ranks[4] = 4'd0;
		ranks[5] = 4'd0;
		count = 3'd3;
		@(posedge clk);

		// Test 7: two aces
		// input: Ace + Ace
		// one ace counts as 11 and the other counts as 1
		// expected: score = 12
		ranks[0] = 4'd0;
		ranks[1] = 4'd0;
		ranks[2] = 4'd0;
		ranks[3] = 4'd0;
		ranks[4] = 4'd0;
		ranks[5] = 4'd0;
		count = 3'd2;
		@(posedge clk);

		$stop;
	end

endmodule 