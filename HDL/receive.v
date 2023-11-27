module Receive #(
    parameter RECE_DONE_WAIT_TIME = 100
)
(
    input                   clk                 ,
    input                   rst_n               ,

    input                   M_AXIS_TREADY       ,
    output      [15:0]      M_AXIS_TDATA        ,
    output                  M_AXIS_TVALID       ,
    output      [1:0]       M_AXIS_TKEEP        ,
    output                  M_AXIS_TLAST        ,  

    input       [15:0]      RX_DATA             ,
    input                   RX_REQ              ,
    output                  RX_ACK              ,    

    output                  RECE_DONE           ,
    output     [31:0]       RECE_COUNT          
    );


/******************** define signal *******************/    
    reg                 rx_ack; 

    wire    [1:0]       m_axis_tkeep; 
    reg  	            m_axis_tvalid;
	reg   	            m_axis_tlast;
	reg     [15:0]      m_axis_tdata;

	reg  				rece_done;
    reg     [31:0]      rece_count;
    reg     [31:0]      done_count;

    wire                rx_req_edge;


/********************** assign *************************/ 
    assign      M_AXIS_TVALID       =   m_axis_tvalid;
    assign      M_AXIS_TLAST        =   1'b0;
    assign      M_AXIS_TKEEP        =   m_axis_tkeep; 
    assign      M_AXIS_TDATA        =   m_axis_tdata;
	assign 		m_axis_tkeep		=	2'b11;  
    assign      RECE_DONE           =   rece_done;
    assign      RECE_COUNT          =   rece_count;
    assign      RX_ACK              =   rx_ack;                                                                     


/********************** edge detection ******************/ 
    edge_detection rx_req_west_edge_detection(
        .clk        (clk      ),
        .rst_n      (rst_n    ),
        .data       (RX_REQ),
        .pos_edge   ( ),   
        .neg_edge   ( ),    
        .data_edge  (rx_req_edge)    
    );

/**********************state machine****************************/

    localparam  [1:0]   IDLE    = 2'b01;
    localparam  [1:0]   RECE    = 2'b10;

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
                if(rx_req_edge) begin
                    next_state = RECE;
                end
                else begin
                    next_state = IDLE;
                end
            end
            RECE: begin
                if(done_count == RECE_DONE_WAIT_TIME-1) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = RECE;
                end
            end
            default: next_state = IDLE;

        endcase
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
        end
        else if (rx_req_edge) begin
            m_axis_tvalid <= 1'b1;
        end
        else if (M_AXIS_TREADY)begin
            m_axis_tvalid <= 1'b0;
        end  
    end  

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_ack <= 1'b0;
        end
        else if (M_AXIS_TREADY && M_AXIS_TVALID && curr_state == RECE) begin
            rx_ack <= ~rx_ack;
        end
    end   

    always @(posedge clk) begin
        if (rx_req_edge) begin
            m_axis_tdata <= RX_DATA;
        end
    end 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || (curr_state==IDLE && rx_req_edge)) begin
            rece_count <= 32'b0;
        end
        else if (M_AXIS_TREADY && M_AXIS_TVALID && curr_state == RECE) begin
            rece_count <= rece_count + 1'b1;
        end
    end  

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_count <= 32'b0;
        end
        else if (rx_req_edge || rece_done || curr_state == IDLE || (M_AXIS_TREADY && M_AXIS_TVALID))  begin
            done_count <= 32'b0;
        end
        else begin
            done_count <= done_count + 1'b1;
        end  
    end  

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rece_done <= 1'b1;
        end 
        else if (done_count == RECE_DONE_WAIT_TIME) begin
            rece_done <= 1'b1;
        end        
        else if (curr_state == RECE) begin
            rece_done <= 1'b0;
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