/* This module controls the main Blackjack game flow. It receives button
	pulses for start, hit, and stand, then moves through the game states for
	dealing cards, handling the player's turn, handling the dealer's turn,
	evaluating the winner, and showing the result. The FSM stores the player
	and dealer hands in rank and suit arrays, requests new cards from the card
	engine, hides the dealer's second card during the player's turn, and sends
	the current game state and result to the VGA renderer.

	Rank encoding:
	0=Ace, 1=Two, ..., 8=Nine, 9=Ten, 10=Jack, 11=Queen, 12=King

	Suit encoding:
	0=Spades, 1=Hearts, 2=Diamonds, 3=Clubs
	
	Result encoding:
	0=player wins, 1=dealer wins, 2=push
*/
module game_fsm (
	input  logic        clk,
	input  logic        reset,

	// button pulses from button_pulse modules
	input  logic        hit_pulse,
	input  logic        stand_pulse,
	input  logic        start_pulse,

	// card engine interface
	output logic        draw_req,
	input  logic [3:0]  drawn_rank,
	input  logic [1:0]  drawn_suit,

	// hand state outputs to pixel_renderer
	output logic [3:0]  player_ranks [6],
	output logic [1:0]  player_suits [6],
	output logic [2:0]  player_count,
	output logic [3:0]  dealer_ranks [6],
	output logic [1:0]  dealer_suits [6],
	output logic [2:0]  dealer_count,
	output logic        dealer_hidden,  // dealer card slot 1 is face-down

	// score inputs from score_calc
	input  logic [4:0]  player_score,
	input  logic [4:0]  dealer_score,

	// game state outputs
	output logic [2:0]  game_state,
	output logic [1:0]  result,
	output logic        deck_reset      // pulse high for one cycle on new game start


);


	// state encoding
	localparam logic [2:0]
		IDLE        = 3'd0,
		DEAL        = 3'd1,
		PLAYER_TURN = 3'd2,
		PLAYER_HIT  = 3'd3,
		DEALER_TURN = 3'd4,
		EVALUATE    = 3'd5,
		RESULT_ST   = 3'd6;

	logic [2:0] ps, ns;
	logic [1:0] deal_step, ns_deal_step;     // tracks which initial card is being dealt
	logic [1:0] result_r, ns_result;

	// Provisional player score checks what the player's score would be
	// after adding the newly drawn card. This lets the FSM detect a bust
	// immediately during PLAYER_HIT instead of waiting for the next cycle.
	logic [3:0] prov_player_ranks [6];
	logic [4:0] prov_player_score;

	score_calc prov_calc (
		.ranks (prov_player_ranks),
		.count (player_count + 3'd1),
		.score (prov_player_score)
	);

	always_comb begin
		for (int i = 0; i < 6; i++)
			prov_player_ranks[i] = player_ranks[i];

		// Temporarily place the drawn card into the next open player slot	
		// so prov_calc can calculate the score after a hit.
		prov_player_ranks[player_count] = drawn_rank;
	end

	// next state logic
	// This block decides where the FSM should go next, but it does not
	// update the stored cards or counts. The actual registers are updated
	// in the always_ff block below.
	always_comb begin
		ns           = ps;
		ns_deal_step = deal_step;
		ns_result    = result_r;

		case (ps)
			IDLE: begin
				if (start_pulse)
					ns = DEAL;
			end

			DEAL: begin
				if (deal_step == 2'd3)
					ns = PLAYER_TURN;
				else
					ns_deal_step = deal_step + 2'd1;
			end

			PLAYER_TURN: begin
				if (hit_pulse)
					ns = PLAYER_HIT;
				else if (stand_pulse)
					ns = DEALER_TURN;
			end

			PLAYER_HIT: begin
				if (prov_player_score > 5'd21) begin
					ns        = EVALUATE;
					ns_result = 2'd1; // dealer wins because player busts
				end else begin
					ns = PLAYER_TURN;
				end
			end

			DEALER_TURN: begin
				if (dealer_score >= 5'd17)
					ns = EVALUATE;
				// Otherwise, stay in DEALER_TURN and keep drawing.
			end

			EVALUATE: begin
				// Determine winner based on final player and dealer scores.
				if (player_score > 5'd21) begin
					ns_result = 2'd1; // dealer wins
				end else if (dealer_score > 5'd21) begin
					ns_result = 2'd0; // player wins
				end else if (player_score > dealer_score) begin
					ns_result = 2'd0; // player wins
				end else if (dealer_score > player_score) begin
					ns_result = 2'd1; // dealer wins
				end else begin
					ns_result = 2'd2; // push
				end

				ns = RESULT_ST;
			end

			RESULT_ST: begin
				if (start_pulse)
					ns = IDLE;
			end

			default: begin
				ns = IDLE;
			end
		endcase
	end

	// output logic
	// These outputs depend on the current state. draw_req asks the card
	// engine for a card, deck_reset clears the used-card tracking for a
	// new round, and dealer_hidden controls whether the second dealer card
	// is shown on the VGA display.
	always_comb begin
		draw_req      = 1'b0;
		deck_reset    = 1'b0;
		game_state    = ps;
		result        = result_r;
		dealer_hidden = (ps == PLAYER_TURN || ps == PLAYER_HIT);
		deck_reset    = (ps == IDLE) && start_pulse;

		case (ps)
			DEAL: begin
				draw_req = 1'b1;
			end

			PLAYER_HIT: begin
				draw_req = 1'b1;
			end

			DEALER_TURN: begin
				draw_req = (dealer_score < 5'd17);
			end

			default: begin
				draw_req = 1'b0;
			end
		endcase
	end

	// state update logic
	// This block stores cards into the player/dealer hand arrays and updates
	// the card counts on the rising edge of the clock.
	always_ff @(posedge clk) begin
		if (reset) begin
			ps           <= IDLE;
			deal_step    <= 2'd0;
			result_r     <= 2'd0;
			player_count <= 3'd0;
			dealer_count <= 3'd0;

			for (int i = 0; i < 6; i++) begin
				player_ranks[i] <= 4'd0;
				player_suits[i] <= 2'd0;
				dealer_ranks[i] <= 4'd0;
				dealer_suits[i] <= 2'd0;
			end
		end else begin
			ps       <= ns;
			result_r <= ns_result;

			case (ps)
				IDLE: begin
					if (start_pulse) begin
						// Clear hands before starting a new game.
						player_count <= 3'd0;
						dealer_count <= 3'd0;
						deal_step    <= 2'd0;

						for (int i = 0; i < 6; i++) begin
							player_ranks[i] <= 4'd0;
							player_suits[i] <= 2'd0;
							dealer_ranks[i] <= 4'd0;
							dealer_suits[i] <= 2'd0;
						end
					end
				end

				DEAL: begin
					deal_step <= ns_deal_step;

					// Deal order:
					// player card 0, dealer card 0, player card 1, dealer card 1.
					case (deal_step)
						2'd0: begin
							player_ranks[0] <= drawn_rank;
							player_suits[0] <= drawn_suit;
							player_count    <= 3'd1;
						end

						2'd1: begin
							dealer_ranks[0] <= drawn_rank;
							dealer_suits[0] <= drawn_suit;
							dealer_count    <= 3'd1;
						end

						2'd2: begin
							player_ranks[1] <= drawn_rank;
							player_suits[1] <= drawn_suit;
							player_count    <= 3'd2;
						end

						2'd3: begin
							dealer_ranks[1] <= drawn_rank;
							dealer_suits[1] <= drawn_suit;
							dealer_count    <= 3'd2;
						end
					endcase
				end

				PLAYER_HIT: begin
					// Add the newly drawn card to the next open player slot.
					player_ranks[player_count] <= drawn_rank;
					player_suits[player_count] <= drawn_suit;
					player_count               <= player_count + 3'd1;
				end

				DEALER_TURN: begin
					// Dealer keeps drawing while the score is below 17.
					if (dealer_score < 5'd17) begin
						dealer_ranks[dealer_count] <= drawn_rank;
						dealer_suits[dealer_count] <= drawn_suit;
						dealer_count               <= dealer_count + 3'd1;
					end
				end
			endcase
		end
	end

endmodule // game_fsm
