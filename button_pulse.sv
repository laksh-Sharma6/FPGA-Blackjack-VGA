//creates a singular pulse for either keys 3,2 or 0 depending on the input

module button_pulse (Clock, reset, key_n, pulse);

	input logic Clock;
	input logic reset;
	input logic key_n; // active-low button input
	output logic pulse; // 1 clock pulse on button press

	logic key_prev_n;

	always_ff @(posedge Clock or posedge reset) begin
		if (reset) begin
			key_prev_n <= 1'b1;   // unpressed state for active-low button
         pulse      <= 1'b0;
      end
      else begin
          // pulse when button goes from 1 to 0
          pulse      <= key_prev_n & ~key_n;
          key_prev_n <= key_n;
      end
   end

endmodule 
