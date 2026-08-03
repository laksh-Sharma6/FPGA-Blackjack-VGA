# Project root is ModelSim's current working directory.
set project_dir [pwd]

# Select testbench.
if {$argc > 0} {
    set module $1
} else {
    set module score_calc_tb
}

puts "Project directory: $project_dir"
puts "Running testbench: $module"

# Recreate work library.
if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

# Active Blackjack source files.
set design_files [list \
    [file join $project_dir button_pulse.sv] \
    [file join $project_dir card_drawer.sv] \
    [file join $project_dir card_engine.sv] \
    [file join $project_dir game_fsm.sv] \
    [file join $project_dir pixel_renderer.sv] \
    [file join $project_dir rank_drawer.sv] \
    [file join $project_dir score_calc.sv] \
    [file join $project_dir suit_drawer.sv] \
    [file join $project_dir sync2.sv] \
    [file join $project_dir video_driver.sv] \
    [file join $project_dir DE1_SoC.sv] \
]

# Select the requested testbench file.
set testbench_file [file join $project_dir "${module}.sv"]

if {![file exists $testbench_file]} {
    error "Testbench file not found: $testbench_file"
}

# Compile active design files and selected testbench.
eval vlog -sv $design_files
vlog -sv $testbench_file

# Compile VGA support.
vlog [file join $project_dir altera_up_avalon_video_vga_timing.v]

# Load and run testbench.
vsim -voptargs="+acc" -t 1ps work.$module

view wave
view structure
view signals
add wave -r sim:/$module/*

run -all