`timescale 1ns / 1ps

module Receive_top_tb( );
    reg     clk                     ;
    reg     rst_n                   ;
    
    reg                         M_AXIS_TREADY           ;
    wire [15:0]                 M_AXIS_TDATA            ;
    wire                        M_AXIS_TVALID           ;
    wire   [1:0]                M_AXIS_TKEEP            ;
    wire                        M_AXIS_TLAST            ;
    
    reg                         E_RX_REQ                ;
    reg       [15:0]           E_RX_DATA               ;
    wire                        E_RX_ACK                ;
    reg                         S_RX_REQ                ;
    reg        [15:0]            S_RX_DATA               ;
    wire                        S_RX_ACK                ;
    reg                         W_RX_REQ                ;
    reg        [15:0]            W_RX_DATA               ;
    wire                        W_RX_ACK                ;
    reg                         N_RX_REQ                ;
    reg         [15:0]           N_RX_DATA               ;
    wire                        N_RX_ACK                ;
    
    wire                        RECE_DONE               ;
    wire       [31:0]           RECE_COUNT              ;
    wire        [1:0]           Receive_Direction       ;
    
    reg                    w_enable;
    reg                    n_enable;
    wire                   W_RX_ACK_edge    ;
    wire                   N_RX_ACK_edge    ;
    
    always #10 clk = ~clk;

    initial begin
        clk  = 1'b0;
        rst_n = 1'b0;
        w_enable = 1'b0;
        n_enable = 1'b0;
        M_AXIS_TREADY = 1'b0;
        W_RX_REQ = 1'b0;
        
        #100
        rst_n = 1'b1;
        w_enable = 1'b1;
        M_AXIS_TREADY = 1'b1;
        W_RX_REQ = 1'b1;
        
        #2000
        w_enable = 1'b0;
        
        #2000
        w_enable = 1'b1;
        
        
        #6000
      
        $finish;                
    end
    
    always @(posedge clk) begin 
        if(!rst_n) begin
            W_RX_DATA <= 16'd0000;
            W_RX_REQ  <= 1'b0;
        end else if(W_RX_ACK_edge && w_enable) begin
            W_RX_DATA <= W_RX_DATA + 16'd1;
            W_RX_REQ  <= ~W_RX_REQ;
        end
    end
    
    always @(posedge clk) begin 
        if(!rst_n) begin
            N_RX_DATA <= 16'd999;
            N_RX_REQ  <= 1'b0;
        end else if(N_RX_ACK_edge && n_enable) begin
            N_RX_DATA <= N_RX_DATA - 16'd1;
            N_RX_REQ  <= ~N_RX_REQ;
        end
    end

edge_detection rx_ack_W_edge_detection(
        .clk        (clk      ),
        .rst_n      (rst_n    ),
        .data       (W_RX_ACK),
        .pos_edge   ( ),   
        .neg_edge   ( ),    
        .data_edge  (W_RX_ACK_edge)    
    );
    
edge_detection rx_ack_N_edge_detection(
        .clk        (clk      ),
        .rst_n      (rst_n    ),
        .data       (N_RX_ACK),
        .pos_edge   ( ),   
        .neg_edge   ( ),    
        .data_edge  (N_RX_ACK_edge)    
    );


Receive_top u_Receive_top(
    .clk              (clk                ),
    .rst_n            (rst_n              ),
    .M_AXIS_TREADY    (M_AXIS_TREADY      ),
    .M_AXIS_TDATA     (M_AXIS_TDATA       ),
    .M_AXIS_TVALID    (M_AXIS_TVALID      ),
    .M_AXIS_TKEEP     (M_AXIS_TKEEP       ),
    .M_AXIS_TLAST     (M_AXIS_TLAST       ),
    .E_RX_REQ         (E_RX_REQ           ),
    .E_RX_DATA        (E_RX_DATA          ),
    .E_RX_ACK         (E_RX_ACK           ),
    .S_RX_REQ         (S_RX_REQ           ),
    .S_RX_DATA        (S_RX_DATA          ),
    .S_RX_ACK         (S_RX_ACK           ),
    .W_RX_REQ         (W_RX_REQ           ),
    .W_RX_DATA        (W_RX_DATA          ),
    .W_RX_ACK         (W_RX_ACK           ),
    .N_RX_REQ         (N_RX_REQ           ),
    .N_RX_DATA        (N_RX_DATA          ),
    .N_RX_ACK         (N_RX_ACK           ),
    .RECE_DONE        (RECE_DONE          ),
    .RECE_COUNT       (RECE_COUNT         ),
    .Receive_Direction(Receive_Direction  )
    );





endmodule
