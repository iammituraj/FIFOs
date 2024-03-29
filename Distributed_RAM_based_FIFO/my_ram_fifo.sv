/*=================================================================================================================================================================================
   Design       : Dual-port Distributed RAM-based FIFO

   Description  : Fully synthesisable and configurable RAM based FIFO.
                  - Infers Dual-port Distributed RAM on FPGA synthesisers.
                  - Configurable Data width.
                  - Configurable Depth.
                  - Full and Empty signals have zero cycle latency.
                  
   Developer    : Mitu Raj, chip@chipmunklogic.com at Chipmunk Logic ™, https://chipmunklogic.com
   Date         : Feb-17-2021
=================================================================================================================================================================================*/

/*=================================================================================================================================================================================
                                                                                 R A M   F I F O
=================================================================================================================================================================================*/

module my_ram_fifo #(
                       parameter DATA_W           = 8      ,        // Data width
                       parameter DEPTH            = 8               // Depth
                    )

                    (
                       /* Global */                    	
                       input                   clk         ,        // Clock
                       input                   rstn        ,        // Active-low Synchronous Reset
                       
                       /* Control */                       
                       input                   i_fifoen    ,        // FIFO enable

                       /* Enqueue side */                       
                       input                   i_wren      ,        // Write Enable
                       input  [DATA_W - 1 : 0] i_wrdata    ,        // Write-data                    
                       output                  o_full      ,        // Full signal
                       
                       /* Dequeue side */   
                       input                   i_rden      ,        // Read Enable
                       output [DATA_W - 1 : 0] o_rddata    ,        // Read-data                    
                       output                  o_empty              // Empty signal
                    );


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Internal Registers/Signals
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
logic [$clog2(DEPTH) - 1 : 0] wrptr_rg        ;        // Write pointer
logic [$clog2(DEPTH) - 1 : 0] rdptr_rg        ;        // Read pointer
logic [$clog2(DEPTH)     : 0] dcount_rg       ;        // Data counter
      
logic                         wren_s          ;        // Write Enable signal generated iff FIFO is not full
logic                         rden_s          ;        // Read Enable signal generated iff FIFO is not empty
logic                         full_s          ;        // Full signal
logic                         empty_s         ;        // Empty signal


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Instantiation of RAM
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
my_ram #(
           .DATA_W  ( DATA_W )    ,
           .DEPTH   ( DEPTH  )
        )

my_ram  (
           .clk      ( clk      ) ,
           
           .i_ramen  ( i_fifoen ) ,
           .i_wren   ( wren_s   ) ,
           .i_waddr  ( wrptr_rg ) ,
           .i_wdata  ( i_wrdata ) ,

           .i_raddr  ( rdptr_rg ) ,
           .o_rdata  ( o_rddata )
        ) ;


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Synchronous logic to write to and read from FIFO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
always @ (posedge clk) begin

   if (!rstn) begin     
           
      wrptr_rg  <= 0              ;
      rdptr_rg  <= 0              ;      
      dcount_rg <= 0              ;
      
   end

   else begin     
            
      if (i_fifoen) begin
      
         /* FIFO write logic */            
         if (wren_s) begin         
         
            if (wrptr_rg == DEPTH - 1) begin
               wrptr_rg <= 0               ;        // Reset write pointer  
            end

            else begin
               wrptr_rg <= wrptr_rg + 1    ;        // Increment write pointer            
            end

         end

         /* FIFO read logic */
         if (rden_s) begin         

            if (rdptr_rg == DEPTH - 1) begin
               rdptr_rg <= 0               ;        // Reset read pointer
            end

            else begin
               rdptr_rg <= rdptr_rg + 1    ;        // Increment read pointer            
            end

         end

         /* FIFO data counter update logic */
         if (wren_s && !rden_s) begin               // Write operation
            dcount_rg <= dcount_rg + 1 ;
         end                    
         else if (!wren_s && rden_s) begin          // Read operation
            dcount_rg <= dcount_rg - 1 ;         
         end   
         
      end
   
   end

end


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Continuous Assignments
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

// Full and Empty internal
assign full_s      = (dcount_rg == DEPTH) ? 1'b1 : 0 ;
assign empty_s     = (dcount_rg == 0    ) ? 1'b1 : 0 ;

// Write and Read Enables internal
assign wren_s      = i_wren & !full_s                ;  
assign rden_s      = i_rden & !empty_s               ;

// Full and Empty to output
assign o_full      = full_s                          ;
assign o_empty     = empty_s                         ;
 

endmodule

/*=================================================================================================================================================================================
                                                                                 R A M   F I F O
=================================================================================================================================================================================*/
