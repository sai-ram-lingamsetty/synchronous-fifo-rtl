`timescale 1ns/1ps

module sync_fifo_tb();

    parameter DEPTH     = 16;
    parameter WIDTH     = 8;
    parameter THRESHOLD = 2;

    reg clk;
    reg rst_n;
    reg wr_en;
    reg rd_en;
    reg [WIDTH-1:0] wr_data;
    wire [WIDTH-1:0] rd_data;
    wire empty, full, almost_empty, almost_full;

    sync_fifo #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH),
        .THRESHOLD(THRESHOLD)
    ) dut (
                .clk(clk),
                .rst_n(rst_n),
                .wr_en(wr_en),
                .rd_en(rd_en),
                .wr_data(wr_data),
                .rd_data(rd_data),
                .empty(empty),
                .almost_empty(almost_empty),
                .full(full),
                .almost_full(almost_full)
          );

    always #5 clk = ~clk;
    
    reg [WIDTH-1:0] model_mem [0:DEPTH-1];
    integer model_wr_ptr;
    integer model_rd_ptr;
    integer model_count;
    integer error_count;

    reg [WIDTH-1:0] expected_data;
    reg check_valid;

    wire model_wr_allow = wr_en && (!full  || rd_en);
    wire model_rd_allow = rd_en && (!empty || wr_en);

    initial begin
        clk = 0;
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;

        model_wr_ptr = 0;
        model_rd_ptr = 0;
        model_count  = 0;
        error_count  = 0;
        check_valid  = 0;

        #20 rst_n = 1;

        run_test();

        #50;

        if (error_count == 0)
            $display("\n===== SIMULATION PASSED =====\n");
        else
            $display("\n===== SIMULATION FAILED : %0d ERRORS =====\n", error_count);

        $finish;
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            model_wr_ptr <= 0;
            model_rd_ptr <= 0;
            model_count  <= 0;
            check_valid  <= 0;
        end else begin

            if (check_valid) begin
                if (rd_data !== expected_data) begin
                    $display("DATA ERROR @ %0t : Expected=%0d Got=%0d",$time, expected_data, rd_data);
                    error_count = error_count + 1;
                end
            end

            check_valid <= 0;
            
            if (model_wr_allow) begin
                model_mem[model_wr_ptr] <= wr_data;
                model_wr_ptr <= (model_wr_ptr + 1) % DEPTH;
            end
            
            if (model_rd_allow) begin
                if (model_count == 0 && wr_en) begin
                    expected_data <= wr_data;   // bypass case
                end else begin
                    expected_data <= model_mem[model_rd_ptr];
                end
                check_valid <= 1;
                model_rd_ptr <= (model_rd_ptr + 1) % DEPTH;
            end
            
            case ({model_wr_allow, model_rd_allow})
                2'b10: model_count <= model_count + 1;
                2'b01: model_count <= model_count - 1;
                default: model_count <= model_count;
            endcase
        end
    end
    
    always @(posedge clk) begin
        if (rst_n) begin
            if (empty !== (model_count == 0)) begin
                $display("EMPTY FLAG ERROR @ %0t", $time);
                error_count = error_count + 1;
            end

            if (full !== (model_count == DEPTH)) begin
                $display("FULL FLAG ERROR @ %0t", $time);
                error_count = error_count + 1;
            end

            if (almost_empty !== ((model_count != 0) &&
                                  (model_count <= THRESHOLD))) begin
                $display("ALMOST_EMPTY FLAG ERROR @ %0t", $time);
                error_count = error_count + 1;
            end

            if (almost_full !== ((model_count < DEPTH) &&
                                 (model_count >= DEPTH-THRESHOLD))) begin
                $display("ALMOST_FULL FLAG ERROR @ %0t", $time);
                error_count = error_count + 1;
            end

            if (full && empty) begin
                $display("FLAG MUTEX ERROR @ %0t", $time);
                error_count = error_count + 1;
            end
        end
    end
    
    task run_test;
        integer i;
        begin
    
            // Write some
            for (i = 0; i < 5; i=i+1) begin
                @(posedge clk);
                wr_en = 1; rd_en = 0;
                wr_data = i;
            end
    
            // Read some
            for (i = 0; i < 3; i=i+1) begin
                @(posedge clk);
                wr_en = 0; rd_en = 1;
            end
    
            // Simultaneous read and write (mid-occupancy)
            for (i = 0; i < 5; i=i+1) begin
                @(posedge clk);
                wr_en = 1; rd_en = 1;
                wr_data = i + 20;
            end
    
            // Fill completely
            while (!full) begin
                @(posedge clk);
                wr_en = 1; rd_en = 0;
                wr_data = $random;
            end
    
            // Try illegal write at FULL
            @(posedge clk);
            wr_en = 1; rd_en = 0;
    
            // Drain completely
            while (!empty) begin
                @(posedge clk);
                wr_en = 0; rd_en = 1;
            end
    
            // Try illegal read at EMPTY
            @(posedge clk);
            wr_en = 0; rd_en = 1;
    
            // Simultaneous read/write at EMPTY (bypass case)
            repeat (5) begin
                @(posedge clk);
                wr_en = 1;
                rd_en = 1;
                wr_data = $random;
            end
    
            @(posedge clk);
            wr_en = 0; 
            rd_en = 0;
    
        end
    endtask

endmodule
