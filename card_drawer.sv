/*	This module draws one playing card at a fixed VGA screen position. The
	card position and size are set by parameters, so the same module can be
	reused for every player and dealer card. The module first draws the card
	border and card face. If hidden is high, it draws the card back instead
	of the rank and suit. If hidden is low, it uses rank_drawer and suit_drawer
	modules to place ROM-based rank and suit graphics on the card.
*/

module card_drawer #(
	parameter int CARD_X = 0,
	parameter int CARD_Y = 0,
	parameter int CARD_W = 62,
	parameter int CARD_H = 82
)(
	input  logic       clk,
	input  logic [9:0] x,
	input  logic [8:0] y,

	input  logic [3:0] rank,
	input  logic [1:0] suit,
	input  logic       hidden,

	output logic       on,
	output logic [7:0] r,
	output logic [7:0] g,
	output logic [7:0] b
);

	// Hearts and diamonds are red. Spades and clubs are black.
	logic red_suit;

	// RGB outputs from the top rank symbol.
	logic rank_top_on;
	logic [7:0] rank_top_r;
	logic [7:0] rank_top_g;
	logic [7:0] rank_top_b;

	// RGB outputs from the bottom rank symbol.
	logic rank_bottom_on;
	logic [7:0] rank_bottom_r;
	logic [7:0] rank_bottom_g;
	logic [7:0] rank_bottom_b;

	// RGB outputs from the top suit symbol.
	logic suit_top_on;
	logic [7:0] suit_top_r;
	logic [7:0] suit_top_g;
	logic [7:0] suit_top_b;

	// RGB outputs from the bottom suit symbol.
	logic suit_bottom_on;
	logic [7:0] suit_bottom_r;
	logic [7:0] suit_bottom_g;
	logic [7:0] suit_bottom_b;

	assign red_suit = (suit == 2'd1) || (suit == 2'd2);

	// Draw the rank in the upper-left area of the card.
	rank_drawer #(
		 .SYM_X(CARD_X + 8),
		 .SYM_Y(CARD_Y + 8)
	) rank_top (
		 .clk  (clk),
		 .x    (x),
		 .y    (y),
		 .rank (rank),
		 .red  (red_suit),
		 .on   (rank_top_on),
		 .r    (rank_top_r),
		 .g    (rank_top_g),
		 .b    (rank_top_b)
	);

	// Draw the suit in the upper-right area of the card.
	suit_drawer #(
		 .SYM_X(CARD_X + CARD_W - 29),
		 .SYM_Y(CARD_Y + 9)
	) suit_top (
		 .clk  (clk),
		 .x    (x),
		 .y    (y),
		 .suit (suit),
		 .red  (red_suit),
		 .on   (suit_top_on),
		 .r    (suit_top_r),
		 .g    (suit_top_g),
		 .b    (suit_top_b)
	);

	// Draw the repeated rank near the bottom of the card.
	rank_drawer #(
		 .SYM_X(CARD_X + 8),
		 .SYM_Y(CARD_Y + CARD_H - 38)
	) rank_bottom (
		 .clk  (clk),
		 .x    (x),
		 .y    (y),
		 .rank (rank),
		 .red  (red_suit),
		 .on   (rank_bottom_on),
		 .r    (rank_bottom_r),
		 .g    (rank_bottom_g),
		 .b    (rank_bottom_b)
	);

	// Draw the repeated suit near the bottom of the card.
	suit_drawer #(
		 .SYM_X(CARD_X + CARD_W - 29),
		 .SYM_Y(CARD_Y + CARD_H - 32)
	) suit_bottom (
		 .clk  (clk),
		 .x    (x),
		 .y    (y),
		 .suit (suit),
		 .red  (red_suit),
		 .on   (suit_bottom_on),
		 .r    (suit_bottom_r),
		 .g    (suit_bottom_g),
		 .b    (suit_bottom_b)
	);

	// Select the final card pixel color.
	// The module starts with no pixel drawn, then checks whether the current
	// VGA coordinate is inside the card border, card face, hidden-card design,
	// or visible rank/suit symbols.
	always_comb begin
		 on = 1'b0;
		 r  = 8'h00;
		 g  = 8'h00;
		 b  = 8'h00;

		 // Draw the outer black card border.
		 if ((x >= CARD_X) && (x < CARD_X + CARD_W) &&
			  (y >= CARD_Y) && (y < CARD_Y + CARD_H)) begin
			  on = 1'b1;
			  r  = 8'h00;
			  g  = 8'h00;
			  b  = 8'h00;
		 end

		 // Draw the inside of the card.
		 // Hidden cards use a blue card back, while visible cards use
		 // an off-white card face.
		 if ((x >= CARD_X + 3) && (x < CARD_X + CARD_W - 3) &&
			  (y >= CARD_Y + 3) && (y < CARD_Y + CARD_H - 3)) begin
			  on = 1'b1;

			  if (hidden) begin
					r = 8'h00;
					g = 8'h20;
					b = 8'hC0;
			  end else begin
					r = 8'hF0;
					g = 8'hF0;
					b = 8'hE8;
			  end
		 end

		 // If this is a hidden dealer card, draw white stripes on the card back.
		 if (hidden) begin
			  if ((x >= CARD_X + 12) && (x < CARD_X + CARD_W - 12) &&
					(y >= CARD_Y + 14) && (y < CARD_Y + 19)) begin
					on = 1'b1; r = 8'hFF; g = 8'hFF; b = 8'hFF;
			  end

			  if ((x >= CARD_X + 12) && (x < CARD_X + CARD_W - 12) &&
					(y >= CARD_Y + 30) && (y < CARD_Y + 35)) begin
					on = 1'b1; r = 8'hFF; g = 8'hFF; b = 8'hFF;
			  end

			  if ((x >= CARD_X + 12) && (x < CARD_X + CARD_W - 12) &&
					(y >= CARD_Y + 46) && (y < CARD_Y + 51)) begin
					on = 1'b1; r = 8'hFF; g = 8'hFF; b = 8'hFF;
			  end

			  if ((x >= CARD_X + 12) && (x < CARD_X + CARD_W - 12) &&
					(y >= CARD_Y + 62) && (y < CARD_Y + 67)) begin
					on = 1'b1; r = 8'hFF; g = 8'hFF; b = 8'hFF;
			  end
		 end

		 // If the card is visible, draw the rank and suit symbols over the face.
		 // The symbol drawer outputs overwrite the card face color only where
		 // the current pixel is part of a rank or suit bitmap.
		 if (!hidden) begin
			  if (rank_top_on) begin
					on = 1'b1;
					r  = rank_top_r;
					g  = rank_top_g;
					b  = rank_top_b;
			  end

			  if (suit_top_on) begin
					on = 1'b1;
					r  = suit_top_r;
					g  = suit_top_g;
					b  = suit_top_b;
			  end

			  if (rank_bottom_on) begin
					on = 1'b1;
					r  = rank_bottom_r;
					g  = rank_bottom_g;
					b  = rank_bottom_b;
			  end

			  if (suit_bottom_on) begin
					on = 1'b1;
					r  = suit_bottom_r;
					g  = suit_bottom_g;
					b  = suit_bottom_b;
			  end
		 end
	end

endmodule 