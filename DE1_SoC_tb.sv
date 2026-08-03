module DE1_SoC_tb();

	logic clk;
	logic [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	logic [9:0] LEDR;
	wire [35:0] V_GPIO;

	// drive signals for V_GPIO inputs
	logic reset_drv, outer_drv, inner_drv;

	// connect only the input bits you want to drive
	assign V_GPIO[23] = reset_drv;
	assign V_GPIO[24] = outer_drv;
	assign V_GPIO[28] = inner_drv;
	
	// instantiate DUT
	DE1_SoC dut (
		.CLOCK_50(clk),
		.HEX0(HEX0),
		.HEX1(HEX1),
		.HEX2(HEX2),
		.HEX3(HEX3),
		.HEX4(HEX4),
		.HEX5(HEX5),
		.LEDR(LEDR),
		.V_GPIO(V_GPIO)
	);

	parameter CLOCK_PERIOD = 100;

	// clock generation
	initial begin
		clk = 0;
		forever #(CLOCK_PERIOD/2) clk = ~clk;
	end

	initial begin
		// initial values
		reset_drv = 0;
		outer_drv = 0;
		inner_drv = 0;

		// hold reset for 2 cycles
		reset_drv = 1;
		repeat (2) @(posedge clk);
		reset_drv = 0;
		repeat (2) @(posedge clk);

		// Test 1: add one car
		outer_drv = 1; inner_drv = 0;   // 10
		repeat (2) @(posedge clk);

		outer_drv = 1; inner_drv = 1;   // 11
		repeat (2) @(posedge clk);

		outer_drv = 0; inner_drv = 1;   // 01
		repeat (2) @(posedge clk);

		outer_drv = 0; inner_drv = 0;   // 00
		repeat (2) @(posedge clk);

		// Test 2: subtract one car
		outer_drv = 0; inner_drv = 1;   // 01
		repeat (2) @(posedge clk);

		outer_drv = 1; inner_drv = 1;   // 11
		repeat (2) @(posedge clk);

		outer_drv = 1; inner_drv = 0;   // 10
		repeat (2) @(posedge clk);

		outer_drv = 0; inner_drv = 0;   // 00
		repeat (2) @(posedge clk);

		// Test 3: try subtracting when empty
		outer_drv = 0; inner_drv = 1;   // 01
		repeat (2) @(posedge clk);

		outer_drv = 1; inner_drv = 1;   // 11
		repeat (2) @(posedge clk);

		outer_drv = 1; inner_drv = 0;   // 10
		repeat (2) @(posedge clk);

		outer_drv = 0; inner_drv = 0;   // 00
		repeat (2) @(posedge clk);

		// Test 4: fill lot to 18
		repeat (18) begin
			outer_drv = 1; inner_drv = 0;   // 10
			repeat (2) @(posedge clk);

			outer_drv = 1; inner_drv = 1;   // 11
			repeat (2) @(posedge clk);

			outer_drv = 0; inner_drv = 1;   // 01
			repeat (2) @(posedge clk);

			outer_drv = 0; inner_drv = 0;   // 00
			repeat (2) @(posedge clk);
		end

		// Test 5: try adding when full
		outer_drv = 1; inner_drv = 0;   // 10
		repeat (2) @(posedge clk);

		outer_drv = 1; inner_drv = 1;   // 11
		repeat (2) @(posedge clk);

		outer_drv = 0; inner_drv = 1;   // 01
		repeat (2) @(posedge clk);

		outer_drv = 0; inner_drv = 0;   // 00
		repeat (2) @(posedge clk);

		// Test 6: subtract one car from full
		outer_drv = 0; inner_drv = 1;   // 01
		repeat (2) @(posedge clk);

		outer_drv = 1; inner_drv = 1;   // 11
		repeat (2) @(posedge clk);

		outer_drv = 1; inner_drv = 0;   // 10
		repeat (2) @(posedge clk);

		outer_drv = 0; inner_drv = 0;   // 00
		repeat (2) @(posedge clk);

		$stop;
	end

endmodule