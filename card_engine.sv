/*	This module generates cards for the Blackjack game using a 16-bit LFSR.
   Each card is represented by a card_id from 0 to 51, which is converted
   into a suit and rank. A 52-bit register tracks which cards have already
   been drawn so the same card is not reused in one deck. When deck_reset is
   pulsed, the used-card register is cleared for a new game, but the LFSR
   continues running so the next game does not restart from the same card.
*/
module card_engine (
	input  logic        clk,
	input  logic        reset,
	input  logic        draw_req,    // assert for exactly one cycle to draw
	input  logic        deck_reset,  // pulse high for one cycle to clear deck for a new game
	output logic [5:0]  card_id,     // result valid while draw_req is high
	output logic [3:0]  drawn_rank,
	output logic [1:0]  drawn_suit
);
	logic [15:0] lfsr;
	logic [51:0] deck_used; // bit N = 1 -> card N already drawn

	logic [5:0] start_idx; // LFSR slice wrapped into 0-51
	logic [5:0] try_idx;   // candidate checked each loop iteration
	logic [5:0] found_id;  // first unused card found
	logic       found;     // latches true once a card is found

	// Combinational card search
	always_comb begin
		start_idx = (lfsr[5:0] >= 6'd52) ? lfsr[5:0] - 6'd52 : lfsr[5:0];

		found    = 1'b0;
		found_id = start_idx;

		// Walk forward from start_idx; stop updating once the first free card is found
		for (int i = 0; i < 52; i++) begin
			try_idx = (start_idx + 6'(i) >= 6'd52)
			          ? (start_idx + 6'(i) - 6'd52)
			          : (start_idx + 6'(i));
			if (!deck_used[try_idx] && !found) begin
				found    = 1'b1;
				found_id = try_idx;
			end
		end

		card_id = found_id;

		// Derive suit/rank via subtraction
		if      (card_id < 6'd13) begin drawn_suit = 2'd0; drawn_rank = card_id[3:0]; end
		else if (card_id < 6'd26) begin drawn_suit = 2'd1; drawn_rank = 4'(card_id - 6'd13); end
		else if (card_id < 6'd39) begin drawn_suit = 2'd2; drawn_rank = 4'(card_id - 6'd26); end
		else                      begin drawn_suit = 2'd3; drawn_rank = 4'(card_id - 6'd39); end
	end

	// LFSR and deck update
	always_ff @(posedge clk) begin
		if (reset) begin
			lfsr      <= 16'hACE1; // non-zero seed required for LFSR to run
			deck_used <= 52'b0;
		end else begin
			// LFSR advances every cycle — keeps draws random across games
			// Fibonacci right-shift, polynomial x^16+x^14+x^13+x^11+1 (maximal length, period 65535)
			lfsr <= {lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10], lfsr[15:1]};

			if (deck_reset)
				deck_used <= 52'b0;          // new game: reset used-card state
			else if (draw_req)
				deck_used[found_id] <= 1'b1; // mark drawn card as used
		end
	end
endmodule 