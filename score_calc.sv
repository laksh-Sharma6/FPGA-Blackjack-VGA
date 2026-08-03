/*	This module calculates the value of a Blackjack hand using the rank values
   stored in the input array. It supports up to 6 cards and uses count to
   decide how many cards are active. Number cards are added by their normal
   Blackjack values, face cards and tens count as 10, and aces are counted as
   1 first. If one ace can safely count as 11 without making the hand go over
   21, the module adds 10 to the final score.
*/
module score_calc (
	input  logic [3:0] ranks [6],   // up to 6 card ranks
	input  logic [2:0] count,       // number of cards in hand (0-6)
	output logic [4:0] score        // hand value (0-31; >21 = bust)
);
	logic [4:0] raw;        // sum with all aces as 1
	logic [2:0] num_aces;   // number of aces in hand
 
	always_comb begin
		raw      = 5'd0;
		num_aces = 3'd0;
 
		for (int i = 0; i < 6; i++) begin
			if (3'(i) < count) begin
				if (ranks[i] == 4'd0) begin
					// Ace counts as 1 initially
					raw      = raw + 5'd1;
					num_aces = num_aces + 3'd1;
				end else if (ranks[i] >= 4'd9) begin
					// Ten, J, Q, K all count as 10
					raw = raw + 5'd10;
				end else begin
					// Two through Nine
					raw = raw + {1'b0, ranks[i]} + 5'd1;
				end
			end
		end
 
		// Use one ace as 11 if it keeps the hand <= 21
		// Check raw <= 11 instead of (raw+10) <= 21 to avoid 5-bit overflow
		if (num_aces > 3'd0 && raw <= 5'd11)
			score = raw + 5'd10;
		else
			score = raw;
	end
	
endmodule 