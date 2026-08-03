/*	This is the top-level module for the FPGA Blackjack game. It connects
   the DE1-SoC inputs and outputs to the main game modules, including the
   button input logic, card engine, score calculators, game FSM, VGA driver,
   and pixel renderer. KEY buttons are used to reset, start, hit, and stand.
   The VGA output displays the Blackjack table and cards, while the HEX
   displays and LEDs are used for score and state debugging.
*/

module DE1_SoC (
   output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
   output logic [9:0] LEDR,

   input  logic [3:0] KEY,
   input  logic [9:0] SW,
	input  logic       CLOCK_50,

   output logic [7:0] VGA_R,
   output logic [7:0] VGA_G,
   output logic [7:0] VGA_B,
   output logic       VGA_BLANK_N,
   output logic       VGA_CLK,
   output logic       VGA_HS,
   output logic       VGA_SYNC_N,
   output logic       VGA_VS
);

   // KEY[0] is active-low reset.
   logic reset;
   assign reset = ~KEY[0];
	
   // VGA coordinate and color wires.
   logic [9:0] x;
   logic [8:0] y;
   logic [7:0] r, g, b;

   video_driver #(.WIDTH(640), .HEIGHT(480)) vga_driver (
       .CLOCK_50    (CLOCK_50),
       .reset       (reset),

       .x           (x),
       .y           (y),
       .r           (r),
       .g           (g),
       .b           (b),

       .VGA_R       (VGA_R),
       .VGA_G       (VGA_G),
       .VGA_B       (VGA_B),
       .VGA_BLANK_N (VGA_BLANK_N),
       .VGA_CLK     (VGA_CLK),
       .VGA_HS      (VGA_HS),
       .VGA_SYNC_N  (VGA_SYNC_N),
       .VGA_VS      (VGA_VS)
   );

   // KEY[1] = start, KEY[2] = hit, KEY[3] = stand.
   logic start_n_sync, hit_n_sync, stand_n_sync;
   logic start_pulse,  hit_pulse,  stand_pulse;

   sync2 start_sync (
       .Clock (CLOCK_50),
       .reset (reset),
       .async (KEY[1]),
       .sync  (start_n_sync)
   );

   sync2 hit_sync (
       .Clock (CLOCK_50),
       .reset (reset),
       .async (KEY[2]),
       .sync  (hit_n_sync)
   );

   sync2 stand_sync (
       .Clock (CLOCK_50),
       .reset (reset),
       .async (KEY[3]),
       .sync  (stand_n_sync)
   );

   button_pulse start_button (
       .Clock (CLOCK_50),
       .reset (reset),
       .key_n (start_n_sync),
       .pulse (start_pulse)
   );

   button_pulse hit_button (
       .Clock (CLOCK_50),
       .reset (reset),
       .key_n (hit_n_sync),
       .pulse (hit_pulse)
   );

   button_pulse stand_button (
       .Clock (CLOCK_50),
       .reset (reset),
       .key_n (stand_n_sync),
       .pulse (stand_pulse)
   );

   // Card engine outputs one card when draw_req is asserted.
   logic       draw_req;
   logic       deck_reset;
   logic [5:0] card_id;
   logic [3:0] drawn_rank;
   logic [1:0] drawn_suit;

   card_engine deck (
       .clk        (CLOCK_50),
       .reset      (reset),
       .draw_req   (draw_req),
       .deck_reset (deck_reset),

       .card_id    (card_id),
       .drawn_rank (drawn_rank),
       .drawn_suit (drawn_suit)
   );

   // Stored player and dealer hands.
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

   score_calc player_score_calc (
       .ranks (player_ranks),
       .count (player_count),
       .score (player_score)
   );

   score_calc dealer_score_calc (
       .ranks (dealer_ranks),
       .count (dealer_count),
       .score (dealer_score)
   );

   game_fsm game (
       .clk          (CLOCK_50),
       .reset        (reset),

       .hit_pulse    (hit_pulse),
       .stand_pulse  (stand_pulse),
       .start_pulse  (start_pulse),

       .draw_req     (draw_req),
       .deck_reset   (deck_reset),
       .drawn_rank   (drawn_rank),
       .drawn_suit   (drawn_suit),

       .player_ranks (player_ranks),
       .player_suits (player_suits),
       .player_count (player_count),

       .dealer_ranks (dealer_ranks),
       .dealer_suits (dealer_suits),
       .dealer_count (dealer_count),
       .dealer_hidden(dealer_hidden),

       .player_score (player_score),
       .dealer_score (dealer_score),

       .game_state   (game_state),
       .result       (result)
   );

   pixel_renderer renderer (
       .clk           (CLOCK_50),
       .reset         (reset),

       .x             (x),
       .y             (y),

       .player_ranks  (player_ranks),
       .player_suits  (player_suits),
       .player_count  (player_count),

       .dealer_ranks  (dealer_ranks),
       .dealer_suits  (dealer_suits),
       .dealer_count  (dealer_count),
       .dealer_hidden (dealer_hidden),

       .player_score  (player_score),
       .dealer_score  (dealer_score),

       .game_state    (game_state),
       .result        (result),

       .r             (r),
       .g             (g),
       .b             (b)
   );

   // LEDs show button pulses, current FSM state, and reset.
   assign LEDR[0]   = hit_pulse;
   assign LEDR[1]   = stand_pulse;
   assign LEDR[2]   = start_pulse;
	assign LEDR[5:3] = game_state;
   assign LEDR[6]   = reset;
   assign LEDR[9:7] = 3'b000;

   // HEX displays show scores for debugging.
   // HEX1 HEX0 = player score
   // HEX5 HEX4 = dealer score, hidden during player turn
   // HEX3 HEX2 = blank
   logic [3:0] player_ones, player_tens;
   logic [3:0] dealer_ones, dealer_tens;

   always_comb begin
       if      (player_score >= 5'd30) begin player_tens = 4'd3; player_ones = 4'(player_score - 5'd30); end
       else if (player_score >= 5'd20) begin player_tens = 4'd2; player_ones = 4'(player_score - 5'd20); end
       else if (player_score >= 5'd10) begin player_tens = 4'd1; player_ones = 4'(player_score - 5'd10); end
       else                            begin player_tens = 4'd0; player_ones = player_score[3:0];         end

       if      (dealer_score >= 5'd30) begin dealer_tens = 4'd3; dealer_ones = 4'(dealer_score - 5'd30); end
       else if (dealer_score >= 5'd20) begin dealer_tens = 4'd2; dealer_ones = 4'(dealer_score - 5'd20); end
       else if (dealer_score >= 5'd10) begin dealer_tens = 4'd1; dealer_ones = 4'(dealer_score - 5'd10); end
       else                            begin dealer_tens = 4'd0; dealer_ones = dealer_score[3:0];         end
   end

   assign HEX0 = sevenseg(player_ones);
   assign HEX1 = sevenseg(player_tens);
   assign HEX2 = 7'b1111111;
   assign HEX3 = 7'b1111111;
   assign HEX4 = dealer_hidden ? 7'b1111111 : sevenseg(dealer_ones);
   assign HEX5 = dealer_hidden ? 7'b1111111 : sevenseg(dealer_tens);

   // Active-low seven-segment decoder.
   function automatic logic [6:0] sevenseg(input logic [3:0] val);
       begin
           case (val)
               4'h0: sevenseg = 7'b1000000;
               4'h1: sevenseg = 7'b1111001;
               4'h2: sevenseg = 7'b0100100;
               4'h3: sevenseg = 7'b0110000;
               4'h4: sevenseg = 7'b0011001;
               4'h5: sevenseg = 7'b0010010;
               4'h6: sevenseg = 7'b0000010;
               4'h7: sevenseg = 7'b1111000;
               4'h8: sevenseg = 7'b0000000;
               4'h9: sevenseg = 7'b0010000;
               4'hA: sevenseg = 7'b0001000;
               4'hB: sevenseg = 7'b0000011;
               4'hC: sevenseg = 7'b1000110;
               4'hD: sevenseg = 7'b0100001;
               4'hE: sevenseg = 7'b0000110;
               4'hF: sevenseg = 7'b0001110;
               default: sevenseg = 7'b1111111;
           endcase
       end
   endfunction

endmodule // DE1_SoC