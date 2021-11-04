/*===============================================================================================================================
   Design       : Single-clock Synchronous FIFO

   Description  : Fully synthesisable, configurable Single-clock Synchronous FIFO based on registers.
                  - Configurable Data width.
                  - Configurable Depth.
                  - Configurable Almost-full and Almost-empty signals.
                  - All status signals have zero cycle latency.
                  
   Developer    : Mitu Raj, chip@chipmunklogic.com at Chipmunk Logic ™, https://chipmunklogic.com
   Date         : Feb-12-2021
===============================================================================================================================*/

module my_fifo #(
                   parameter DATA_W           = 4      ,        // Data width
                   parameter DEPTH            = 8      ,        // Depth of FIFO                   
                   parameter UPP_TH           = 4      ,        // Upper threshold to generate Almost-full
                   parameter LOW_TH           = 2               // Lower threshold to generate Almost-empty
                )

                (
                   input                   clk         ,        // Clock
                   input                   rstn        ,        // Active-low Synchronous Reset
                   
                   input                   i_wren      ,        // Write Enable
                   input  [DATA_W - 1 : 0] i_wrdata    ,        // Write-data
                   output                  o_alm_full  ,        // Almost-full signal
                   output                  o_full      ,        // Full signal

                   input                   i_rden      ,        // Read Enable
                   output [DATA_W - 1 : 0] o_rddata    ,        // Read-data
                   output                  o_alm_empty ,        // Almost-empty signal
                   output                  o_empty              // Empty signal
                );


/*-------------------------------------------------------------------------------------------------------------------------------
   Internal Registers/Signals
-------------------------------------------------------------------------------------------------------------------------------*/
logic                         ready_rg        ;        // Ready signal to indicate that FIFO is out of reset
logic [DATA_W - 1        : 0] data_rg [DEPTH] ;        // Data array
logic [$clog2(DEPTH) - 1 : 0] wrptr_rg        ;        // Write pointer
logic [$clog2(DEPTH) - 1 : 0] rdptr_rg        ;        // Read pointer
logic [$clog2(DEPTH)     : 0] dcount_rg       ;        // Data counter
      
logic                         wren_s          ;        // Write Enable signal generated iff FIFO is not full
logic                         rden_s          ;        // Read Enable signal generated iff FIFO is not empty
logic                         full_s          ;        // Full signal
logic                         empty_s         ;        // Empty signal


/*-------------------------------------------------------------------------------------------------------------------------------
   Synchronous logic to write to and read from FIFO
-------------------------------------------------------------------------------------------------------------------------------*/
always @ (posedge clk) begin

   if (!rstn) begin
      
      ready_rg  <= 1'b0           ;
      data_rg   <= '{default: '0} ;
      wrptr_rg  <= 0              ;
      rdptr_rg  <= 0              ;      
      dcount_rg <= 0              ;

   end

   else begin
      
      ready_rg <= 1'b1 ;
      
      /* FIFO write logic */            
      if (wren_s) begin                          
                  
         data_rg [wrptr_rg] <= i_wrdata ;        // Data written to FIFO

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


/*-------------------------------------------------------------------------------------------------------------------------------
   Continuous Assignments
-------------------------------------------------------------------------------------------------------------------------------*/

// Full and Empty internal
assign full_s      = (dcount_rg == DEPTH) ? 1'b1 : 0                ; 
assign empty_s     = (dcount_rg == 0    ) ? 1'b1 : 0                ;

// Write and Read Enables internal
assign wren_s      = i_wren & !full_s                               ;  
assign rden_s      = i_rden & !empty_s                              ;

// Full and Empty to output
assign o_full      = full_s  || !ready_rg                           ;
assign o_empty     = empty_s                                        ;

// Almost-full and Almost Empty to output
assign o_alm_full  = ((dcount_rg > UPP_TH) ? 1'b1 : 0) || !ready_rg ;
assign o_alm_empty = (dcount_rg < LOW_TH) ? 1'b1 : 0                ;  

// Read-data to output
assign o_rddata    = data_rg [rdptr_rg]                             ;   


endmodule

/*=============================================================================================================================*/
