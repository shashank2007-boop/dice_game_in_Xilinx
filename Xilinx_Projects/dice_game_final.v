// =============================================================
//  DIGITAL DICE GAME — Complete Verilog Source (FIXED DISPLAY)
//  Board  : Digilent Nexys 4 (Artix-7 XC7A100T-1CSG324C)
//  Clock  : 100 MHz (pin E3)
//
//  7-Segment Display: COMMON ANODE
//    - Anodes  AN[7:0] : active LOW  (0 = digit ON)
//    - Cathodes seg[6:0]: active LOW  (0 = segment ON)
//
//  ✅ FIX APPLIED:
//     - Removed all ~enc(...)
//     - Encoding now ACTIVE LOW directly
// =============================================================


// =============================================================
// 1. CLOCK DIVIDER
// =============================================================
module clock_divider (
    input  wire clk_in,
    input  wire rst,
    output reg  clk_slow,
    output reg  clk_fast
);
    localparam SLOW_DIV = 50_000;
    localparam FAST_DIV = 5_000;

    reg [16:0] slow_cnt;
    reg [12:0] fast_cnt;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin slow_cnt <= 0; clk_slow <= 0; end
        else if (slow_cnt >= SLOW_DIV - 1) begin slow_cnt <= 0; clk_slow <= ~clk_slow; end
        else slow_cnt <= slow_cnt + 1;
    end

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin fast_cnt <= 0; clk_fast <= 0; end
        else if (fast_cnt >= FAST_DIV - 1) begin fast_cnt <= 0; clk_fast <= ~clk_fast; end
        else fast_cnt <= fast_cnt + 1;
    end
endmodule


// =============================================================
// 2. DEBOUNCER
// =============================================================
module debouncer (
    input  wire clk,
    input  wire rst,
    input  wire btn_raw,
    output reg  btn_clean
);
    reg [3:0] shift_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin shift_reg <= 4'b0000; btn_clean <= 1'b0; end
        else begin
            shift_reg <= {shift_reg[2:0], btn_raw};
            if      (shift_reg == 4'b1111) btn_clean <= 1'b1;
            else if (shift_reg == 4'b0000) btn_clean <= 1'b0;
        end
    end
endmodule


// =============================================================
// 3. DICE GENERATOR
// =============================================================
module dice_generator (
    input  wire       clk_fast,
    input  wire       rst,
    input  wire       roll_en,
    output reg  [2:0] dice_val
);
    always @(posedge clk_fast or posedge rst) begin
        if (rst) dice_val <= 3'd1;
        else if (roll_en) begin
            if (dice_val >= 3'd6) dice_val <= 3'd1;
            else                  dice_val <= dice_val + 3'd1;
        end
    end
endmodule


// =============================================================
// 4. SCORE REGISTERS
// =============================================================
module score_registers (
    input  wire       clk_slow,
    input  wire       rst,
    input  wire       score_wr_en,
    input  wire       current_player,
    input  wire [7:0] score_in,
    output reg  [7:0] score_p1,
    output reg  [7:0] score_p2
);
    always @(posedge clk_slow or posedge rst) begin
        if (rst) begin score_p1 <= 8'd0; score_p2 <= 8'd0; end
        else if (score_wr_en) begin
            if (current_player == 0) score_p1 <= score_in;
            else                     score_p2 <= score_in;
        end
    end
endmodule


// =============================================================
// 5. CONTROL UNIT (FSM)
// =============================================================
module control_unit (
    input  wire       clk_slow,
    input  wire       rst,
    input  wire       btn_p1,
    input  wire       btn_p2,
    input  wire [2:0] dice_val,
    input  wire [7:0] score_p1,
    input  wire [7:0] score_p2,
    output reg        roll_en,
    output reg        score_wr_en,
    output reg  [7:0] score_in,
    output reg        current_player,
    output reg        game_over,
    output reg        winner,
    output reg  [2:0] state_out
);

    localparam WIN_TARGET  = 8'd30;
    localparam IDLE=0,ROLLING=1,HOLD=2,UPDATE=3,CHECK=4,NEXT=5;

    reg [2:0] state,next;
    reg [2:0] locked;

    always @(posedge clk_slow or posedge rst) begin
        if (rst) begin state<=IDLE; current_player<=0; game_over<=0; end
        else begin
            state<=next;
            if(state==ROLLING && next==HOLD) locked<=dice_val;
            if(state==NEXT) current_player<=~current_player;
            if(state==CHECK) begin
                if(score_p1>=WIN_TARGET) begin game_over<=1; winner<=0; end
                else if(score_p2>=WIN_TARGET) begin game_over<=1; winner<=1; end
            end
        end
    end

    always @(*) begin
        next=state;
        case(state)
            IDLE: if(!game_over && ((current_player==0&&btn_p1)||(current_player==1&&btn_p2))) next=ROLLING;
            ROLLING: if((current_player==0&&!btn_p1)||(current_player==1&&!btn_p2)) next=HOLD;
            HOLD: next=UPDATE;
            UPDATE: next=CHECK;
            CHECK: next=(game_over)?IDLE:NEXT;
            NEXT: next=IDLE;
        endcase
    end

    always @(*) begin
        roll_en=(state==ROLLING);
        score_wr_en=(state==UPDATE);
        score_in=(current_player==0)?score_p1+locked:score_p2+locked;
        state_out=state;
    end
endmodule


// =============================================================
// 6. 7-SEGMENT DISPLAY DRIVER — FIXED
// =============================================================
module seg7_driver (
    input  wire       clk_slow,
    input  wire       rst,
    input  wire [2:0] dice_val,
    input  wire [7:0] score_p1,
    input  wire [7:0] score_p2,
    input  wire       current_player,
    input  wire       game_over,
    input  wire       winner,
    output reg  [6:0] seg,
    output reg  [7:0] an
);

    // ACTIVE LOW ENCODING
    function [6:0] enc;
        input [3:0] d;
        case(d)
            0: enc=7'b1000000;
            1: enc=7'b1111001;
            2: enc=7'b0100100;
            3: enc=7'b0110000;
            4: enc=7'b0011001;
            5: enc=7'b0010010;
            6: enc=7'b0000010;
            7: enc=7'b1111000;
            8: enc=7'b0000000;
            9: enc=7'b0010000;
            default: enc=7'b1111111;
        endcase
    endfunction

    reg [2:0] mux_cnt;

    always @(posedge clk_slow or posedge rst)
        if (rst) mux_cnt<=0;
        else mux_cnt<=mux_cnt+1;

    wire [7:0] score=(current_player==0)?score_p1:score_p2;
    wire [3:0] t=score/10;
    wire [3:0] u=score%10;

    always @(*) begin
        an=8'hFF;
        seg=7'h7F;

        case(mux_cnt)
            3'd3: begin an=8'b11110111; seg=enc(current_player+1); end
            3'd2: begin an=8'b11111011; seg=enc(dice_val); end
            3'd1: begin an=8'b11111101; seg=(t==0)?7'h7F:enc(t); end
            3'd0: begin an=8'b11111110; seg=enc(u); end
        endcase
    end
endmodule

// =============================================================
// 7. TOP-LEVEL MODULE
//    All pin assignments verified from Nexys 4 Reference Manual
// =============================================================
module dice_game_top (
    input  wire       clk,          // 100 MHz — pin E3
    input  wire       rst,          // BTNC    — pin E16
    input  wire       btn_p1_raw,   // BTNL    — pin T16
    input  wire       btn_p2_raw,   // BTNR    — pin R10

    output wire [6:0] seg,          // Cathodes CA–CG (active low)
    output wire [7:0] an,           // Anodes AN7–AN0 (active low)
    output wire       led_p1,       // LD0 — P1 turn
    output wire       led_p2,       // LD1 — P2 turn
    output wire       led_win       // LD2 — winner
);

    wire clk_slow, clk_fast;
    wire btn_p1, btn_p2;
    wire roll_en, score_wr_en;
    wire [7:0] score_in;
    wire current_player, game_over, winner;
    wire [2:0] state_out, dice_val;
    wire [7:0] score_p1, score_p2;

    clock_divider  u_clk  (.clk_in(clk), .rst(rst), .clk_slow(clk_slow), .clk_fast(clk_fast));
    debouncer      u_db1  (.clk(clk_slow), .rst(rst), .btn_raw(btn_p1_raw), .btn_clean(btn_p1));
    debouncer      u_db2  (.clk(clk_slow), .rst(rst), .btn_raw(btn_p2_raw), .btn_clean(btn_p2));
    dice_generator u_dice (.clk_fast(clk_fast), .rst(rst), .roll_en(roll_en), .dice_val(dice_val));
    score_registers u_sc  (.clk_slow(clk_slow), .rst(rst), .score_wr_en(score_wr_en),
                            .current_player(current_player), .score_in(score_in),
                            .score_p1(score_p1), .score_p2(score_p2));
    control_unit   u_fsm  (.clk_slow(clk_slow), .rst(rst), .btn_p1(btn_p1), .btn_p2(btn_p2),
                            .dice_val(dice_val), .score_p1(score_p1), .score_p2(score_p2),
                            .roll_en(roll_en), .score_wr_en(score_wr_en), .score_in(score_in),
                            .current_player(current_player), .game_over(game_over),
                            .winner(winner), .state_out(state_out));
    seg7_driver    u_seg  (.clk_slow(clk_slow), .rst(rst), .dice_val(dice_val),
                            .score_p1(score_p1), .score_p2(score_p2),
                            .current_player(current_player), .game_over(game_over),
                            .winner(winner), .seg(seg), .an(an));

    assign led_p1 = (~current_player) & (~game_over);
    assign led_p2 = ( current_player) & (~game_over);
    assign led_win = game_over;

endmodule

// =============================================================
// 8. TESTBENCH (simulation only — do NOT set as top in Vivado)
// =============================================================
module tb_dice_game;
    reg  clk, rst, btn_p1_raw, btn_p2_raw;
    wire [6:0] seg;
    wire [7:0] an;
    wire led_p1, led_p2, led_win;

    dice_game_top dut (
        .clk(clk), .rst(rst),
        .btn_p1_raw(btn_p1_raw),
        .btn_p2_raw(btn_p2_raw),
        .seg(seg), .an(an),
        .led_p1(led_p1),
        .led_p2(led_p2),
        .led_win(led_win)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    task press_button;
        input player;
        input [15:0] hold_cycles;
        begin
            if (player == 0) btn_p1_raw = 1;
            else btn_p2_raw = 1;

            repeat(hold_cycles) @(posedge dut.clk_slow);

            if (player == 0) btn_p1_raw = 0;
            else btn_p2_raw = 0;

            repeat(20) @(posedge dut.clk_slow);
        end
    endtask

    initial begin
        rst = 1;
        btn_p1_raw = 0;
        btn_p2_raw = 0;

        repeat(10) @(posedge clk);
        rst = 0;

        repeat(20) @(posedge dut.clk_slow);

        press_button(0,5);
        $display("P1 Score = %0d", dut.score_p1);

        press_button(1,7);
        $display("P2 Score = %0d", dut.score_p2);

        $finish;
    end
endmodule