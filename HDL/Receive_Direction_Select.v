module Receive_Direction_Select(
    input                           clk         ,
    input                           rst_n       ,
    input                           E_RX_REQ    ,
    input               [15:0]      E_RX_DATA   ,
    output      reg                 E_RX_ACK    ,
    input                           S_RX_REQ    ,
    input               [15:0]      S_RX_DATA   ,
    output      reg                 S_RX_ACK    ,   
    input                           W_RX_REQ    ,
    input               [15:0]      W_RX_DATA   ,
    output      reg                 W_RX_ACK    ,
    input                           N_RX_REQ    ,
    input               [15:0]      N_RX_DATA   ,
    output      reg                 N_RX_ACK    ,

    output      reg                 RX_REQ      ,
    output      reg     [15:0]      RX_DATA     ,
    input                           RX_ACK      ,

    output               [1:0]      Receive_Direction,
    input                           RECE_DONE

);
/******************** define signal *******************/    
wire                 E_RX_REQ_delay;
wire                 S_RX_REQ_delay;
wire                 W_RX_REQ_delay;
wire                 N_RX_REQ_delay;

wire                 e_rx_req_edge;
wire                 s_rx_req_edge;
wire                 w_rx_req_edge;
wire                 n_rx_req_edge;

reg      [1:0]       receive_direction;

/******************** assign *******************/ 
assign      Receive_Direction = receive_direction;

/******************** delay_3_clk *******************/    
delay_3_clk e_delay_3_clk(
    .clk         (clk           ), 
    .rst_n       (rst_n         ), 
    .signal      (E_RX_REQ      ), 
    .signal_delay(E_RX_REQ_delay)
);
delay_3_clk s_delay_3_clk(
    .clk         (clk           ), 
    .rst_n       (rst_n         ), 
    .signal      (S_RX_REQ      ), 
    .signal_delay(S_RX_REQ_delay)
);
delay_3_clk w_delay_3_clk(
    .clk         (clk           ), 
    .rst_n       (rst_n         ), 
    .signal      (W_RX_REQ      ), 
    .signal_delay(W_RX_REQ_delay)
);
delay_3_clk n_delay_3_clk(
    .clk         (clk           ), 
    .rst_n       (rst_n         ), 
    .signal      (N_RX_REQ      ), 
    .signal_delay(N_RX_REQ_delay)
);

/******************** edge detection *******************/    
edge_detection e_rx_req_edge_detection(
    .clk        (clk      ),
    .rst_n      (rst_n    ),
    .data       (E_RX_REQ_delay),
    .pos_edge   ( ),   
    .neg_edge   ( ),    
    .data_edge  (e_rx_req_edge)    
);
edge_detection s_rx_req_edge_detection(
    .clk        (clk      ),
    .rst_n      (rst_n    ),
    .data       (S_RX_REQ_delay),
    .pos_edge   ( ),   
    .neg_edge   ( ),    
    .data_edge  (s_rx_req_edge)    
);
edge_detection w_rx_req_edge_detection(
    .clk        (clk      ),
    .rst_n      (rst_n    ),
    .data       (W_RX_REQ_delay),
    .pos_edge   ( ),   
    .neg_edge   ( ),    
    .data_edge  (w_rx_req_edge)    
);
edge_detection n_rx_req_edge_detection(
    .clk        (clk      ),
    .rst_n      (rst_n    ),
    .data       (N_RX_REQ_delay),
    .pos_edge   ( ),   
    .neg_edge   ( ),    
    .data_edge  (n_rx_req_edge)    
);

always @(posedge clk) begin
    if(!rst_n) begin
        RX_REQ <= 1'b0;
    end
    else begin
        case (receive_direction)
            2'b00: begin
                RX_REQ              <= E_RX_REQ;
                RX_DATA             <= E_RX_DATA;
                E_RX_ACK            <= RX_ACK;
            end
            2'b01: begin
                RX_REQ              <= S_RX_REQ;
                RX_DATA             <= S_RX_DATA;
                S_RX_ACK            <= RX_ACK;
            end
            2'b10: begin
                RX_REQ              <= W_RX_REQ;
                RX_DATA             <= W_RX_DATA;
                W_RX_ACK           <= RX_ACK;
            end
            2'b11: begin
                RX_REQ              <= N_RX_REQ;
                RX_DATA             <= N_RX_DATA;
                N_RX_ACK            <= RX_ACK;
            end
            default: begin
                RX_REQ              <= E_RX_REQ;
                RX_DATA             <= E_RX_DATA;
                E_RX_ACK            <= RX_ACK;
            end
        endcase
    end
end


always @(posedge clk) begin
    if(!rst_n) begin
        receive_direction <= 2'b10;
    end
    else if(RECE_DONE) begin   
        if(e_rx_req_edge) begin
            receive_direction   <= 2'b00;
        end
        else if(s_rx_req_edge) begin
            receive_direction   <= 2'b01;
        end 
        else if(w_rx_req_edge) begin
            receive_direction   <= 2'b10;
        end 
        else if(n_rx_req_edge) begin
            receive_direction   <= 2'b11;
        end 
    end
end

endmodule
