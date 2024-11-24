/*
============================================================================

Date   : 2023/03/10
Author : EECS Lab

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Debuggging mode  : Screen Display
Generate concept :
    Generate the valid solution path firstly.
============================================================================
*/

`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif


module PATTERN(
    // Output Signals
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    
    // Input Signals
    out_valid,
    out
);

//======================================
//          I/O PORTS
//======================================
output reg             clk;
output reg           rst_n;
output reg        in_valid;
output reg [1:0]      init;
output reg [1:0]       in0;
output reg [1:0]       in1;
output reg [1:0]       in2;
output reg [1:0]       in3;

input            out_valid;
input      [1:0]       out;

//=====================================
//       PARAMTERS & VARIABLES
//=====================================
parameter PATNUM         = 10;
parameter CYCLE          = `CYCLE_TIME;
parameter DELAY          = 3000;
parameter OUT_NUM        = 63;
// =================================
parameter OBSTACLE_NUMER = 1;
parameter OBSTACLE_DENOM = 2;
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
parameter LOG_NUM        = 100;
integer   SEED           = 911409657;

// PATTERN CONTROL
integer       i;
integer       j;
integer       m;
integer       n;
integer       k;
integer     pat;
integer exe_lat;
integer out_lat;
integer tot_lat;

// String control
// Should use %0s
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

reg[10*8:1] bkg_black_prefix  = "\033[40;1m";
reg[10*8:1] bkg_red_prefix    = "\033[41;1m";
reg[10*8:1] bkg_green_prefix  = "\033[42;1m";
reg[10*8:1] bkg_yellow_prefix = "\033[43;1m";
reg[10*8:1] bkg_blue_prefix   = "\033[44;1m";
reg[10*8:1] bkg_white_prefix  = "\033[47;1m";

//pragma protect
//pragma protect begin

//======================================
//      DATA MODEL
//======================================
//-----------------
// Data parameter
//-----------------
parameter NUM_TRACK = 4;
parameter NUM_CYCLE = 64;
parameter MAGIC_NUM = 8;
// Map parameter
parameter ROAD       = 0;
parameter LOW_OB     = 1;
parameter HIGH_OB    = 2;
parameter TRAIN      = 3;
parameter TRAIN_MOD  = 4;
// Move parameter
parameter FORWARD   = 0;
parameter RIGHT     = 1;
parameter LEFT      = 2;
parameter JUMP      = 3;

//------
// Map 
//------
integer start_pos;
integer map[NUM_TRACK-1:0][NUM_CYCLE-1:0];
integer valid_path[NUM_CYCLE-1:0]; // Generate at least on valid path
integer your_path [NUM_CYCLE-1:0];
integer your_act  [NUM_CYCLE-1:0];
integer map_i, map_j, map_k;

// reset the map
task reset_map; begin
    // reset map
    for(map_i=0 ; map_i<NUM_TRACK ; map_i=map_i+1)
        for(map_j=0 ; map_j<NUM_CYCLE ; map_j=map_j+1)
            map[map_i][map_j] = 0;
    // reset valid path
    for(map_j=0 ; map_j<NUM_CYCLE ; map_j=map_j+1) valid_path[map_j] = 0;
end endtask

// show original map
task show_map; begin
    $display("[Info] This is the original map");
    $display("[Info] Initial pos            : %-2b", start_pos);
    $display("[Info] Probabilty of obstacle : %-5d/%-5d", OBSTACLE_NUMER, OBSTACLE_DENOM);
    $write("%0s   ", reset_color);
    for(map_j=0 ; map_j<NUM_CYCLE ; map_j=map_j+1) $write("%0s%-2d %0s", txt_yellow_prefix, map_j, reset_color);
    $write("\n");
    for(map_i=0 ; map_i<NUM_TRACK ; map_i=map_i+1) begin
        $write("%0s%-2d %0s", txt_yellow_prefix, map_i, reset_color);
        for(map_j=0 ; map_j<NUM_CYCLE ; map_j=map_j+1) begin
            case(map[map_i][map_j])
                ROAD   : $write("%0s%-2b ", txt_black_prefix, map[map_i][map_j]);
                LOW_OB : $write("%0s%-2b ", txt_blue_prefix,  map[map_i][map_j]);
                HIGH_OB: $write("%0s%-2b ", txt_green_prefix, map[map_i][map_j]);
                TRAIN  : $write("%0s%-2b ", txt_red_prefix,   map[map_i][map_j]);
                default : $write("[Error] Invalid value, please check map : %-2b", map[map_i][map_j]);
            endcase
            $write("%0s", reset_color);
        end
        $write("\n");
    end
    $write("\n");
end endtask

// Show the map with your path
task show_map_with_your_path;
    input integer move_num;
begin
    $display("\n[Info] This is the original map with your path");
    $write("%0s   ", reset_color);
    for(map_j=0 ; map_j<NUM_CYCLE ; map_j=map_j+1) $write("%0s%-2d %0s", txt_yellow_prefix, map_j, reset_color);
    $write("\n");
    for(map_i=0 ; map_i<NUM_TRACK ; map_i=map_i+1) begin
        $write("%0s%-2d %0s", txt_yellow_prefix, map_i, reset_color);
        for(map_j=0 ; map_j<NUM_CYCLE ; map_j=map_j+1) begin
            if(map_j < move_num && your_path[map_j] == map_i) begin
                case(map[map_i][map_j])
                    ROAD   : $write("%0s%0s%-2b ", bkg_white_prefix, txt_black_prefix, map[map_i][map_j]);
                    LOW_OB : $write("%0s%-2b ", bkg_blue_prefix, map[map_i][map_j]);
                    HIGH_OB: $write("%0s%-2b ", bkg_green_prefix, map[map_i][map_j]);
                    TRAIN  : $write("%0s%-2b ", bkg_red_prefix,   map[map_i][map_j]);
                    default: $write("[Error] Invalid value, please check map : %-2b", map[map_i][map_j]);
                endcase
            end
            else begin
                case(map[map_i][map_j])
                     ROAD   : $write("%0s%-2b ", txt_black_prefix, map[map_i][map_j]);
                     LOW_OB : $write("%0s%-2b ", txt_blue_prefix,  map[map_i][map_j]);
                     HIGH_OB: $write("%0s%-2b ", txt_green_prefix, map[map_i][map_j]);
                     TRAIN  : $write("%0s%-2b ", txt_red_prefix,   map[map_i][map_j]);
                    default : $write("[Error] Invalid value, please check map : %-2b", map[map_i][map_j]);
                endcase
            end
            $write("%0s", reset_color);
        end
        $write("\n");
    end
    $write("%0s   XX ", reset_color);
    for(map_j=1 ; map_j<NUM_CYCLE ; map_j=map_j+1) begin
        // $write("%-2d ", your_act[map_j]);
        if(your_act[map_j] == FORWARD)    $write("-  ");
        else if(your_act[map_j] == RIGHT) $write("V  ");
        else if(your_act[map_j] == LEFT)  $write("^  ");
        else if(your_act[map_j] == JUMP)  $write("*  ");
    end
    $write("\n");
    $write("%0s   XX ", reset_color);
    for(map_j=1 ; map_j<NUM_CYCLE ; map_j=map_j+1) begin
        $write("%-2d ", your_act[map_j]);
    end
    $write("\n");
end endtask

// Show the map with the valid path set initially
task show_map_with_valid_path; begin
    $display("[Info] This is the original map with one valid path");
    $write("%0s   ", reset_color);
    for(map_j=0 ; map_j<NUM_CYCLE ; map_j=map_j+1) $write("%0s%-2d %0s", txt_yellow_prefix, map_j, reset_color);
    $write("\n");
    for(map_i=0 ; map_i<NUM_TRACK ; map_i=map_i+1) begin
        $write("%0s%-2d %0s", txt_yellow_prefix, map_i, reset_color);
        for(map_j=0 ; map_j<NUM_CYCLE ; map_j=map_j+1) begin
            if(valid_path[map_j] == map_i) begin
                case(map[map_i][map_j])
                    ROAD   : $write("%0s%0s%-2b ", bkg_white_prefix, txt_black_prefix, map[map_i][map_j]);
                    LOW_OB : $write("%0s%-2b ", bkg_blue_prefix, map[map_i][map_j]);
                    HIGH_OB: $write("%0s%-2b ", bkg_green_prefix, map[map_i][map_j]);
                    default: $write("[Error] Invalid value, please check map : %-2b", map[map_i][map_j]);
                endcase
            end
            else begin
                case(map[map_i][map_j])
                     ROAD   : $write("%0s%-2b ", txt_black_prefix, map[map_i][map_j]);
                     LOW_OB : $write("%0s%-2b ", txt_blue_prefix,  map[map_i][map_j]);
                     HIGH_OB: $write("%0s%-2b ", txt_green_prefix, map[map_i][map_j]);
                     TRAIN  : $write("%0s%-2b ", txt_red_prefix,   map[map_i][map_j]);
                    default : $write("[Error] Invalid value, please check map : %-2b", map[map_i][map_j]);
                endcase
            end
            $write("%0s", reset_color);
        end
        $write("\n");
    end
    $write("\n");
end endtask

// generate the first valid path
integer next_pos;
task gen_valid_path; begin
    // Random init
    start_pos = {$random(SEED)} % NUM_TRACK;
    valid_path[0] = start_pos;
    // $display("[Info] Start Point : %d", start_pos);
    
    // Path
    for(map_j=1 ; map_j<NUM_CYCLE ; map_j=map_j+1) begin
        if(map_j%MAGIC_NUM < TRAIN_MOD) begin
            next_pos = valid_path[map_j-1];
        end
        else begin
            case(valid_path[map_j-1])
                0: next_pos = 1;
                1: next_pos = {$random(SEED)} % 2 ? 0 : 2;
                2: next_pos = {$random(SEED)} % 2 ? 1 : 3;
                3: next_pos = 2;
                default : $display("[Error] The valid paht shouldn't be %-2d at iter %-2d", valid_path[map_j-1], map_j);
            endcase
        end
        valid_path[map_j] = next_pos;
    end

    // Initialize the answer path
    your_path[0] = start_pos;
end endtask

// generate the map
reg[3:0] num_train;
task gen_map; begin
    // Train
    // Min : 1, Max : 16
    // Use four bit represent the train location [1,1,1,1]
    // 0000 -> no train not valid, 1111 -> four train not valid
    for(map_j=0 ; map_j<NUM_CYCLE ; map_j=map_j+8) begin
        if(map_j%MAGIC_NUM < TRAIN_MOD) begin
            num_train = {$random(SEED)} % 16 + 1;
            while(num_train == 4'd1 || num_train == 4'd2 || num_train == 4'd4 || num_train == 4'd8) begin
                num_train = {$random(SEED)} % 16 + 1; // 1~15
            end
            // $display("%[Info] -2d Num train : %-4b", map_j, num_train);
            for(map_k=0 ; map_k<TRAIN_MOD ; map_k=map_k+1) begin
                if(map_k != valid_path[map_j] && num_train[map_k]==1'b1) begin
                    map[map_k][map_j  ] = TRAIN;
                    map[map_k][map_j+1] = TRAIN;
                    map[map_k][map_j+2] = TRAIN;
                    map[map_k][map_j+3] = TRAIN;
                end
            end
        end
    end

    // Obstacle
    for(map_i=0 ; map_i<NUM_TRACK ; map_i=map_i+1) begin
        for(map_j=0 ; map_j<NUM_CYCLE ; map_j=map_j+2) begin
            if(map[map_i][map_j] != 3 && map_j%MAGIC_NUM != 0) begin
                // $display("[Info] Iter : %-2d, %-2d", map_i, map_j);
                // Probability : OBSTACLE_NUMER / OBSTACLE_DENOM
                if(({$random(SEED)} % OBSTACLE_DENOM) < OBSTACLE_NUMER) begin
                        if({$random(SEED)} % 2) map[map_i][map_j] = HIGH_OB;
                        else                    map[map_i][map_j] = LOW_OB;
                end
            end
        end
    end
end endtask

/*
    0. : out of map
    1. : hit the low obstacle
    2. : hit the high obstacle
    3. : hit the train
*/
integer pre_pos;
integer err_type;
task check_move;
    input integer move_num;
    input integer move_type;
begin
    pre_pos = your_path[move_num-1];
    err_type = -1;
    // $display("[Info] Pre pos             : %-2d", pre_pos);
    // $display("[Info] Current num of move : %-2d", move_num);
    // if(move_type == 0) $display("[Info] Current type        : FORWARD");
    // else if(move_type == 1) $display("[Info] Current type        : RIGHT");
    // else if(move_type == 2) $display("[Info] Current type        : LEFT");
    // else if(move_type == 3) $display("[Info] Current type        : JUMP");
    case(move_type)
        FORWARD:begin
            if(map[pre_pos][move_num] == LOW_OB)     err_type = 1;
            else if(map[pre_pos][move_num] == TRAIN) err_type = 3;
            else begin
                your_path[move_num] = pre_pos;
                your_act[move_num] = move_type;
            end
        end
        RIGHT  :begin
            if(pre_pos == 3) err_type = 0;
            else begin
                if(map[pre_pos+1][move_num] == LOW_OB)       err_type = 1;
                else if(map[pre_pos+1][move_num] == HIGH_OB) err_type = 2;
                else if(map[pre_pos+1][move_num] == TRAIN)   err_type = 3;
                else begin
                    your_path[move_num] = pre_pos+1;
                    your_act[move_num] = move_type;
                end
            end
        end
        LEFT   :begin
            if(pre_pos == 0) err_type = 0;
            else begin
                if(map[pre_pos-1][move_num] == LOW_OB)       err_type = 1;
                else if(map[pre_pos-1][move_num] == HIGH_OB) err_type = 2;
                else if(map[pre_pos-1][move_num] == TRAIN)   err_type = 3;
                else begin
                    your_path[move_num] = pre_pos-1;
                    your_act[move_num] = move_type;
                end
            end
        end
        JUMP   :begin
            if(map[pre_pos][move_num] == HIGH_OB)    err_type = 2;
            else if(map[pre_pos][move_num] == TRAIN) err_type = 3;
            else begin
                your_path[move_num] = pre_pos;
                your_act[move_num] = move_type;
            end
        end
        default : $display("[Error] The valid paht shouldn't be %-2d at move %-2d", your_path[move_num-1], move_num);
    endcase
    if(err_type == 0) begin
        $display("=======================================");
        $display("=        (winnie the pooh.jpg)         ");
        $display("=     Hit the boundary of the map      ");
        $display("=        at at %-12d ps                ", $time*1000);
        $display("=======================================");
        $display("Current num of move : %-2d", move_num);
        if(move_type == 0) $display("Current type        : FORWARD");
        else if(move_type == 1) $display("Current type        : RIGHT");
        else if(move_type == 2) $display("Current type        : LEFT");
        else if(move_type == 3) $display("Current type        : JUMP");
        show_map_with_your_path(move_num);
        $finish;
    end
    else if(err_type == 1) begin
        $display("=======================================");
        $display("=        (winnie the pooh.jpg)         ");
        $display("=        Hit the low obstacle          ");
        $display("=        at at %-12d ps                ", $time*1000);
        $display("=======================================");
        $display("Current num of move : %-2d", move_num);
        if(move_type == 0) $display("Current type        : FORWARD");
        else if(move_type == 1) $display("Current type        : RIGHT");
        else if(move_type == 2) $display("Current type        : LEFT");
        else if(move_type == 3) $display("Current type        : JUMP");
        show_map_with_your_path(move_num);
        $finish;
    end
    else if(err_type == 2) begin
        $display("=======================================");
        $display("=        (winnie the pooh.jpg)         ");
        $display("=        Hit the high obstacle         ");
        $display("=        at at %-12d ps                ", $time*1000);
        $display("=======================================");
        $display("Current num of move : %-2d", move_num);
        if(move_type == 0) $display("Current type        : FORWARD");
        else if(move_type == 1) $display("Current type        : RIGHT");
        else if(move_type == 2) $display("Current type        : LEFT");
        else if(move_type == 3) $display("Current type        : JUMP");
        show_map_with_your_path(move_num);
        $finish;
    end
    else if(err_type == 3) begin
        $display("=======================================");
        $display("=        (winnie the pooh.jpg)         ");
        $display("=        Hit the train                 ");
        $display("=        at at %-12d ps                ", $time*1000);
        $display("=======================================");
        $display("Current num of move : %-2d", move_num);
        if(move_type == 0) $display("Current type        : FORWARD");
        else if(move_type == 1) $display("Current type        : RIGHT");
        else if(move_type == 2) $display("Current type        : LEFT");
        else if(move_type == 3) $display("Current type        : JUMP");
        show_map_with_your_path(move_num);
        $finish;
    end
end endtask

//pragma protect end

//======================================
//              Clock
//======================================
initial clk = 1'b0;
always #(CYCLE/2.0) clk = ~clk;

//======================================
//              MAIN
//======================================
initial exe_task;

//======================================
//              TASKS
//======================================
task exe_task; begin
    reset_task;
    for (pat=0 ; pat<PATNUM ; pat=pat+1) begin
        input_task;
        wait_task;
        check_task;
    
        // Print Pass Info and accumulate the total latency
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", pat ,exe_lat);
        tot_lat = tot_lat + exe_lat;
    end
    pass_task;
end endtask

task reset_task; begin
    
    tot_lat = 0;
    
    force clk  = 0;
    rst_n      = 1;
    in_valid   = 0;
    init       = 'dx;
    in0        = 'dx;
    in1        = 'dx;
    in2        = 'dx;
    in3        = 'dx;
    
    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if(out_valid !== 0 || out !== 0) begin
        $display("                                           `:::::`                                                       ");
        $display("                                          .+-----++                                                      ");
        $display("                .--.`                    o:------/o                                                      ");
        $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
        $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
        $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
        $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
        $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
        $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
        $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
        $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
        $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
        $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
        $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
        $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
        $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
        $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
        $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
        $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
        $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
        $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
        $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
        $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
        $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
        $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
        $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
        $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
        $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     after the reset signal is asserted");
        $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
        $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
        $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
        $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
        $display("                       `s--------------------------::::::::-----:o                                       ");
        $display("                       +:----------------------------------------y`                                      ");
        repeat(5) #(CYCLE);
        $finish;
    end
    #(CYCLE/2.0) release clk;
end endtask

task input_task; begin
    repeat( ({$random(SEED)} % 4 + 2) ) @(negedge clk);
    reset_map;
    gen_valid_path;
    gen_map;
    // show_map_with_valid_path;

    for(j=0 ; j<NUM_CYCLE ; j=j+1) begin
        if(j==0) init = start_pos;
        else     init = 'dx;
        in_valid = 1;
        in0      = map[0][j];
        in1      = map[1][j];
        in2      = map[2][j];
        in3      = map[3][j];
        @(negedge clk);
    end
    in_valid = 0;
    in0      = 'dx;
    in1      = 'dx;
    in2      = 'dx;
    in3      = 'dx;
end endtask

task wait_task; begin
    exe_lat = -1;
    while(out_valid!==1) begin
        if(out !== 0) begin
            $display("                                           `:::::`                                                       ");
            $display("                                          .+-----++                                                      ");
            $display("                .--.`                    o:------/o                                                      ");
            $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
            $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
            $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
            $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
            $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
            $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
            $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
            $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
            $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
            $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
            $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
            $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
            $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
            $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
            $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
            $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
            $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
            $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
            $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
            $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
            $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
            $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
            $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
            $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
            $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     when the out_valid is pulled down ");
            $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
            $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
            $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
            $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
            $display("                       `s--------------------------::::::::-----:o                                       ");
            $display("                       +:----------------------------------------y`                                      ");
            repeat(5) @(negedge clk);
            $finish;
        end
        if (exe_lat == DELAY) begin
            $display("                                   ..--.                                ");
            $display("                                `:/:-:::/-                              ");
            $display("                                `/:-------o                             ");
            $display("                                /-------:o:                             ");
            $display("                                +-:////+s/::--..                        ");
            $display("    The execution latency      .o+/:::::----::::/:-.       at %-12d ps  ", $time*1000);
            $display("    is over %6d  cycles    `:::--:/++:----------::/:.                ", DELAY);
            $display("                            -+:--:++////-------------::/-               ");
            $display("                            .+---------------------------:/--::::::.`   ");
            $display("                          `.+-----------------------------:o/------::.  ");
            $display("                       .-::-----------------------------:--:o:-------:  ");
            $display("                     -:::--------:/yy------------------/y/--/o------/-  ");
            $display("                    /:-----------:+y+:://:--------------+y--:o//:://-   ");
            $display("                   //--------------:-:+ssoo+/------------s--/. ````     ");
            $display("                   o---------:/:------dNNNmds+:----------/-//           ");
            $display("                   s--------/o+:------yNNNNNd/+--+y:------/+            ");
            $display("                 .-y---------o:-------:+sso+/-:-:yy:------o`            ");
            $display("              `:oosh/--------++-----------------:--:------/.            ");
            $display("              +ssssyy--------:y:---------------------------/            ");
            $display("              +ssssyd/--------/s/-------------++-----------/`           ");
            $display("              `/yyssyso/:------:+o/::----:::/+//:----------+`           ");
            $display("             ./osyyyysssso/------:/++o+++///:-------------/:            ");
            $display("           -osssssssssssssso/---------------------------:/.             ");
            $display("         `/sssshyssssssssssss+:---------------------:/+ss               ");
            $display("        ./ssssyysssssssssssssso:--------------:::/+syyys+               ");
            $display("     `-+sssssyssssssssssssssssso-----::/++ooooossyyssyy:                ");
            $display("     -syssssyssssssssssssssssssso::+ossssssssssssyyyyyss+`              ");
            $display("     .hsyssyssssssssssssssssssssyssssssssssyhhhdhhsssyssso`             ");
            $display("     +/yyshsssssssssssssssssssysssssssssyhhyyyyssssshysssso             ");
            $display("    ./-:+hsssssssssssssssssssssyyyyyssssssssssssssssshsssss:`           ");
            $display("    /---:hsyysyssssssssssssssssssssssssssssssssssssssshssssy+           ");
            $display("    o----oyy:-:/+oyysssssssssssssssssssssssssssssssssshssssy+-          ");
            $display("    s-----++-------/+sysssssssssssssssssssssssssssssyssssyo:-:-         ");
            $display("    o/----s-----------:+syyssssssssssssssssssssssyso:--os:----/.        ");
            $display("    `o/--:o---------------:+ossyysssssssssssyyso+:------o:-----:        ");
            $display("      /+:/+---------------------:/++ooooo++/:------------s:---::        ");
            $display("       `/o+----------------------------------------------:o---+`        ");
            $display("         `+-----------------------------------------------o::+.         ");
            $display("          +-----------------------------------------------/o/`          ");
            $display("          ::----------------------------------------------:-            ");
            repeat(5) @(negedge clk);
            $finish; 
        end
        exe_lat = exe_lat + 1;
        @(negedge clk);
    end
end endtask

//pragma protect
//pragma protect begin

task check_task; begin
    out_lat = 0;
    // show_map;
    while (out_valid === 1) begin
        if (out_lat == OUT_NUM) begin
            $display("                                                                                ");
            $display("                                                   ./+oo+/.                     ");
            $display("    Out cycles is more than %-3d                  /s:-----+s`     at %-12d ps   ", OUT_NUM, $time*1000);
            $display("                                                  y/-------:y                   ");
            $display("                                             `.-:/od+/------y`                  ");
            $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
            $display("                              -m+:::::::---------------------::o+.              ");
            $display("                             `hod-------------------------------:o+             ");
            $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
            $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
            $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
            $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
            $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
            $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
            $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
            $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
            $display("                 s:----------------/s+///------------------------------o`       ");
            $display("           ``..../s------------------::--------------------------------o        ");
            $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
            $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
            $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
            $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
            $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
            $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
            $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
            $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
            $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
            $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
            $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
            $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
            $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
            $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
            $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
            $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
            $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
            $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
            $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
            $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
            $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
            $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
            $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   ");
        end

        check_move(out_lat+1, out);

        out_lat = out_lat + 1;
        @(negedge clk);
    end
    
    if (out_lat<OUT_NUM) begin
        $display("                                                                                ");
        $display("                                                   ./+oo+/.                     ");
        $display("    Out cycles is less than %-2d                  /s:-----+s`     at %-12d ps   ", OUT_NUM, $time*1000);
        $display("                                                  y/-------:y                   ");
        $display("                                             `.-:/od+/------y`                  ");
        $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
        $display("                              -m+:::::::---------------------::o+.              ");
        $display("                             `hod-------------------------------:o+             ");
        $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
        $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
        $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
        $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
        $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
        $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
        $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
        $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
        $display("                 s:----------------/s+///------------------------------o`       ");
        $display("           ``..../s------------------::--------------------------------o        ");
        $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
        $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
        $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
        $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
        $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
        $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
        $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
        $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
        $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
        $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
        $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
        $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
        $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
        $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
        $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
        $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
        $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
        $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
        $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
        $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
        $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
        $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
        $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
        repeat(5) @(negedge clk);
        show_map_with_your_path(out_lat+1);
        $finish;
    end

//pragma protect end

    if (out !== 0) begin
        $display("                                           `:::::`                                                       ");
        $display("                                          .+-----++                                                      ");
        $display("                .--.`                    o:------/o                                                      ");
        $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
        $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
        $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
        $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
        $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
        $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
        $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
        $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
        $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
        $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
        $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
        $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
        $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
        $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
        $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
        $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
        $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
        $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
        $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
        $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
        $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
        $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
        $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
        $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
        $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     when the out_valid is pulled down ");
        $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
        $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
        $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
        $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
        $display("                       `s--------------------------::::::::-----:o                                       ");
        $display("                       +:----------------------------------------y`                                      ");
        repeat(5) @(negedge clk);
        $finish;
    end
    show_map_with_your_path(64);
end endtask

task pass_task; begin
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Congratulation!!! \033[1;0m                                   ");
    $display("\033[1;33m               /h/----+y        `+++++:             \033[1;35m PASS This Lab........Maybe \033[1;0m                          ");
    $display("\033[1;33m             .y------:m/+ydoo+:y:---:+o             \033[1;35m Total Latency : %-10d\033[1;0m                                ", tot_lat);
    $display("\033[1;33m              o+------/y--::::::+oso+:/y                                                                                     ");
    $display("\033[1;33m              s/-----:/:----------:+ooy+-                                                                                    ");
    $display("\033[1;33m             /o----------------/yhyo/::/o+/:-.`                                                                              ");
    $display("\033[1;33m            `ys----------------:::--------:::+yyo+                                                                           ");
    $display("\033[1;33m            .d/:-------------------:--------/--/hos/                                                                         ");
    $display("\033[1;33m            y/-------------------::ds------:s:/-:sy-                                                                         ");
    $display("\033[1;33m           +y--------------------::os:-----:ssm/o+`                                                                          ");
    $display("\033[1;33m          `d:-----------------------:-----/+o++yNNmms                                                                        ");
    $display("\033[1;33m           /y-----------------------------------hMMMMN.                                                                      ");
    $display("\033[1;33m           o+---------------------://:----------:odmdy/+.                                                                    ");
    $display("\033[1;33m           o+---------------------::y:------------::+o-/h                                                                    ");
    $display("\033[1;33m           :y-----------------------+s:------------/h:-:d                                                                    ");
    $display("\033[1;33m           `m/-----------------------+y/---------:oy:--/y                                                                    ");
    $display("\033[1;33m            /h------------------------:os++/:::/+o/:--:h-                                                                    ");
    $display("\033[1;33m         `:+ym--------------------------://++++o/:---:h/                                                                     ");
    $display("\033[1;31m        `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
    $display("\033[1;31m         shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
    $display("\033[1;31m         .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
    $display("\033[1;31m        `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
    $display("\033[1;31m        -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
    $display("\033[1;31m         hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
    $display("\033[1;31m         `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
    $display("\033[1;31m          dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
    $display("\033[1;31m         :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
    $display("\033[1;31m        /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
    $display("\033[1;31m      +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
    $display("\033[1;31m      -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
    $display("\033[1;31m       `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
    $display("\033[1;31m         os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
    $display("\033[1;33m         h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
    $display("\033[1;33m         m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
    $display("\033[1;33m        `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
    $display("\033[1;33m        .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
    $display("\033[1;33m        +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
    $display("\033[1;33m        h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
    $display("\033[1;33m       `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
    $display("\033[1;33m    `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
    $display("\033[1;33m   -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
    $display("\033[1;33m   s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
    $display("\033[1;33m   o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
    $display("\033[1;33m    :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
    $display("\033[1;33m       .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
    $display("\033[1;33m                                          `:+omy/---------------------+h:----:y+//so                                         ");
    $display("\033[1;33m                                              `-ys:-------------------+s-----+s///om                                         ");
    $display("\033[1;33m                                                 -os+::---------------/y-----ho///om                                         ");
    $display("\033[1;33m                                                    -+oo//:-----------:h-----h+///+d                                         ");
    $display("\033[1;33m                                                       `-oyy+:---------s:----s/////y                                         ");
    $display("\033[1;33m                                                           `-/o+::-----:+----oo///+s                                         ");
    $display("\033[1;33m                                                               ./+o+::-------:y///s:                                         ");
    $display("\033[1;33m                                                                   ./+oo/-----oo/+h                                          ");
    $display("\033[1;33m                                                                       `://++++syo`                                          ");
    $display("\033[1;0m"); 
    repeat(5) @(negedge clk);
    $finish;
end endtask

endmodule
