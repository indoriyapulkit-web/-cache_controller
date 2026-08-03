module cache_controller(
input clk,
input rst,

// CPU Interface

input        cpu_write,
input [31:0] cpu_address,
input [31:0] cpu_data_in,

// Main Memory Interface
input        mem_ready,
input [31:0] mem_data_in,
// CPU Interface
output reg [31:0] cpu_data_out,
output reg        cpu_ready,

// Main Memory Interface
output reg        mem_read,
output reg        mem_write,
output reg [31:0] mem_address,
output reg [31:0] mem_data_out,

// Status
output reg        cache_hit,
output reg        cache_miss
    );
    localparam S0 = 4'd0,
               S1 = 4'd1,
               S2 = 4'd2,
               S3 = 4'd3,
               S4 = 4'd4,
               S5 = 4'd5,
               S6 = 4'd6,
               S7 = 4'd7,
               S8 = 4'd8;


    reg [3:0] current_state, next_state;
    reg [31:0] cache_data [0:15];
    reg        valid      [0:15];
    integer i;
    wire [3:0] index;
    wire [27:0] tag;
    assign index = cpu_address[3:0];
    assign tag   = cpu_address[31:4];
    reg [27:0] cache_tag [0:15];
    
    //====================================================
    // State Register
    //====================================================
    always @(posedge clk or posedge rst) begin
        if (rst)begin
            current_state <= S0;
            for (i = 0; i < 16; i = i + 1)begin
            valid[i] <= 1'b0;
            cache_data[i] <= 32'd0;
            cache_tag[i]  <= 28'd0;
            end
            end
        else begin
            current_state <= next_state;
            if(current_state==S4)begin
            valid[index]<=1;
            cache_tag[index] <= tag;
            cache_data[index]<=mem_data_in;
            end
            if(current_state==S5)begin
                valid[index]<=1;
                cache_tag[index] <= tag;
                cache_data[index]<=cpu_data_in ;
            
            end

            end
    end

    //====================================================
    // Next State Logic
    //====================================================
    always @(*) begin

        // Default assignment
        next_state = current_state;

        case(current_state)

            S0: begin
            if(!cpu_write)
            begin
                if(valid[index]&& (cache_tag[index] == tag))
                    next_state = S1;
                else
                    next_state = S2;
            end
            
            if(cpu_write)
            begin
                next_state=S2;
            
            end
            end
            S1: begin
                next_state=S0;      
            end

            S2: begin
                next_state=S3;
            end

            S3: begin
                if(!mem_ready)
                    next_state=S3;
                else begin
                if(cpu_write)
                    next_state = S5;
                else
                    next_state = S4;
            end
            end

            S4: begin
                next_state=S0;
            end

            S5: begin
                next_state=S0;
            end


            default: begin
                next_state = S0;
            end

        endcase
    end

    //====================================================
    // Output Logic (Moore FSM)
    //====================================================
    always @(*) begin

        // Default output
        mem_read   = 0;
        mem_write  = 0;
        cpu_ready  = 0;
        cache_hit  = 0;
        cache_miss = 0;
        mem_data_out=0;
        mem_address=0;
        cpu_data_out=0;

        case(current_state)
            S0:
                begin 
                    mem_read=0;
                    cpu_ready=0;
                    mem_write=0;
                    cache_hit=0;
                    cache_miss=0;
                
                end
            S1:
            begin
                cache_hit=1;
                cpu_data_out=cache_data[index];
                mem_read=0;
                mem_write=0;
                cache_miss=0;
                cpu_ready=1;
            
            end
            
            S2:
            begin
                if(!cpu_write)
                begin
                    cache_miss=1;
                    cache_hit=0;
                    mem_read=1;
                    mem_address=cpu_address;
                    cpu_ready=0;
                    mem_write=0;
                    
                end

                else
                begin
                    if(valid[index]&& (cache_tag[index] == tag))
                    begin
                        cache_miss=0;
                        cache_hit=1;
                    
                    end
                    else
                    begin
                        cache_miss=1;
                        cache_hit=0;
                    
                    end
                    

                    mem_read    = 0;
                    mem_write   = 1;
                    mem_address = cpu_address;
                    mem_data_out = cpu_data_in;
                    cpu_ready   = 0;
                end
            end
            S3:
            begin
                if(!cpu_write)
                begin
                    cache_miss=1;
                    cache_hit=0;
                    mem_read=1;
                    mem_address=cpu_address;
                    cpu_ready=0;
                    mem_write=0;
                end
                else

                begin
                    if(valid[index]&& (cache_tag[index] == tag))
                    begin
                        cache_miss=0;
                        cache_hit=1;
                    
                    end
                    else
                    begin
                        cache_miss=1;
                        cache_hit=0;
                    
                    end
                    mem_read    = 0;
                    mem_write   = 1;
                    mem_address = cpu_address;
                    mem_data_out = cpu_data_in;
                    cpu_ready   = 0;
                end 
            end
            S4:begin
                cache_miss=1;
                cache_hit=0;
                cpu_data_out=mem_data_in;
                mem_read=0;
                mem_write=0;
                cpu_ready=1;

                
            end
            S5:
            begin
                mem_data_out=cpu_data_in;
                    if(valid[index]&& (cache_tag[index] == tag))
                    begin
                        cache_miss=0;
                        cache_hit=1;
                    
                    end
                    else
                    begin
                        cache_miss=1;
                        cache_hit=0;
                    
                    end
                mem_read=0;
                mem_write=0;
                cpu_ready=1;
            
            end
            

        endcase
    end
endmodule
