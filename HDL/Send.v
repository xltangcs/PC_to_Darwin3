module Send(
    input                   clk                 ,
    input                   rst_n               ,
    input       [15:0]      S_AXIS_TDATA        ,
    input                   S_AXIS_TVALID       ,
    input       [1:0]       S_AXIS_TKEEP        ,
    input                   S_AXIS_TLAST        ,
    output                  S_AXIS_TREADY       ,    

    output      [15:0]      TX_DATA             ,
    output                  TX_REQ              ,
    input                   TX_ACK              ,   

    input     wire          is_receive          ,
    output                  SEND_DONE
    );
/******************** define signal *******************/    
    reg     [15:0]      tx_data     ; 
    reg                 tx_req      ; 
    wire                tx_ack_edge   ;  
    reg                 tx_ack_en   ;  
    reg                 send_done;  
    reg                 s_axis_tready;  

    reg      [2:0]      pkg_type;
    reg      [1:0]      flit_type;
    reg      [4:0]      flit_cnt_16bit;

    wire                send_en;
  
/********************** assign *************************/ 
    assign      S_AXIS_TREADY       =   s_axis_tready;  
    assign      TX_DATA             =   tx_data     ;   
    assign      TX_REQ              =   tx_req     ;
    assign      SEND_DONE           =   send_done;

    assign      send_en             = (pkg_type == 3'b010) ?
                                      is_receive : (S_AXIS_TVALID && S_AXIS_TREADY && tx_ack_en);

/********************** edge detection ********************** **/ 
    edge_detection tx_ack_edge_detection(
        .clk        (clk      ),
        .rst_n      (rst_n    ),
        .data       (TX_ACK),
        .pos_edge   ( ),    //上升沿
        .neg_edge   ( ),    //下降沿  
        .data_edge  (tx_ack_edge)     //数据边沿
    );

/********************** state machine ****************************/

    localparam  [1:0]   IDLE    = 2'b01;
    localparam  [1:0]   SEND    = 2'b10;

    reg         [1:0]   curr_state;
    reg         [1:0]   next_state;


    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            curr_state <= IDLE;
        end
        else begin
            curr_state <= next_state;
        end
    end

    always @(*) begin
        case(curr_state)
            IDLE: begin
                if(S_AXIS_TVALID) begin
                    next_state = SEND;
                end
                else begin
                    next_state = IDLE;
                end
            end
            SEND: begin
                if(S_AXIS_TLAST && !S_AXIS_TVALID && tx_ack_edge) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = SEND;
                end
            end
            default: next_state = IDLE;

        endcase
    end

    always @( posedge clk ) begin
        if (!rst_n)
        begin
            send_done <= 1'b0;
        end   
        else if (S_AXIS_TLAST && !S_AXIS_TVALID && tx_ack_edge) begin
            send_done <= 1'b1;
        end          
        else if(S_AXIS_TVALID) begin
            send_done <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (send_en) begin
            tx_data <= S_AXIS_TDATA;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_req <= 1'b0;
        end
        else if (send_en) begin
            tx_req <= ~tx_req;
        end
    end 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tready <= 1'b1;
        end
        else if(tx_ack_edge && (curr_state == SEND)) begin
            s_axis_tready <= 1'b1;
        end   
        else if (S_AXIS_TVALID) begin
            s_axis_tready <= 1'b0;
        end
        else if(send_done) begin
            s_axis_tready <= 1'b1;
        end
    end  
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_ack_en <= 1'b1;
        end
        else if (tx_ack_edge) begin
            tx_ack_en <= 1'b1;
        end
        else if (S_AXIS_TVALID && S_AXIS_TREADY && tx_ack_en) begin
            tx_ack_en <= 1'b0;
        end
    end 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pkg_type <= 3'b000;
        end
        else if (curr_state == SEND && flit_cnt_16bit == 4'b0000) begin
            pkg_type = S_AXIS_TDATA[24:22];
        end
    end  

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flit_cnt_16bit <= 34'b0000;
        end
        else if (pkg_type == 3'b000 && flit_cnt_16bit == 4'b0100) begin //spike pkg
            flit_cnt_16bit <= 4'b000;
        end
        else if (pkg_type == 3'b001 && flit_cnt_16bit == 4'b1000) begin //write pkg
            flit_cnt_16bit <= 4'b000;
        end        
        else if (pkg_type == 3'b010 && flit_cnt_16bit == 4'b0100) begin //read pkg
            flit_cnt_16bit <= 4'b000;
        end
        else if(flit_cnt_16bit == 4'b1000) begin
            flit_cnt_16bit <= 4'b000;
        end
        else begin
            flit_cnt_16bit <= flit_cnt_16bit + 1;
        end  
    end  


/* always 模板
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            
        end
        else if ( ) begin
            
        end
        else begin
            
        end  
    end  
*/
endmodule   