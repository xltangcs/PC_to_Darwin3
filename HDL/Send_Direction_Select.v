module Send_Direction_Select(
    input                       clk                 ,
    input                       rst_n               ,
    output  reg     [15:0]      E_TX_DATA           ,
    output  reg                 E_TX_REQ            ,
    input                       E_TX_ACK            ,
    output  reg     [15:0]      S_TX_DATA           ,
    output  reg                 S_TX_REQ            ,
    input                       S_TX_ACK            ,
    output  reg     [15:0]      W_TX_DATA           ,
    output  reg                 W_TX_REQ            ,
    input                       W_TX_ACK            ,
    output  reg     [15:0]      N_TX_DATA           ,
    output  reg                 N_TX_REQ            ,
    input                       N_TX_ACK            ,   

    input           [15:0]      TX_DATA             ,
    input                       TX_REQ              ,
    output  reg                 TX_ACK             ,

    input                       SEND_DONE           ,
    input                       DIRECTION           
);

wire                 E_TX_ACK_delay;
wire                 S_TX_ACK_delay;
wire                 W_TX_ACK_delay;
wire                 N_TX_ACK_delay;

delay_3_clk e_delay_3_clk(
    .clk         (clk           ), 
    .rst_n       (rst_n         ), 
    .signal      (E_TX_ACK      ), 
    .signal_delay(E_TX_ACK_delay)
);
delay_3_clk s_delay_3_clk(
    .clk         (clk           ), 
    .rst_n       (rst_n         ), 
    .signal      (S_TX_ACK      ), 
    .signal_delay(S_TX_ACK_delay)
);
delay_3_clk w_delay_3_clk(
    .clk         (clk           ), 
    .rst_n       (rst_n         ), 
    .signal      (W_TX_ACK      ), 
    .signal_delay(W_TX_ACK_delay)
);
delay_3_clk n_delay_3_clk(
    .clk         (clk           ), 
    .rst_n       (rst_n         ), 
    .signal      (N_TX_ACK      ), 
    .signal_delay(N_TX_ACK_delay)
);

always @(*) begin
    case(DIRECTION)
        2'b00: begin
            E_TX_DATA   <=  TX_DATA         ;
            E_TX_REQ    <=  TX_REQ          ;
            TX_ACK      <=  E_TX_ACK_delay  ;
        end
        2'b01: begin
            S_TX_DATA   <=  TX_DATA         ;
            S_TX_REQ    <=  TX_REQ          ;
            TX_ACK      <=  S_TX_ACK_delay  ;
        end
        2'b10: begin
            W_TX_DATA   <=  TX_DATA         ;
            W_TX_REQ    <=  TX_REQ          ;
            TX_ACK      <=  W_TX_ACK_delay  ;
        end
        2'b11: begin
            N_TX_DATA   <=  TX_DATA         ;
            N_TX_REQ    <=  TX_REQ          ;
            TX_ACK      <=  N_TX_ACK_delay  ;
        end
        default : begin
            E_TX_DATA   <=  TX_DATA         ;
            E_TX_REQ    <=  TX_REQ          ;
            TX_ACK      <=  E_TX_ACK_delay  ;
        end
    endcase
end


endmodule