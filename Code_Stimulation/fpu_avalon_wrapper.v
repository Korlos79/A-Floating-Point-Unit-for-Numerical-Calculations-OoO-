`timescale 1ns / 1ps

module fpu_avalon_wrapper (
    input  wire        clk,
    input  wire        reset_n,

    // Avalon-MM Slave Interface
    input  wire [2:0]  avs_address,
    input  wire        avs_write,
    input  wire [31:0] avs_writedata,
    input  wire        avs_read,
    output reg  [31:0] avs_readdata,
    output wire        avs_waitrequest
);

    // ---------------------------------------------------------------
    // Internal Registers — A / B / Opcode / valid pulse
    // ---------------------------------------------------------------
    reg [31:0] reg_a;
    reg [31:0] reg_b;
    reg [2:0]  reg_opcode;
    reg        fpu_valid_in;

    // ---------------------------------------------------------------
    // FPU wires
    // ---------------------------------------------------------------
    wire [31:0] fpu_result;
    wire        fpu_valid_out;
    wire        fpu_full;

    assign avs_waitrequest = fpu_full;

    // ---------------------------------------------------------------
    // FIX BUG 3 — Output FIFO (4 entries) để lưu từng result riêng
    // ---------------------------------------------------------------
    reg [31:0] result_fifo [0:3];
    reg [1:0]  wr_ptr;          // write pointer (vòng)
    reg [1:0]  rd_ptr;          // read  pointer (vòng)
    reg [2:0]  fifo_count;      // số phần tử hiện có (0..4)

    wire status_done = (fifo_count > 0);

    // ---------------------------------------------------------------
    // Instantiate FPU Top
    // ---------------------------------------------------------------
    fpu_top u_fpu (
        .clk        (clk),
        .rst_n      (reset_n),
        .valid_in   (fpu_valid_in),
        .opcode     (reg_opcode),
        .a          (reg_a),
        .b          (reg_b),
        .result_out (fpu_result),
        .valid_out  (fpu_valid_out),
        .rob_full   (fpu_full)
    );

    // ---------------------------------------------------------------
    // Control Path — Write registers + FIFO management
    // ---------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reg_a        <= 32'b0;
            reg_b        <= 32'b0;
            reg_opcode   <= 3'b0;
            fpu_valid_in <= 1'b0;
            wr_ptr       <= 2'b0;
            rd_ptr       <= 2'b0;
            fifo_count   <= 3'b0;
        end else begin

            fpu_valid_in <= 1'b0;

            if (fpu_valid_out) begin
                result_fifo[wr_ptr] <= fpu_result;
                wr_ptr              <= wr_ptr + 1;
                fifo_count          <= fifo_count + 1;
            end

            if (avs_read && (avs_address == 3'h3) && (fifo_count > 0)) begin
                rd_ptr     <= rd_ptr + 1;
                fifo_count <= fifo_count - 1;
            end
            // --- Ghi thanh ghi điều khiển từ Avalon bus ---
            if (avs_write && !avs_waitrequest) begin
                case (avs_address)
                    3'h0: reg_a <= avs_writedata;
                    3'h1: reg_b <= avs_writedata;
                    3'h2: begin
                        reg_opcode   <= avs_writedata[2:0];
                        fpu_valid_in <= 1'b1; // kích lệnh mới vào FPU
                    end
                    default: ; // địa chỉ khác — bỏ qua
                endcase
            end

        end
    end

    always @(*) begin
        case (avs_address)
            3'h0:    avs_readdata = reg_a;
            3'h1:    avs_readdata = reg_b;
            3'h2:    avs_readdata = {29'b0, reg_opcode};
            // Trả về head của FIFO — dữ liệu hợp lệ khi status_done=1
            3'h3:    avs_readdata = result_fifo[rd_ptr];
            // status_done là wire tổ hợp từ fifo_count → không bao giờ trễ
            3'h4:    avs_readdata = {31'b0, status_done};
            default: avs_readdata = 32'hDEADBEEF;
        endcase
    end

endmodule