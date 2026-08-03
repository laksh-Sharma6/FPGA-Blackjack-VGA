/*	This module controls the VGA pixel colors for the Blackjack game screen.
	It takes the current x and y pixel location from the VGA driver and decides
	what RGB color should be shown at that pixel. The background, card areas,
	idle box, and result box are drawn with rectangle checks. The actual card
	graphics are produced by card_drawer modules, and this renderer chooses
	whether to show the dealer cards, player cards, or screen UI elements.
*/

module pixel_renderer (
	input  logic        clk,
	input  logic        reset,

	input  logic [9:0]  x,
	input  logic [8:0]  y,

	input  logic [3:0]  player_ranks [6],
	input  logic [1:0]  player_suits [6],
	input  logic [2:0]  player_count,

	input  logic [3:0]  dealer_ranks [6],
	input  logic [1:0]  dealer_suits [6],
	input  logic [2:0]  dealer_count,
	input  logic        dealer_hidden,

	input  logic [4:0]  player_score,
	input  logic [4:0]  dealer_score,

	input  logic [2:0]  game_state,
	input  logic [1:0]  result,

	output logic [7:0]  r,
	output logic [7:0]  g,
	output logic [7:0]  b
);

	// FSM states used by the renderer for extra screen elements.
	// IDLE shows the start box, and RESULT_ST shows the result box.
	localparam logic [2:0] IDLE      = 3'd0;
	localparam logic [2:0] RESULT_ST = 3'd6;

	// Card size and placement constants.
	// The X0/Y0 values define where the first card in each row begins.
	localparam int CARD_W    = 62;
	localparam int CARD_H    = 82;
	localparam int CARD_GAP  = 12;
	localparam int DEALER_X0 = 110;
	localparam int DEALER_Y0 = 70;
	localparam int PLAYER_X0 = 110;
	localparam int PLAYER_Y0 = 315;

	// Each card_drawer gives its own on signal and RGB color.
	// d_* signals are for dealer cards, and p_* signals are for player cards.
	logic       d_on [6],  p_on [6];
	logic [7:0] d_r  [6],  p_r  [6];
	logic [7:0] d_g  [6],  p_g  [6];
	logic [7:0] d_b  [6],  p_b  [6];

	// Generate six dealer card_drawer modules.
	// Each copy is placed one card width plus one gap farther to the right.
	genvar gi;
	generate
	for (gi = 0; gi < 6; gi++) begin : gen_dealer
	card_drawer #(
		.CARD_X (DEALER_X0 + gi * (CARD_W + CARD_GAP)),
		.CARD_Y (DEALER_Y0),
		.CARD_W (CARD_W),
		.CARD_H (CARD_H)
	) inst (
		.clk    (clk),
		.x      (x),
		.y      (y),
		.rank   (dealer_ranks[gi]),
		.suit   (dealer_suits[gi]),
		.hidden (gi == 1 ? dealer_hidden : 1'b0),
		.on     (d_on[gi]),
		.r      (d_r[gi]),
		.g      (d_g[gi]),
		.b      (d_b[gi])
	);
	
	end


   // Generate six player card_drawer modules.
   // Player cards are never hidden, so hidden is tied to 0.
   for (gi = 0; gi < 6; gi++) begin : gen_player
       card_drawer #(
           .CARD_X (PLAYER_X0 + gi * (CARD_W + CARD_GAP)),
           .CARD_Y (PLAYER_Y0),
           .CARD_W (CARD_W),
           .CARD_H (CARD_H)
       ) inst (
           .clk    (clk),
           .x      (x),
           .y      (y),
           .rank   (player_ranks[gi]),
           .suit   (player_suits[gi]),
           .hidden (1'b0),
           .on     (p_on[gi]),
           .r      (p_r[gi]),
           .g      (p_g[gi]),
           .b      (p_b[gi])
       );
   end

	endgenerate

	// Returns true when the current pixel is inside a rectangle.
	// This is used for the table borders, card row areas, and UI boxes.
	function automatic logic in_rect(
		input int px, py, rx, ry, rw, rh
	);
		in_rect = (px >= rx) && (px < rx + rw) &&
		(py >= ry) && (py < ry + rh);
		
	endfunction

	// This block chooses the final RGB value for the current pixel.
	// It starts with the table background, then later drawing checks can
	// overwrite the color if the pixel belongs to a card or UI box.
	always_comb begin
		r = 8'h00;
		g = 8'h70;
		b = 8'h20;

		// Darker top and bottom border areas of the table.
		if (in_rect(x, y, 0, 0, 640, 45) ||
			 in_rect(x, y, 0, 435, 640, 45)) begin
			 r = 8'h00; g = 8'h20; b = 8'h10;
		end

		// Dealer card row background.
		if (in_rect(x, y, 90, 55, 460, 110)) begin
			 r = 8'h00; g = 8'h50; b = 8'h20;
		end

		// Player card row background.
		if (in_rect(x, y, 90, 300, 460, 110)) begin
			 r = 8'h00; g = 8'h50; b = 8'h20;
		end

		// Draw active dealer cards over the background.
		// A card is active only if its index is less than dealer_count.
		// d_on[i] means the current pixel is inside dealer card i.
		for (int i = 0; i < 6; i++) begin
			 if (3'(i) < dealer_count && d_on[i]) begin
				  r = d_r[i]; g = d_g[i]; b = d_b[i];
			 end
		end

		// Draw active player cards over the background.
		// p_on[i] means the current pixel is inside player card i.
		for (int i = 0; i < 6; i++) begin
			 if (3'(i) < player_count && p_on[i]) begin
				  r = p_r[i]; g = p_g[i]; b = p_b[i];
			 end
		end

		// When the game is idle, draw a simple start box in the middle.
		// The larger rectangle is the border and the smaller one is the fill.
		if (game_state == IDLE) begin
			 if (in_rect(x, y, 210, 210, 220, 60)) begin
				  r = 8'h00; g = 8'h00; b = 8'h00;
			 end
			 if (in_rect(x, y, 215, 215, 210, 50)) begin
				  r = 8'hE0; g = 8'hE0; b = 8'h00;
			 end
		end

		// When the game reaches the result state, draw the result box.
		// Green means player wins, red means dealer wins, and gray means push.
		if (game_state == RESULT_ST) begin
			 if (in_rect(x, y, 200, 210, 240, 70)) begin
				  r = 8'h00; g = 8'h00; b = 8'h00;
			 end
			 if (in_rect(x, y, 205, 215, 230, 60)) begin
				  case (result)
						2'd0: begin r = 8'h40; g = 8'hFF; b = 8'h40; end
						2'd1: begin r = 8'hFF; g = 8'h30; b = 8'h30; end
						2'd2: begin r = 8'h80; g = 8'h80; b = 8'h80; end
						default: begin r = 8'hFF; g = 8'hFF; b = 8'hFF; end
				  endcase
			 end
		end

	end

endmodule // pixel_renderer
