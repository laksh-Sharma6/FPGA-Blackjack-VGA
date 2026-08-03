/*	This module draws one suit symbol at a fixed VGA screen position. The suit
	graphics are stored in a ROM-style memory so the symbol pixels can be read
	from memory instead of being drawn directly in the main renderer. Each suit
	is stored as a 20 by 23 bitmap. The module checks whether the current VGA
	pixel is inside the symbol area, calculates the ROM address, reads the
	stored bitmap value, and outputs either a red or black pixel.
*/

module suit_drawer #(
	parameter int SYM_X = 0,
	parameter int SYM_Y = 0
)(
	input  logic       clk,
	input  logic [9:0] x,
	input  logic [8:0] y,

	input  logic [1:0] suit,
	input  logic       red,

	output logic       on,
	output logic [7:0] r,
	output logic [7:0] g,
	output logic [7:0] b

);

	// ROM storage for the suit graphics.
	// There are 4 suits, and each suit uses a 20 by 23 bitmap.
	// Total size = 4 * 20 * 23 = 1840 bits.
	(* ramstyle = "M10K" *) logic suit_rom [0:1839];

	logic [10:0] rom_addr;
	logic        valid_pixel;
	logic        red_reg;

	int px;
	int py;
	int ss;
	int addr;

	// Initialize the suit bitmap memory.
	// The first loop clears the ROM, and the nested loops set selected
	// pixels to 1 to form each suit shape.
	initial begin
		 for (addr = 0; addr < 1840; addr = addr + 1) begin
			  suit_rom[addr] = 1'b0;
		 end

		 // ss selects which suit bitmap is currently being initialized.
		 // ss = 0 spade, 1 heart, 2 diamond, 3 club.
		 for (ss = 0; ss < 4; ss = ss + 1) begin
			  for (py = 0; py < 23; py = py + 1) begin
					for (px = 0; px < 20; px = px + 1) begin

						 // Convert suit number, local y, and local x into one ROM address.
						 addr = ss * 460 + py * 20 + px;

						 // Spade
						 if (ss == 0) begin
							  if ((px >= 6 && px < 14  && py >= 0  && py < 4)  ||
									(px >= 3 && px < 17  && py >= 4  && py < 9)  ||
									(px >= 0 && px < 20  && py >= 9  && py < 14) ||
									(px >= 8 && px < 12  && py >= 14 && py < 22)) begin
									suit_rom[addr] = 1'b1;
							  end
						 end

						 // Heart
						 if (ss == 1) begin
							  if ((px >= 1 && px < 8   && py >= 0  && py < 7)  ||
									(px >= 12 && px < 19 && py >= 0  && py < 7)  ||
									(px >= 0 && px < 20  && py >= 5  && py < 12) ||
									(px >= 4 && px < 16  && py >= 12 && py < 17) ||
									(px >= 8 && px < 12  && py >= 17 && py < 21)) begin
									suit_rom[addr] = 1'b1;
							  end
						 end

						 // Diamond
						 if (ss == 2) begin
							  if ((px >= 8 && px < 12  && py >= 0  && py < 4)  ||
									(px >= 4 && px < 16  && py >= 4  && py < 9)  ||
									(px >= 0 && px < 20  && py >= 9  && py < 14) ||
									(px >= 4 && px < 16  && py >= 14 && py < 19) ||
									(px >= 8 && px < 12  && py >= 19 && py < 23)) begin
									suit_rom[addr] = 1'b1;
							  end
						 end

						 // Club
						 if (ss == 3) begin
							  if ((px >= 7 && px < 14  && py >= 0  && py < 7)  ||
									(px >= 2 && px < 9   && py >= 7  && py < 14) ||
									(px >= 12 && px < 19 && py >= 7  && py < 14) ||
									(px >= 7 && px < 14  && py >= 10 && py < 17) ||
									(px >= 9 && px < 12  && py >= 16 && py < 23)) begin
									suit_rom[addr] = 1'b1;
							  end
						 end

					end
			  end
		 end
	end

	// Check whether the current VGA pixel is inside the 20 by 23 symbol box.
	// If it is inside, calculate the matching address in the suit ROM.
	always_comb begin
		 valid_pixel = 1'b0;
		 rom_addr    = 11'd0;

		 if ((x >= SYM_X) && (x < SYM_X + 20) &&
			  (y >= SYM_Y) && (y < SYM_Y + 23)) begin
			  valid_pixel = 1'b1;
			  rom_addr = suit * 11'd460 + (y - SYM_Y) * 11'd20 + (x - SYM_X);
		 end
	end

	// Register the ROM output for the current pixel.
	// red is also registered so the color stays aligned with the ROM read.
	always_ff @(posedge clk) begin
		 red_reg <= red;
		 on      <= valid_pixel && suit_rom[rom_addr];
	end

	// Choose the output color for the suit pixel.
	// Hearts and diamonds use red, while spades and clubs use black.
	always_comb begin
		 if (on && red_reg) begin
			  r = 8'hE0;
			  g = 8'h00;
			  b = 8'h00;
		 end else if (on) begin
			  r = 8'h00;
			  g = 8'h00;
			  b = 8'h00;
		 end else begin
			  r = 8'h00;
			  g = 8'h00;
			  b = 8'h00;
		 end
	end

endmodule // suit_drawer