/*	This module draws a rank symbol (A, 2-9, 10, J, Q, K) at a fixed screen
	position using a bitmap ROM stored in M10K. All 13 ranks are packed into
	a 390-entry by 20-bit ROM where each entry holds one row of pixels. The
	address for any pixel is rank * 30 + row. The ROM is read synchronously
	to ensure Quartus infers M10K, and bit_index selects the column within
	the registered row data each cycle.

	Total ROM size: 13 * 30 * 20 = 7800 bits
	Rank encoding: 0=A  1=2  2=3 ... 8=9  9=10  10=J  11=Q  12=K
	Bit ordering:  bit 19 = leftmost pixel, bit 0 = rightmost pixel
*/

module rank_drawer #(
	parameter int SYM_X = 0,
	parameter int SYM_Y = 0
)(
	input  logic       clk,
	input  logic [9:0] x,
	input  logic [8:0] y,

	input  logic [3:0] rank,
	input  logic       red,    // 1 = red suit (hearts/diamonds), 0 = black

	output logic       on,
	output logic [7:0] r,
	output logic [7:0] g,
	output logic [7:0] b
);

	// 390 rows of 20 bits, forced into M10K by the pragma
	(* ramstyle = "M10K" *) logic [19:0] rank_rom [0:389];

	logic [8:0]  rom_addr;
	logic [19:0] row_data;
	logic        valid_pixel;
	logic        valid_reg;
	logic        red_reg;
	logic [4:0]  local_x;
	logic [4:0]  local_y;
	logic [4:0]  bit_index;

	int rr;
	int py;
	int addr;
	logic [19:0] row_bits;

	// Build ROM at elaboration time. Each rank is described as horizontal
	// bands using bitmasks ORed into row_bits for each range of py values.
	initial begin
		for (rr = 0; rr < 13; rr = rr + 1) begin
			for (py = 0; py < 30; py = py + 1) begin
				addr     = rr * 30 + py;
				row_bits = 20'b00000000000000000000;

				case (rr)

					// A: top bar, upper sides, crossbar, lower sides
					0: begin
						if ((py >= 0)  && (py < 3))  row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 3)  && (py < 14)) row_bits = row_bits | 20'b11100000000000000111;
						if ((py >= 14) && (py < 17)) row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 16) && (py < 27)) row_bits = row_bits | 20'b11100000000000000111;
					end

					// 2: top bar, right side, middle bar, left side, bottom bar
					1: begin
						if ((py >= 0)  && (py < 3))  row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 3)  && (py < 14)) row_bits = row_bits | 20'b00000000000000000111;
						if ((py >= 14) && (py < 17)) row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 16) && (py < 27)) row_bits = row_bits | 20'b11100000000000000000;
						if ((py >= 27) && (py < 30)) row_bits = row_bits | 20'b00011111111111111000;
					end

					// 3: top bar, right side, middle bar, right side, bottom bar
					2: begin
						if ((py >= 0)  && (py < 3))  row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 3)  && (py < 14)) row_bits = row_bits | 20'b00000000000000000111;
						if ((py >= 14) && (py < 17)) row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 16) && (py < 27)) row_bits = row_bits | 20'b00000000000000000111;
						if ((py >= 27) && (py < 30)) row_bits = row_bits | 20'b00011111111111111000;
					end

					// 4: both sides, crossbar, right side only
					3: begin
						if ((py >= 3)  && (py < 14)) row_bits = row_bits | 20'b11100000000000000111;
						if ((py >= 14) && (py < 17)) row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 16) && (py < 27)) row_bits = row_bits | 20'b00000000000000000111;
					end

					// 5: top bar, left side, middle bar, right side, bottom bar
					4: begin
						if ((py >= 0)  && (py < 3))  row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 3)  && (py < 14)) row_bits = row_bits | 20'b11100000000000000000;
						if ((py >= 14) && (py < 17)) row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 16) && (py < 27)) row_bits = row_bits | 20'b00000000000000000111;
						if ((py >= 27) && (py < 30)) row_bits = row_bits | 20'b00011111111111111000;
					end

					// 6: top bar, left side, middle bar, both sides, bottom bar
					5: begin
						if ((py >= 0)  && (py < 3))  row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 3)  && (py < 14)) row_bits = row_bits | 20'b11100000000000000000;
						if ((py >= 14) && (py < 17)) row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 16) && (py < 27)) row_bits = row_bits | 20'b11100000000000000111;
						if ((py >= 27) && (py < 30)) row_bits = row_bits | 20'b00011111111111111000;
					end

					// 7: top bar and right side only
					6: begin
						if ((py >= 0)  && (py < 3))  row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 3)  && (py < 14)) row_bits = row_bits | 20'b00000000000000000111;
						if ((py >= 16) && (py < 27)) row_bits = row_bits | 20'b00000000000000000111;
					end

					// 8: top bar, both sides, middle bar, both sides, bottom bar
					7: begin
						if ((py >= 0)  && (py < 3))  row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 3)  && (py < 14)) row_bits = row_bits | 20'b11100000000000000111;
						if ((py >= 14) && (py < 17)) row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 16) && (py < 27)) row_bits = row_bits | 20'b11100000000000000111;
						if ((py >= 27) && (py < 30)) row_bits = row_bits | 20'b00011111111111111000;
					end

					// 9: top bar, both sides, middle bar, right side, bottom bar
					8: begin
						if ((py >= 0)  && (py < 3))  row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 3)  && (py < 14)) row_bits = row_bits | 20'b11100000000000000111;
						if ((py >= 14) && (py < 17)) row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 16) && (py < 27)) row_bits = row_bits | 20'b00000000000000000111;
						if ((py >= 27) && (py < 30)) row_bits = row_bits | 20'b00011111111111111000;
					end

					// 10: left half draws "1" (solid bar), right half draws "0" (outline)
					9: begin
						row_bits = row_bits | 20'b00111000000000000000; // "1" stem
						if ((py >= 0)  && (py < 3))  row_bits = row_bits | 20'b00000000111111111110; // top of 0
						if ((py >= 3)  && (py < 27)) row_bits = row_bits | 20'b00000000111000000111; // sides of 0
						if ((py >= 27) && (py < 30)) row_bits = row_bits | 20'b00000000111111111110; // bottom of 0
					end

					// J: right side upper, both sides lower, bottom bar hook
					10: begin
						if ((py >= 3)  && (py < 14)) row_bits = row_bits | 20'b00000000000000000111;
						if ((py >= 16) && (py < 27)) row_bits = row_bits | 20'b11100000000000000111;
						if ((py >= 27) && (py < 30)) row_bits = row_bits | 20'b00011111111111111000;
					end

					// Q: same outline as O plus a small tail at the bottom right
					11: begin
						if ((py >= 0)  && (py < 3))  row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 3)  && (py < 14)) row_bits = row_bits | 20'b11100000000000000111;
						if ((py >= 16) && (py < 27)) row_bits = row_bits | 20'b11100000000000000111;
						if ((py >= 27) && (py < 30)) row_bits = row_bits | 20'b00011111111111111000;
						if ((py >= 23) && (py < 30)) row_bits = row_bits | 20'b00000000000001111111; // tail
					end

					// K: full-height left stem plus upper and lower staircase arms
					12: begin
						row_bits = row_bits | 20'b11100000000000000000; // stem
						if ((py >= 0)  && (py < 4))  row_bits = row_bits | 20'b00000000000000111111; // upper arm
						if ((py >= 4)  && (py < 9))  row_bits = row_bits | 20'b00000000000111110000;
						if ((py >= 9)  && (py < 14)) row_bits = row_bits | 20'b00011111110000000000;
						if ((py >= 16) && (py < 21)) row_bits = row_bits | 20'b00011111110000000000; // lower arm
						if ((py >= 21) && (py < 26)) row_bits = row_bits | 20'b00000000000111110000;
						if ((py >= 26) && (py < 30)) row_bits = row_bits | 20'b00000000000000111111;
					end

					default: row_bits = 20'b00000000000000000000;
				endcase

				rank_rom[addr] = row_bits;
			end
		end
	end

	// Compute ROM address and bit index from the current scan position
	always_comb begin
		valid_pixel = 1'b0;
		rom_addr    = 9'd0;
		local_x     = 5'd0;
		local_y     = 5'd0;
		bit_index   = 5'd0;

		if ((x >= SYM_X) && (x < SYM_X + 20) &&
		    (y >= SYM_Y) && (y < SYM_Y + 30) &&
		    (rank < 4'd13)) begin
			valid_pixel = 1'b1;
			local_x     = x - SYM_X;
			local_y     = y - SYM_Y;
			rom_addr    = rank * 9'd30 + local_y;
			bit_index   = 5'd19 - local_x;
		end
	end

	// Registered ROM read so Quartus infers M10K
	always_ff @(posedge clk) begin
		row_data  <= rank_rom[rom_addr];
		valid_reg <= valid_pixel;
		red_reg   <= red;
	end

	// Assert on when the registered valid flag and the current ROM bit are both set
	always_comb begin
		on = valid_reg && row_data[bit_index];

		if (on && red_reg) begin
			r = 8'hE0; g = 8'h00; b = 8'h00; // red suit
		end else if (on) begin
			r = 8'h00; g = 8'h00; b = 8'h00; // black suit
		end else begin
			r = 8'h00; g = 8'h00; b = 8'h00;
		end
	end

endmodule 