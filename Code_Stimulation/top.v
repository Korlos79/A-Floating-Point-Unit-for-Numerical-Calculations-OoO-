`timescale 1 ns / 1 ps

module top (
    input wire CLOCK_50,    // Xung nhịp hệ thống
    input wire [0:0] KEY   // Reset tích cực mức thấp (Active-low reset)
);

    // =======================================================
    // Instantiation of the Qsys System
    // =======================================================
    system u_system (
        .clk_clk       (CLOCK_50),   // Kết nối tới clk.clk của system
        .reset_reset_n (KEY[0])  // Kết nối tới reset.reset_n của system
    );

    // Lưu ý: Nếu sau này bạn quay lại Qsys (Platform Designer) 
    // và export thêm các tín hiệu ngoại vi (ví dụ GPIO, UART TX/RX, SPI...),
    // bạn sẽ cần khai báo thêm các port tương ứng ở module top này 
    // và nối dây vào u_system.

endmodule 