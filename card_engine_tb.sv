`timescale 1 ps / 1 ps

module card_engine_tb();

	logic clk;
	logic reset;
	logic draw_req;
	logic deck_reset;

	logic [5:0] card_id;
	logic [3:0] drawn_rank;
	logic [1:0] drawn_suit;

	// instantiate DUT
	card_engine dut (
		.clk(clk),
		.reset(reset),
		.draw_req(draw_req),
		.deck_reset(deck_reset),
		.card_id(card_id),
		.drawn_rank(drawn_rank),
		.drawn_suit(drawn_suit)
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
		draw_req = 0;
		deck_reset = 0;

		// hold reset for 2 cycles
		repeat (2) @(posedge clk);
		reset = 0;
		@(posedge clk);

		// Test 1: output after reset
		// expected: card_id is between 0 and 51
		// expected: drawn_rank is between 0 and 12
		// expected: drawn_suit is between 0 and 3
		@(posedge clk);

		// Test 2: draw one card
		// input: draw_req = 1 for one cycle
		// expected: selected card is marked as used internally
		// expected: card_id is still between 0 and 51
		draw_req = 1;
		deck_reset = 0;
		@(posedge clk);
		draw_req = 0;
		@(posedge clk);

		// Test 3: draw another card
		// input: draw_req = 1 for one cycle
		// expected: another valid card is selected
		// expected: card_id is between 0 and 51
		// expected: rank and suit match the selected card_id
		draw_req = 1;
		deck_reset = 0;
		@(posedge clk);
		draw_req = 0;
		@(posedge clk);

		// Test 4: draw several cards from the same deck
		// input: five one-cycle draw requests
		// expected: card_engine continues producing valid cards
		// expected: used cards are skipped instead of being selected again
		repeat (5) begin
			draw_req = 1;
			deck_reset = 0;
			@(posedge clk);
			draw_req = 0;
			@(posedge clk);
		end

		// Test 5: reset deck for a new game
		// input: deck_reset = 1 for one cycle
		// expected: used-card state is cleared
		// expected: LFSR keeps running and does not reset to the original seed
		deck_reset = 1;
		draw_req = 0;
		@(posedge clk);
		deck_reset = 0;
		@(posedge clk);

		// Test 6: draw after deck reset
		// input: draw_req = 1 for one cycle after deck_reset
		// expected: card_engine can draw from a newly cleared deck
		// expected: card_id is between 0 and 51
		draw_req = 1;
		deck_reset = 0;
		@(posedge clk);
		draw_req = 0;
		@(posedge clk);

		$stop;
	end

endmodule 