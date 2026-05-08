`timescale 1ns/1ps

module test_bench;
    reg clk;
    reg op_sub;
    reg [31:0] a, b;
    wire [31:0] out;

    // Kết nối với module TOP (Hiện tại là 4-stage pipeline)
    top dut (
        .clk(clk),
        .op_sub(op_sub),
        .a(a),
        .b(b),
        .out(out)
    );

    // Tạo xung nhịp 5.5ns (~181MHz) để test đúng thực tế ông anh muốn
    initial begin
        clk = 0;
        forever #2.75 clk = ~clk; 
    end

    // Task thực hiện test case
    task run_test(
        input integer id, 
        input [31:0] in_a, 
        input [31:0] in_b, 
        input sub, 
        input [31:0] expected
    );
        begin
            a = in_a;
            b = in_b;
            op_sub = sub;
            
            // QUAN TRỌNG: Đợi đúng 4 chu kỳ cho thiết kế 4-stage pipeline
            repeat(4) @(posedge clk); 
            
            #1; // Đợi tín hiệu ổn định sau cạnh clock
            if (out === expected)
                $display("TEST %0d PASS | Result: %h", id, out);
            else
                $display("TEST %0d FAIL | Result: %h (Expected: %h)", id, out, expected);
        end
    endtask

    initial begin
        $display("--- Bat dau kiem tra FPU 4-Stage (LZC Tree Optimization) ---");
        
        // Reset ban dau
        a = 0; b = 0; op_sub = 0;
        @(posedge clk);

        // TEST 2: 2.5 + 1.0 = 3.5
        run_test(2, 32'h40200000, 32'h3f800000, 0, 32'h40600000);

        // TEST 3: -1235.1 + 1.1 = -1234.0
        run_test(3, 32'hc49a6333, 32'h3f8ccccd, 0, 32'hc49a4000);

        // TEST 4: Pi + 10^-8 (FAR path)
        run_test(4, 32'h40490fdb, 32'h332b1662, 0, 32'h40490fdb);

        // TEST 5: 2.5 - 1.0 = 1.5 (3fc00000)
        run_test(5, 32'h40200000, 32'h3f800000, 1, 32'h3fc00000);

        // TEST 6: -1235.1 - (-1.1) = -1234.0
        run_test(6, 32'hc49a6333, 32'hbf8ccccd, 1, 32'hc49a4000);

        // TEST 7: Pi - 10^-8
        run_test(7, 32'h40490fdb, 32'h332b1662, 1, 32'h40490fdb);

        $display("--- Hoan thanh tat ca cac test case ---");
        $finish;
    end
endmodule