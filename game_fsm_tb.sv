`timescale 1 ps / 1 ps
module game_fsm_tb();

	logic clk;
	logic reset;

	logic hit_pulse;
	logic stand_pulse;
	logic start_pulse;

	logic draw_req;
	logic [3:0] drawn_rank;
	logic [1:0] drawn_suit;

	logic [3:0] player_ranks [6];
	logic [1:0] player_suits [6];
	logic [2:0] player_count;

	logic [3:0] dealer_ranks [6];
	logic [1:0] dealer_suits [6];
	logic [2:0] dealer_count;

	logic dealer_hidden;

	logic [4:0] player_score;
	logic [4:0] dealer_score;

	logic [2:0] game_state;
	logic [1:0] result;
	logic deck_reset;

	// instantiate DUT
	game_fsm dut (
		.clk(clk),
		.reset(reset),

		.hit_pulse(hit_pulse),
		.stand_pulse(stand_pulse),
		.start_pulse(start_pulse),

		.draw_req(draw_req),
		.drawn_rank(drawn_rank),
		.drawn_suit(drawn_suit),

		.player_ranks(player_ranks),
		.player_suits(player_suits),
		.player_count(player_count),

		.dealer_ranks(dealer_ranks),
		.dealer_suits(dealer_suits),
		.dealer_count(dealer_count),

		.dealer_hidden(dealer_hidden),

		.player_score(player_score),
		.dealer_score(dealer_score),

		.game_state(game_state),
		.result(result),
		.deck_reset(deck_reset)
	);

	parameter CLOCK_PERIOD = 100;

	// clock generation
	initial begin
		clk = 0;
		forever #(CLOCK_PERIOD/2) clk = ~clk;
	end

	initial begin
		// initial values
		reset = 1;
		hit_pulse = 0;
		stand_pulse = 0;
		start_pulse = 0;

		drawn_rank = 4'd0;
		drawn_suit = 2'd0;

		player_score = 5'd0;
		dealer_score = 5'd0;

		// hold reset for 2 cycles
		repeat (2) @(posedge clk);
		reset = 0;
		@(posedge clk);

		// Test 1: reset state
		// expected: game_state = 0
		// expected: player_count = 0
		// expected: dealer_count = 0
		@(posedge clk);

		// Test 2: start a new game
		// input: start_pulse = 1 for one cycle
		// expected: deck_reset pulses high while starting
		// expected: next state becomes DEAL
		start_pulse = 1;
		@(posedge clk);
		start_pulse = 0;
		@(posedge clk);

		// Test 3: initial deal card 1
		// input: player first card = 10
		// rank encoding: 9=Ten
		// expected: player_count = 1
		drawn_rank = 4'd9;
		drawn_suit = 2'd0;
		@(posedge clk);

		// Test 4: initial deal card 2
		// input: dealer first card = 6
		// rank encoding: 5=Six
		// expected: dealer_count = 1
		drawn_rank = 4'd5;
		drawn_suit = 2'd1;
		@(posedge clk);

		// Test 5: initial deal card 3
		// input: player second card = 9
		// rank encoding: 8=Nine
		// expected: player_count = 2
		drawn_rank = 4'd8;
		drawn_suit = 2'd2;
		@(posedge clk);

		// Test 6: initial deal card 4
		// input: dealer second card = 10
		// rank encoding: 9=Ten
		// expected: dealer_count = 2
		// expected: next state becomes PLAYER_TURN
		drawn_rank = 4'd9;
		drawn_suit = 2'd3;
		player_score = 5'd19;
		dealer_score = 5'd16;
		@(posedge clk);
		@(posedge clk);

		// Test 7: player hit without busting
		// input: hit_pulse = 1
		// input: drawn card = 2
		// expected: player_count becomes 3
		// expected: player returns to PLAYER_TURN
		hit_pulse = 1;
		@(posedge clk);
		hit_pulse = 0;

		drawn_rank = 4'd1;
		drawn_suit = 2'd0;
		player_score = 5'd21;
		@(posedge clk);
		@(posedge clk);

		// Test 8: player stands
		// input: stand_pulse = 1
		// expected: dealer_hidden becomes 0
		// expected: state moves to DEALER_TURN
		stand_pulse = 1;
		@(posedge clk);
		stand_pulse = 0;
		@(posedge clk);

		// Test 9: dealer draws because dealer score is below 17
		// input: dealer_score = 16
		// input: drawn card = 4
		// expected: dealer_count becomes 3
		dealer_score = 5'd16;
		drawn_rank = 4'd3;
		drawn_suit = 2'd2;
		@(posedge clk);

		// Test 10: dealer stops after reaching at least 17
		// input: dealer_score = 20
		// expected: state moves to EVALUATE, then RESULT_ST
		dealer_score = 5'd20;
		player_score = 5'd21;
		@(posedge clk);
		@(posedge clk);

		// Test 11: evaluate player win
		// input: player_score = 21, dealer_score = 20
		// expected: result = 0
		// expected: game_state = 6
		@(posedge clk);

		// reset before second round
		reset = 1;
		repeat (2) @(posedge clk);
		reset = 0;
		@(posedge clk);

		// Test 12: start second game
		// input: start_pulse = 1 for one cycle
		// expected: next state becomes DEAL
		start_pulse = 1;
		@(posedge clk);
		start_pulse = 0;
		@(posedge clk);

		// Test 13: deal second round card 1
		// input: player first card = 10
		// expected: player_count = 1
		drawn_rank = 4'd9;
		drawn_suit = 2'd0;
		@(posedge clk);

		// Test 14: deal second round card 2
		// input: dealer first card = 7
		// expected: dealer_count = 1
		drawn_rank = 4'd6;
		drawn_suit = 2'd1;
		@(posedge clk);

		// Test 15: deal second round card 3
		// input: player second card = 9
		// expected: player_count = 2
		drawn_rank = 4'd8;
		drawn_suit = 2'd2;
		@(posedge clk);

		// Test 16: deal second round card 4
		// input: dealer second card = 8
		// expected: dealer_count = 2
		// expected: state moves to PLAYER_TURN
		drawn_rank = 4'd7;
		drawn_suit = 2'd3;
		player_score = 5'd19;
		dealer_score = 5'd15;
		@(posedge clk);
		@(posedge clk);

		// Test 17: player hits and busts
		// input: hit_pulse = 1
		// input: drawn card = 5
		// expected: player_count becomes 3
		// expected: result becomes dealer win
		hit_pulse = 1;
		@(posedge clk);
		hit_pulse = 0;

		drawn_rank = 4'd4;
		drawn_suit = 2'd0;
		player_score = 5'd24;
		@(posedge clk);

		// Test 18: player bust ends round
		// expected: game_state moves to RESULT_ST
		// expected: result = 1
		@(posedge clk);
		@(posedge clk);

		$stop;
	end

endmodule 