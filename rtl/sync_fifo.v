`timescale 1ns/1ps

module sync_fifo#(
    parameter DEPTH = 16,
    parameter WIDTH = 8, 
    parameter THRESHOLD = 2
    )(
    input wire clk,rst_n,
    input wire wr_en,rd_en,
    input wire [WIDTH-1:0] wr_data,
    output reg [WIDTH-1:0] rd_data,
    output reg empty,full,almost_empty,almost_full
);
    initial begin
       if ((DEPTH & (DEPTH-1)) != 0)
          $error("Depth must be power of 2");
    end
    
    initial begin
       if (THRESHOLD >= DEPTH)
          $error("Threshold must be < DEPTH");
    end
    
    reg [WIDTH-1:0] mem [DEPTH-1:0];
    localparam ADDRESS_BITS = $clog2(DEPTH);
    reg [ADDRESS_BITS:0]wr_ptr,rd_ptr; //one extra bit for wrap up detection
    
   
    wire wr_allow,rd_allow; 
    assign wr_allow = wr_en && (!full || rd_en);
    assign rd_allow = rd_en && (!empty || wr_en);
    
    
    wire [ADDRESS_BITS:0] next_wr_ptr, next_rd_ptr;
    assign  next_wr_ptr = wr_allow ? wr_ptr + 1'b1 : wr_ptr;
    assign  next_rd_ptr = rd_allow ? rd_ptr + 1'b1 : rd_ptr;
    
    wire [ADDRESS_BITS:0] occupancy;
    assign occupancy = next_wr_ptr - next_rd_ptr;
    
    wire empty_next,full_next;
    assign empty_next = (occupancy == 0);
    assign full_next  = (occupancy == DEPTH);
    
    always@(posedge clk) begin
        if(!rst_n) begin
            empty <= 1'b1;
            full  <= 1'b0;
            almost_empty <= 1'b0;
            almost_full  <= 1'b0;
            rd_data <= 'b0;
            wr_ptr <= 'b0;
            rd_ptr <= 'b0;
        end else begin
            if(wr_allow && rd_allow && empty) begin
                rd_data <= wr_data;
                rd_ptr <= next_rd_ptr;
                wr_ptr <= next_wr_ptr;
            end else begin
                if(wr_allow) begin
                    mem[wr_ptr[ADDRESS_BITS-1:0]] <= wr_data;
                end
                
                if(rd_allow) begin
                    rd_data <= mem[rd_ptr[ADDRESS_BITS-1:0]];
                end
                
                rd_ptr <= next_rd_ptr;
                wr_ptr <= next_wr_ptr;
            end
            
            empty <=  empty_next;
            full  <= full_next;
            almost_empty <= (!empty_next) && (occupancy <= THRESHOLD);
            almost_full   <= (!full_next)  && (occupancy >= DEPTH - THRESHOLD);
            
        end
    end
    
endmodule
