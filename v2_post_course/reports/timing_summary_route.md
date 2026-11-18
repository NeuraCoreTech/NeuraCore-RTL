Copyright 1986-2022 Xilinx, Inc. All Rights Reserved. Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
| Tool Version : Vivado v.2025.1 (win64) Build 6140274 Thu May 22 00:12:29 MDT 2025
| Date         : Thu Nov 12 19:15:34 2026
| Host         : KrishnaPatil running 64-bit major release  (build 9200)
| Command      : report_timing_summary -max_paths 10 -routable_nets -report_unconstrained -file noc_impl_top_timing_summary_routed.rpt -pb noc_impl_top_timing_summary_routed.pb -rpx noc_impl_top_timing_summary_routed.rpx -warn_on_violation
| Design       : noc_impl_top
| Device       : 7a100t-csg324
| Speed File   : -1  PRODUCTION 1.23 2018-06-13
| Design State : Routed
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Timing Summary Report

------------------------------------------------------------------------------------------------
| Timer Settings
| --------------
------------------------------------------------------------------------------------------------

  Enable Multi Corner Analysis               :  Yes
  Enable Pessimism Removal                   :  Yes
  Pessimism Removal Resolution               :  Nearest Common Node
  Enable Input Delay Default Clock           :  No
  Enable Preset / Clear Arcs                 :  No
  Disable Flight Delays                      :  No
  Ignore I/O Paths                           :  No
  Timing Early Launch at Borrowing Latches   :  No
  Borrow Time for Max Delay Exceptions       :  Yes
  Merge Timing Exceptions                    :  Yes
  Inter-SLR Compensation                     :  Conservative

  Corner  Analyze    Analyze    
  Name    Max Paths  Min Paths  
  ------  ---------  ---------  
  Slow    Yes        Yes        
  Fast    Yes        Yes        


------------------------------------------------------------------------------------------------
| Report Methodology
| ------------------
------------------------------------------------------------------------------------------------

Rule       Severity  Description                                  Violations  
---------  --------  -------------------------------------------  ----------  
SYNTH-6    Warning   Timing of a RAM block might be sub-optimal   128         
SYNTH-9    Warning   Small multiplier                             80          
TIMING-18  Warning   Missing input or output delay                2           
ULMTCS-1   Warning   Control Sets use limits recommend reduction  1           

Note: This report is based on the most recent report_methodology run and may not be up-to-date. Run report_methodology on the current design for the latest report.



check_timing report

Table of Contents
-----------------
1. checking no_clock (0)
2. checking constant_clock (0)
3. checking pulse_width_clock (0)
4. checking unconstrained_internal_endpoints (0)
5. checking no_input_delay (1)
6. checking no_output_delay (1)
7. checking multiple_clock (0)
8. checking generated_clocks (0)
9. checking loops (0)
10. checking partial_input_delay (0)
11. checking partial_output_delay (0)
12. checking latch_loops (0)

1. checking no_clock (0)
------------------------
 There are 0 register/latch pins with no clock.


2. checking constant_clock (0)
------------------------------
 There are 0 register/latch pins with constant_clock.


3. checking pulse_width_clock (0)
---------------------------------
 There are 0 register/latch pins which need pulse_width check


4. checking unconstrained_internal_endpoints (0)
------------------------------------------------
 There are 0 pins that are not constrained for maximum delay.

 There are 0 pins that are not constrained for maximum delay due to constant clock.


5. checking no_input_delay (1)
------------------------------
 There is 1 input port with no input delay specified. (HIGH)

 There are 0 input ports with no input delay but user has a false path constraint.


6. checking no_output_delay (1)
-------------------------------
 There is 1 port with no output delay specified. (HIGH)

 There are 0 ports with no output delay but user has a false path constraint

 There are 0 ports with no output delay but with a timing clock defined on it or propagating through it


7. checking multiple_clock (0)
------------------------------
 There are 0 register/latch pins with multiple clocks.


8. checking generated_clocks (0)
--------------------------------
 There are 0 generated clocks that are not connected to a clock source.


9. checking loops (0)
---------------------
 There are 0 combinational loops in the design.


10. checking partial_input_delay (0)
------------------------------------
 There are 0 input ports with partial input delay specified.


11. checking partial_output_delay (0)
-------------------------------------
 There are 0 ports with partial output delay specified.


12. checking latch_loops (0)
----------------------------
 There are 0 combinational latch loops in the design through latch input



------------------------------------------------------------------------------------------------
| Design Timing Summary
| ---------------------
------------------------------------------------------------------------------------------------

    WNS(ns)      TNS(ns)  TNS Failing Endpoints  TNS Total Endpoints      WHS(ns)      THS(ns)  THS Failing Endpoints  THS Total Endpoints     WPWS(ns)     TPWS(ns)  TPWS Failing Endpoints  TPWS Total Endpoints  
    -------      -------  ---------------------  -------------------      -------      -------  ---------------------  -------------------     --------     --------  ----------------------  --------------------  
      0.061        0.000                      0                75882        0.025        0.000                      0                75882        2.750        0.000                       0                 27236  


All user specified timing constraints are met.


------------------------------------------------------------------------------------------------
| Clock Summary
| -------------
------------------------------------------------------------------------------------------------

Clock  Waveform(ns)         Period(ns)      Frequency(MHz)
-----  ------------         ----------      --------------
clk    {0.000 4.000}        8.000           125.000         


------------------------------------------------------------------------------------------------
| Intra Clock Table
| -----------------
------------------------------------------------------------------------------------------------

Clock             WNS(ns)      TNS(ns)  TNS Failing Endpoints  TNS Total Endpoints      WHS(ns)      THS(ns)  THS Failing Endpoints  THS Total Endpoints     WPWS(ns)     TPWS(ns)  TPWS Failing Endpoints  TPWS Total Endpoints  
-----             -------      -------  ---------------------  -------------------      -------      -------  ---------------------  -------------------     --------     --------  ----------------------  --------------------  
clk                 0.061        0.000                      0                75882        0.025        0.000                      0                75882        2.750        0.000                       0                 27236  


------------------------------------------------------------------------------------------------
| Inter Clock Table
| -----------------
------------------------------------------------------------------------------------------------

From Clock    To Clock          WNS(ns)      TNS(ns)  TNS Failing Endpoints  TNS Total Endpoints      WHS(ns)      THS(ns)  THS Failing Endpoints  THS Total Endpoints  
----------    --------          -------      -------  ---------------------  -------------------      -------      -------  ---------------------  -------------------  


------------------------------------------------------------------------------------------------
| Other Path Groups Table
| -----------------------
------------------------------------------------------------------------------------------------

Path Group    From Clock    To Clock          WNS(ns)      TNS(ns)  TNS Failing Endpoints  TNS Total Endpoints      WHS(ns)      THS(ns)  THS Failing Endpoints  THS Total Endpoints  
----------    ----------    --------          -------      -------  ---------------------  -------------------      -------      -------  ---------------------  -------------------  


------------------------------------------------------------------------------------------------
| User Ignored Path Table
| -----------------------
------------------------------------------------------------------------------------------------

Path Group    From Clock    To Clock    
----------    ----------    --------    


------------------------------------------------------------------------------------------------
| Unconstrained Path Table
| ------------------------
------------------------------------------------------------------------------------------------

Path Group    From Clock    To Clock    
----------    ----------    --------    
(none)        clk                         
(none)                      clk           


------------------------------------------------------------------------------------------------
| Timing Details
| --------------
------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------
From Clock:  clk
  To Clock:  clk

Setup :            0  Failing Endpoints,  Worst Slack        0.061ns,  Total Violation        0.000ns
Hold  :            0  Failing Endpoints,  Worst Slack        0.025ns,  Total Violation        0.000ns
PW    :            0  Failing Endpoints,  Worst Slack        2.750ns,  Total Violation        0.000ns
---------------------------------------------------------------------------------------------------


Max Delay Paths
--------------------------------------------------------------------------------------
Slack (MET) :             0.061ns  (required time - arrival time)
  Source:                 u_noc/c_src_reg[2][1][8][1]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][0]/CE
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            8.000ns  (clk rise@8.000ns - clk rise@0.000ns)
  Data Path Delay:        7.650ns  (logic 1.262ns (16.497%)  route 6.388ns (83.503%))
  Logic Levels:           6  (LUT5=1 LUT6=5)
  Clock Path Skew:        -0.049ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns = ( 8.924 - 8.000 ) 
    Source Clock Delay      (SCD):    0.973ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.035ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.071ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.973     0.973    u_noc/clk
    SLICE_X42Y93         FDCE                                         r  u_noc/c_src_reg[2][1][8][1]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X42Y93         FDCE (Prop_fdce_C_Q)         0.518     1.491 f  u_noc/c_src_reg[2][1][8][1]/Q
                         net (fo=76, routed)          1.082     2.573    u_noc/u_net_p/g_router[1].u_router/d1_reg[8][25]_0[1]
    SLICE_X43Y93         LUT5 (Prop_lut5_I1_O)        0.124     2.697 r  u_noc/u_net_p/g_router[1].u_router/pending[2][8]_i_2/O
                         net (fo=3, routed)           1.133     3.830    u_noc/u_net_p/g_router[1].u_router/pending[2][8]_i_2_n_0
    SLICE_X44Y94         LUT6 (Prop_lut6_I2_O)        0.124     3.954 r  u_noc/u_net_p/g_router[1].u_router/i___109_i_8/O
                         net (fo=1, routed)           0.791     4.745    u_noc/u_net_p/g_router[1].u_router/i___109_i_8_n_0
    SLICE_X43Y89         LUT6 (Prop_lut6_I3_O)        0.124     4.869 f  u_noc/u_net_p/g_router[1].u_router/i___109_i_2/O
                         net (fo=1, routed)           1.033     5.902    u_noc/u_net_p/g_router[1].u_router/i___109_i_2_n_0
    SLICE_X38Y93         LUT6 (Prop_lut6_I0_O)        0.124     6.026 r  u_noc/u_net_p/g_router[1].u_router/i___109_i_1/O
                         net (fo=19, routed)          1.056     7.082    u_noc/u_net_p/g_router[1].u_router/cnt_reg[9][1]_1
    SLICE_X30Y86         LUT6 (Prop_lut6_I2_O)        0.124     7.206 r  u_noc/u_net_p/g_router[1].u_router/g_pos[6][3]_i_4/O
                         net (fo=2, routed)           0.773     7.979    u_noc/u_net_p/g_router[1].u_router/g_pos[6][3]_i_4_n_0
    SLICE_X29Y84         LUT6 (Prop_lut6_I2_O)        0.124     8.103 r  u_noc/u_net_p/g_router[1].u_router/g_idx[6][3]_i_1/O
                         net (fo=4, routed)           0.520     8.623    u_noc/u_net_p/g_router[1].u_router/g_idx[6][3]_i_1_n_0
    SLICE_X28Y83         FDCE                                         r  u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][0]/CE
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        8.000     8.000 r  
                                                      0.000     8.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     8.924    u_noc/u_net_p/g_router[1].u_router/clk
    SLICE_X28Y83         FDCE                                         r  u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][0]/C
                         clock pessimism              0.000     8.924    
                         clock uncertainty           -0.035     8.889    
    SLICE_X28Y83         FDCE (Setup_fdce_C_CE)      -0.205     8.684    u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][0]
  -------------------------------------------------------------------
                         required time                          8.684    
                         arrival time                          -8.623    
  -------------------------------------------------------------------
                         slack                                  0.061    

Slack (MET) :             0.061ns  (required time - arrival time)
  Source:                 u_noc/c_src_reg[2][1][8][1]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][1]/CE
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            8.000ns  (clk rise@8.000ns - clk rise@0.000ns)
  Data Path Delay:        7.650ns  (logic 1.262ns (16.497%)  route 6.388ns (83.503%))
  Logic Levels:           6  (LUT5=1 LUT6=5)
  Clock Path Skew:        -0.049ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns = ( 8.924 - 8.000 ) 
    Source Clock Delay      (SCD):    0.973ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.035ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.071ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.973     0.973    u_noc/clk
    SLICE_X42Y93         FDCE                                         r  u_noc/c_src_reg[2][1][8][1]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X42Y93         FDCE (Prop_fdce_C_Q)         0.518     1.491 f  u_noc/c_src_reg[2][1][8][1]/Q
                         net (fo=76, routed)          1.082     2.573    u_noc/u_net_p/g_router[1].u_router/d1_reg[8][25]_0[1]
    SLICE_X43Y93         LUT5 (Prop_lut5_I1_O)        0.124     2.697 r  u_noc/u_net_p/g_router[1].u_router/pending[2][8]_i_2/O
                         net (fo=3, routed)           1.133     3.830    u_noc/u_net_p/g_router[1].u_router/pending[2][8]_i_2_n_0
    SLICE_X44Y94         LUT6 (Prop_lut6_I2_O)        0.124     3.954 r  u_noc/u_net_p/g_router[1].u_router/i___109_i_8/O
                         net (fo=1, routed)           0.791     4.745    u_noc/u_net_p/g_router[1].u_router/i___109_i_8_n_0
    SLICE_X43Y89         LUT6 (Prop_lut6_I3_O)        0.124     4.869 f  u_noc/u_net_p/g_router[1].u_router/i___109_i_2/O
                         net (fo=1, routed)           1.033     5.902    u_noc/u_net_p/g_router[1].u_router/i___109_i_2_n_0
    SLICE_X38Y93         LUT6 (Prop_lut6_I0_O)        0.124     6.026 r  u_noc/u_net_p/g_router[1].u_router/i___109_i_1/O
                         net (fo=19, routed)          1.056     7.082    u_noc/u_net_p/g_router[1].u_router/cnt_reg[9][1]_1
    SLICE_X30Y86         LUT6 (Prop_lut6_I2_O)        0.124     7.206 r  u_noc/u_net_p/g_router[1].u_router/g_pos[6][3]_i_4/O
                         net (fo=2, routed)           0.773     7.979    u_noc/u_net_p/g_router[1].u_router/g_pos[6][3]_i_4_n_0
    SLICE_X29Y84         LUT6 (Prop_lut6_I2_O)        0.124     8.103 r  u_noc/u_net_p/g_router[1].u_router/g_idx[6][3]_i_1/O
                         net (fo=4, routed)           0.520     8.623    u_noc/u_net_p/g_router[1].u_router/g_idx[6][3]_i_1_n_0
    SLICE_X28Y83         FDCE                                         r  u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][1]/CE
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        8.000     8.000 r  
                                                      0.000     8.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     8.924    u_noc/u_net_p/g_router[1].u_router/clk
    SLICE_X28Y83         FDCE                                         r  u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][1]/C
                         clock pessimism              0.000     8.924    
                         clock uncertainty           -0.035     8.889    
    SLICE_X28Y83         FDCE (Setup_fdce_C_CE)      -0.205     8.684    u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][1]
  -------------------------------------------------------------------
                         required time                          8.684    
                         arrival time                          -8.623    
  -------------------------------------------------------------------
                         slack                                  0.061    

Slack (MET) :             0.061ns  (required time - arrival time)
  Source:                 u_noc/c_src_reg[2][1][8][1]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][2]/CE
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            8.000ns  (clk rise@8.000ns - clk rise@0.000ns)
  Data Path Delay:        7.650ns  (logic 1.262ns (16.497%)  route 6.388ns (83.503%))
  Logic Levels:           6  (LUT5=1 LUT6=5)
  Clock Path Skew:        -0.049ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns = ( 8.924 - 8.000 ) 
    Source Clock Delay      (SCD):    0.973ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.035ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.071ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.973     0.973    u_noc/clk
    SLICE_X42Y93         FDCE                                         r  u_noc/c_src_reg[2][1][8][1]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X42Y93         FDCE (Prop_fdce_C_Q)         0.518     1.491 f  u_noc/c_src_reg[2][1][8][1]/Q
                         net (fo=76, routed)          1.082     2.573    u_noc/u_net_p/g_router[1].u_router/d1_reg[8][25]_0[1]
    SLICE_X43Y93         LUT5 (Prop_lut5_I1_O)        0.124     2.697 r  u_noc/u_net_p/g_router[1].u_router/pending[2][8]_i_2/O
                         net (fo=3, routed)           1.133     3.830    u_noc/u_net_p/g_router[1].u_router/pending[2][8]_i_2_n_0
    SLICE_X44Y94         LUT6 (Prop_lut6_I2_O)        0.124     3.954 r  u_noc/u_net_p/g_router[1].u_router/i___109_i_8/O
                         net (fo=1, routed)           0.791     4.745    u_noc/u_net_p/g_router[1].u_router/i___109_i_8_n_0
    SLICE_X43Y89         LUT6 (Prop_lut6_I3_O)        0.124     4.869 f  u_noc/u_net_p/g_router[1].u_router/i___109_i_2/O
                         net (fo=1, routed)           1.033     5.902    u_noc/u_net_p/g_router[1].u_router/i___109_i_2_n_0
    SLICE_X38Y93         LUT6 (Prop_lut6_I0_O)        0.124     6.026 r  u_noc/u_net_p/g_router[1].u_router/i___109_i_1/O
                         net (fo=19, routed)          1.056     7.082    u_noc/u_net_p/g_router[1].u_router/cnt_reg[9][1]_1
    SLICE_X30Y86         LUT6 (Prop_lut6_I2_O)        0.124     7.206 r  u_noc/u_net_p/g_router[1].u_router/g_pos[6][3]_i_4/O
                         net (fo=2, routed)           0.773     7.979    u_noc/u_net_p/g_router[1].u_router/g_pos[6][3]_i_4_n_0
    SLICE_X29Y84         LUT6 (Prop_lut6_I2_O)        0.124     8.103 r  u_noc/u_net_p/g_router[1].u_router/g_idx[6][3]_i_1/O
                         net (fo=4, routed)           0.520     8.623    u_noc/u_net_p/g_router[1].u_router/g_idx[6][3]_i_1_n_0
    SLICE_X28Y83         FDCE                                         r  u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][2]/CE
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        8.000     8.000 r  
                                                      0.000     8.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     8.924    u_noc/u_net_p/g_router[1].u_router/clk
    SLICE_X28Y83         FDCE                                         r  u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][2]/C
                         clock pessimism              0.000     8.924    
                         clock uncertainty           -0.035     8.889    
    SLICE_X28Y83         FDCE (Setup_fdce_C_CE)      -0.205     8.684    u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][2]
  -------------------------------------------------------------------
                         required time                          8.684    
                         arrival time                          -8.623    
  -------------------------------------------------------------------
                         slack                                  0.061    

Slack (MET) :             0.061ns  (required time - arrival time)
  Source:                 u_noc/c_src_reg[2][1][8][1]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][3]/CE
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            8.000ns  (clk rise@8.000ns - clk rise@0.000ns)
  Data Path Delay:        7.650ns  (logic 1.262ns (16.497%)  route 6.388ns (83.503%))
  Logic Levels:           6  (LUT5=1 LUT6=5)
  Clock Path Skew:        -0.049ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns = ( 8.924 - 8.000 ) 
    Source Clock Delay      (SCD):    0.973ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.035ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.071ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.973     0.973    u_noc/clk
    SLICE_X42Y93         FDCE                                         r  u_noc/c_src_reg[2][1][8][1]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X42Y93         FDCE (Prop_fdce_C_Q)         0.518     1.491 f  u_noc/c_src_reg[2][1][8][1]/Q
                         net (fo=76, routed)          1.082     2.573    u_noc/u_net_p/g_router[1].u_router/d1_reg[8][25]_0[1]
    SLICE_X43Y93         LUT5 (Prop_lut5_I1_O)        0.124     2.697 r  u_noc/u_net_p/g_router[1].u_router/pending[2][8]_i_2/O
                         net (fo=3, routed)           1.133     3.830    u_noc/u_net_p/g_router[1].u_router/pending[2][8]_i_2_n_0
    SLICE_X44Y94         LUT6 (Prop_lut6_I2_O)        0.124     3.954 r  u_noc/u_net_p/g_router[1].u_router/i___109_i_8/O
                         net (fo=1, routed)           0.791     4.745    u_noc/u_net_p/g_router[1].u_router/i___109_i_8_n_0
    SLICE_X43Y89         LUT6 (Prop_lut6_I3_O)        0.124     4.869 f  u_noc/u_net_p/g_router[1].u_router/i___109_i_2/O
                         net (fo=1, routed)           1.033     5.902    u_noc/u_net_p/g_router[1].u_router/i___109_i_2_n_0
    SLICE_X38Y93         LUT6 (Prop_lut6_I0_O)        0.124     6.026 r  u_noc/u_net_p/g_router[1].u_router/i___109_i_1/O
                         net (fo=19, routed)          1.056     7.082    u_noc/u_net_p/g_router[1].u_router/cnt_reg[9][1]_1
    SLICE_X30Y86         LUT6 (Prop_lut6_I2_O)        0.124     7.206 r  u_noc/u_net_p/g_router[1].u_router/g_pos[6][3]_i_4/O
                         net (fo=2, routed)           0.773     7.979    u_noc/u_net_p/g_router[1].u_router/g_pos[6][3]_i_4_n_0
    SLICE_X29Y84         LUT6 (Prop_lut6_I2_O)        0.124     8.103 r  u_noc/u_net_p/g_router[1].u_router/g_idx[6][3]_i_1/O
                         net (fo=4, routed)           0.520     8.623    u_noc/u_net_p/g_router[1].u_router/g_idx[6][3]_i_1_n_0
    SLICE_X28Y83         FDCE                                         r  u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][3]/CE
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        8.000     8.000 r  
                                                      0.000     8.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     8.924    u_noc/u_net_p/g_router[1].u_router/clk
    SLICE_X28Y83         FDCE                                         r  u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][3]/C
                         clock pessimism              0.000     8.924    
                         clock uncertainty           -0.035     8.889    
    SLICE_X28Y83         FDCE (Setup_fdce_C_CE)      -0.205     8.684    u_noc/u_net_p/g_router[1].u_router/g_idx_reg[6][3]
  -------------------------------------------------------------------
                         required time                          8.684    
                         arrival time                          -8.623    
  -------------------------------------------------------------------
                         slack                                  0.061    

Slack (MET) :             0.083ns  (required time - arrival time)
  Source:                 u_noc/c_src_reg[2][3][3][1]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/u_net_p/g_router[3].u_router/g_idx_reg[9][0]/CE
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            8.000ns  (clk rise@8.000ns - clk rise@0.000ns)
  Data Path Delay:        7.628ns  (logic 1.498ns (19.638%)  route 6.130ns (80.362%))
  Logic Levels:           6  (LUT5=1 LUT6=5)
  Clock Path Skew:        -0.049ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns = ( 8.924 - 8.000 ) 
    Source Clock Delay      (SCD):    0.973ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.035ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.071ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.973     0.973    u_noc/clk
    SLICE_X54Y53         FDCE                                         r  u_noc/c_src_reg[2][3][3][1]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X54Y53         FDCE (Prop_fdce_C_Q)         0.518     1.491 r  u_noc/c_src_reg[2][3][3][1]/Q
                         net (fo=83, routed)          1.264     2.755    u_noc/u_net_p/g_router[3].u_router/d1_reg[3][25]_0[1]
    SLICE_X55Y54         LUT5 (Prop_lut5_I3_O)        0.152     2.907 f  u_noc/u_net_p/g_router[3].u_router/pending[7][3]_i_2/O
                         net (fo=2, routed)           0.776     3.683    u_noc/u_net_p/g_router[3].u_router/pending[7][3]_i_2_n_0
    SLICE_X55Y59         LUT6 (Prop_lut6_I4_O)        0.332     4.015 r  u_noc/u_net_p/g_router[3].u_router/i___112_i_3/O
                         net (fo=1, routed)           0.576     4.590    u_noc/u_net_p/g_router[3].u_router/i___112_i_3_n_0
    SLICE_X59Y59         LUT6 (Prop_lut6_I5_O)        0.124     4.714 f  u_noc/u_net_p/g_router[3].u_router/i___112_i_1/O
                         net (fo=3, routed)           1.043     5.758    u_noc/u_net_p/g_router[3].u_router/i___112_i_1_n_0
    SLICE_X57Y56         LUT6 (Prop_lut6_I4_O)        0.124     5.882 f  u_noc/u_net_p/g_router[3].u_router/i___7_i_2/O
                         net (fo=22, routed)          0.952     6.834    u_noc/u_net_p/g_router[3].u_router/pending_reg[7][12]_0
    SLICE_X61Y63         LUT6 (Prop_lut6_I5_O)        0.124     6.958 r  u_noc/u_net_p/g_router[3].u_router/g_idx[9][3]_i_3/O
                         net (fo=1, routed)           0.797     7.755    u_noc/u_net_p/g_router[3].u_router/g_idx[9][3]_i_3_n_0
    SLICE_X61Y64         LUT6 (Prop_lut6_I0_O)        0.124     7.879 r  u_noc/u_net_p/g_router[3].u_router/g_idx[9][3]_i_1/O
                         net (fo=4, routed)           0.722     8.601    u_noc/u_net_p/g_router[3].u_router/g_idx[9][3]_i_1_n_0
    SLICE_X61Y63         FDCE                                         r  u_noc/u_net_p/g_router[3].u_router/g_idx_reg[9][0]/CE
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        8.000     8.000 r  
                                                      0.000     8.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     8.924    u_noc/u_net_p/g_router[3].u_router/clk
    SLICE_X61Y63         FDCE                                         r  u_noc/u_net_p/g_router[3].u_router/g_idx_reg[9][0]/C
                         clock pessimism              0.000     8.924    
                         clock uncertainty           -0.035     8.889    
    SLICE_X61Y63         FDCE (Setup_fdce_C_CE)      -0.205     8.684    u_noc/u_net_p/g_router[3].u_router/g_idx_reg[9][0]
  -------------------------------------------------------------------
                         required time                          8.684    
                         arrival time                          -8.601    
  -------------------------------------------------------------------
                         slack                                  0.083    

Slack (MET) :             0.083ns  (required time - arrival time)
  Source:                 u_noc/c_src_reg[2][3][3][1]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/u_net_p/g_router[3].u_router/g_idx_reg[9][3]/CE
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            8.000ns  (clk rise@8.000ns - clk rise@0.000ns)
  Data Path Delay:        7.628ns  (logic 1.498ns (19.638%)  route 6.130ns (80.362%))
  Logic Levels:           6  (LUT5=1 LUT6=5)
  Clock Path Skew:        -0.049ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns = ( 8.924 - 8.000 ) 
    Source Clock Delay      (SCD):    0.973ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.035ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.071ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.973     0.973    u_noc/clk
    SLICE_X54Y53         FDCE                                         r  u_noc/c_src_reg[2][3][3][1]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X54Y53         FDCE (Prop_fdce_C_Q)         0.518     1.491 r  u_noc/c_src_reg[2][3][3][1]/Q
                         net (fo=83, routed)          1.264     2.755    u_noc/u_net_p/g_router[3].u_router/d1_reg[3][25]_0[1]
    SLICE_X55Y54         LUT5 (Prop_lut5_I3_O)        0.152     2.907 f  u_noc/u_net_p/g_router[3].u_router/pending[7][3]_i_2/O
                         net (fo=2, routed)           0.776     3.683    u_noc/u_net_p/g_router[3].u_router/pending[7][3]_i_2_n_0
    SLICE_X55Y59         LUT6 (Prop_lut6_I4_O)        0.332     4.015 r  u_noc/u_net_p/g_router[3].u_router/i___112_i_3/O
                         net (fo=1, routed)           0.576     4.590    u_noc/u_net_p/g_router[3].u_router/i___112_i_3_n_0
    SLICE_X59Y59         LUT6 (Prop_lut6_I5_O)        0.124     4.714 f  u_noc/u_net_p/g_router[3].u_router/i___112_i_1/O
                         net (fo=3, routed)           1.043     5.758    u_noc/u_net_p/g_router[3].u_router/i___112_i_1_n_0
    SLICE_X57Y56         LUT6 (Prop_lut6_I4_O)        0.124     5.882 f  u_noc/u_net_p/g_router[3].u_router/i___7_i_2/O
                         net (fo=22, routed)          0.952     6.834    u_noc/u_net_p/g_router[3].u_router/pending_reg[7][12]_0
    SLICE_X61Y63         LUT6 (Prop_lut6_I5_O)        0.124     6.958 r  u_noc/u_net_p/g_router[3].u_router/g_idx[9][3]_i_3/O
                         net (fo=1, routed)           0.797     7.755    u_noc/u_net_p/g_router[3].u_router/g_idx[9][3]_i_3_n_0
    SLICE_X61Y64         LUT6 (Prop_lut6_I0_O)        0.124     7.879 r  u_noc/u_net_p/g_router[3].u_router/g_idx[9][3]_i_1/O
                         net (fo=4, routed)           0.722     8.601    u_noc/u_net_p/g_router[3].u_router/g_idx[9][3]_i_1_n_0
    SLICE_X61Y63         FDCE                                         r  u_noc/u_net_p/g_router[3].u_router/g_idx_reg[9][3]/CE
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        8.000     8.000 r  
                                                      0.000     8.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     8.924    u_noc/u_net_p/g_router[3].u_router/clk
    SLICE_X61Y63         FDCE                                         r  u_noc/u_net_p/g_router[3].u_router/g_idx_reg[9][3]/C
                         clock pessimism              0.000     8.924    
                         clock uncertainty           -0.035     8.889    
    SLICE_X61Y63         FDCE (Setup_fdce_C_CE)      -0.205     8.684    u_noc/u_net_p/g_router[3].u_router/g_idx_reg[9][3]
  -------------------------------------------------------------------
                         required time                          8.684    
                         arrival time                          -8.601    
  -------------------------------------------------------------------
                         slack                                  0.083    

Slack (MET) :             0.097ns  (required time - arrival time)
  Source:                 u_noc/c_en_reg[2][2][6]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][0]/CE
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            8.000ns  (clk rise@8.000ns - clk rise@0.000ns)
  Data Path Delay:        7.650ns  (logic 1.436ns (18.772%)  route 6.214ns (81.228%))
  Logic Levels:           6  (LUT5=1 LUT6=5)
  Clock Path Skew:        -0.049ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns = ( 8.924 - 8.000 ) 
    Source Clock Delay      (SCD):    0.973ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.035ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.071ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.973     0.973    u_noc/clk
    SLICE_X59Y74         FDCE                                         r  u_noc/c_en_reg[2][2][6]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X59Y74         FDCE (Prop_fdce_C_Q)         0.456     1.429 r  u_noc/c_en_reg[2][2][6]/Q
                         net (fo=23, routed)          1.217     2.646    u_noc/u_net_p/g_router[2].u_router/p_en[2]_15[6]
    SLICE_X60Y76         LUT5 (Prop_lut5_I0_O)        0.153     2.799 f  u_noc/u_net_p/g_router[2].u_router/pending[6][6]_i_2/O
                         net (fo=2, routed)           0.934     3.733    u_noc/u_net_p/g_router[2].u_router/pending[6][6]_i_2_n_0
    SLICE_X57Y82         LUT6 (Prop_lut6_I4_O)        0.331     4.064 r  u_noc/u_net_p/g_router[2].u_router/i___89_i_3/O
                         net (fo=1, routed)           0.690     4.754    u_noc/u_net_p/g_router[2].u_router/i___89_i_3_n_0
    SLICE_X61Y78         LUT6 (Prop_lut6_I5_O)        0.124     4.878 f  u_noc/u_net_p/g_router[2].u_router/i___89_i_1/O
                         net (fo=3, routed)           1.032     5.910    u_noc/u_net_p/g_router[2].u_router/i___89_i_1_n_0
    SLICE_X61Y78         LUT6 (Prop_lut6_I1_O)        0.124     6.034 r  u_noc/u_net_p/g_router[2].u_router/i___90_i_1/O
                         net (fo=18, routed)          0.911     6.945    u_noc/u_net_p/g_router[2].u_router/ir[2]_601[1]
    SLICE_X56Y81         LUT6 (Prop_lut6_I2_O)        0.124     7.069 r  u_noc/u_net_p/g_router[2].u_router/g_pos[5][3]_i_6/O
                         net (fo=2, routed)           0.861     7.930    u_noc/u_net_p/g_router[2].u_router/g_pos[5][3]_i_6_n_0
    SLICE_X55Y82         LUT6 (Prop_lut6_I1_O)        0.124     8.054 r  u_noc/u_net_p/g_router[2].u_router/g_idx[5][3]_i_1/O
                         net (fo=4, routed)           0.568     8.623    u_noc/u_net_p/g_router[2].u_router/g_idx[5][3]_i_1_n_0
    SLICE_X54Y82         FDCE                                         r  u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][0]/CE
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        8.000     8.000 r  
                                                      0.000     8.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     8.924    u_noc/u_net_p/g_router[2].u_router/clk
    SLICE_X54Y82         FDCE                                         r  u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][0]/C
                         clock pessimism              0.000     8.924    
                         clock uncertainty           -0.035     8.889    
    SLICE_X54Y82         FDCE (Setup_fdce_C_CE)      -0.169     8.720    u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][0]
  -------------------------------------------------------------------
                         required time                          8.720    
                         arrival time                          -8.623    
  -------------------------------------------------------------------
                         slack                                  0.097    

Slack (MET) :             0.097ns  (required time - arrival time)
  Source:                 u_noc/c_en_reg[2][2][6]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][1]/CE
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            8.000ns  (clk rise@8.000ns - clk rise@0.000ns)
  Data Path Delay:        7.650ns  (logic 1.436ns (18.772%)  route 6.214ns (81.228%))
  Logic Levels:           6  (LUT5=1 LUT6=5)
  Clock Path Skew:        -0.049ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns = ( 8.924 - 8.000 ) 
    Source Clock Delay      (SCD):    0.973ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.035ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.071ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.973     0.973    u_noc/clk
    SLICE_X59Y74         FDCE                                         r  u_noc/c_en_reg[2][2][6]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X59Y74         FDCE (Prop_fdce_C_Q)         0.456     1.429 r  u_noc/c_en_reg[2][2][6]/Q
                         net (fo=23, routed)          1.217     2.646    u_noc/u_net_p/g_router[2].u_router/p_en[2]_15[6]
    SLICE_X60Y76         LUT5 (Prop_lut5_I0_O)        0.153     2.799 f  u_noc/u_net_p/g_router[2].u_router/pending[6][6]_i_2/O
                         net (fo=2, routed)           0.934     3.733    u_noc/u_net_p/g_router[2].u_router/pending[6][6]_i_2_n_0
    SLICE_X57Y82         LUT6 (Prop_lut6_I4_O)        0.331     4.064 r  u_noc/u_net_p/g_router[2].u_router/i___89_i_3/O
                         net (fo=1, routed)           0.690     4.754    u_noc/u_net_p/g_router[2].u_router/i___89_i_3_n_0
    SLICE_X61Y78         LUT6 (Prop_lut6_I5_O)        0.124     4.878 f  u_noc/u_net_p/g_router[2].u_router/i___89_i_1/O
                         net (fo=3, routed)           1.032     5.910    u_noc/u_net_p/g_router[2].u_router/i___89_i_1_n_0
    SLICE_X61Y78         LUT6 (Prop_lut6_I1_O)        0.124     6.034 r  u_noc/u_net_p/g_router[2].u_router/i___90_i_1/O
                         net (fo=18, routed)          0.911     6.945    u_noc/u_net_p/g_router[2].u_router/ir[2]_601[1]
    SLICE_X56Y81         LUT6 (Prop_lut6_I2_O)        0.124     7.069 r  u_noc/u_net_p/g_router[2].u_router/g_pos[5][3]_i_6/O
                         net (fo=2, routed)           0.861     7.930    u_noc/u_net_p/g_router[2].u_router/g_pos[5][3]_i_6_n_0
    SLICE_X55Y82         LUT6 (Prop_lut6_I1_O)        0.124     8.054 r  u_noc/u_net_p/g_router[2].u_router/g_idx[5][3]_i_1/O
                         net (fo=4, routed)           0.568     8.623    u_noc/u_net_p/g_router[2].u_router/g_idx[5][3]_i_1_n_0
    SLICE_X54Y82         FDCE                                         r  u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][1]/CE
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        8.000     8.000 r  
                                                      0.000     8.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     8.924    u_noc/u_net_p/g_router[2].u_router/clk
    SLICE_X54Y82         FDCE                                         r  u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][1]/C
                         clock pessimism              0.000     8.924    
                         clock uncertainty           -0.035     8.889    
    SLICE_X54Y82         FDCE (Setup_fdce_C_CE)      -0.169     8.720    u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][1]
  -------------------------------------------------------------------
                         required time                          8.720    
                         arrival time                          -8.623    
  -------------------------------------------------------------------
                         slack                                  0.097    

Slack (MET) :             0.097ns  (required time - arrival time)
  Source:                 u_noc/c_en_reg[2][2][6]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][2]/CE
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            8.000ns  (clk rise@8.000ns - clk rise@0.000ns)
  Data Path Delay:        7.650ns  (logic 1.436ns (18.772%)  route 6.214ns (81.228%))
  Logic Levels:           6  (LUT5=1 LUT6=5)
  Clock Path Skew:        -0.049ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns = ( 8.924 - 8.000 ) 
    Source Clock Delay      (SCD):    0.973ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.035ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.071ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.973     0.973    u_noc/clk
    SLICE_X59Y74         FDCE                                         r  u_noc/c_en_reg[2][2][6]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X59Y74         FDCE (Prop_fdce_C_Q)         0.456     1.429 r  u_noc/c_en_reg[2][2][6]/Q
                         net (fo=23, routed)          1.217     2.646    u_noc/u_net_p/g_router[2].u_router/p_en[2]_15[6]
    SLICE_X60Y76         LUT5 (Prop_lut5_I0_O)        0.153     2.799 f  u_noc/u_net_p/g_router[2].u_router/pending[6][6]_i_2/O
                         net (fo=2, routed)           0.934     3.733    u_noc/u_net_p/g_router[2].u_router/pending[6][6]_i_2_n_0
    SLICE_X57Y82         LUT6 (Prop_lut6_I4_O)        0.331     4.064 r  u_noc/u_net_p/g_router[2].u_router/i___89_i_3/O
                         net (fo=1, routed)           0.690     4.754    u_noc/u_net_p/g_router[2].u_router/i___89_i_3_n_0
    SLICE_X61Y78         LUT6 (Prop_lut6_I5_O)        0.124     4.878 f  u_noc/u_net_p/g_router[2].u_router/i___89_i_1/O
                         net (fo=3, routed)           1.032     5.910    u_noc/u_net_p/g_router[2].u_router/i___89_i_1_n_0
    SLICE_X61Y78         LUT6 (Prop_lut6_I1_O)        0.124     6.034 r  u_noc/u_net_p/g_router[2].u_router/i___90_i_1/O
                         net (fo=18, routed)          0.911     6.945    u_noc/u_net_p/g_router[2].u_router/ir[2]_601[1]
    SLICE_X56Y81         LUT6 (Prop_lut6_I2_O)        0.124     7.069 r  u_noc/u_net_p/g_router[2].u_router/g_pos[5][3]_i_6/O
                         net (fo=2, routed)           0.861     7.930    u_noc/u_net_p/g_router[2].u_router/g_pos[5][3]_i_6_n_0
    SLICE_X55Y82         LUT6 (Prop_lut6_I1_O)        0.124     8.054 r  u_noc/u_net_p/g_router[2].u_router/g_idx[5][3]_i_1/O
                         net (fo=4, routed)           0.568     8.623    u_noc/u_net_p/g_router[2].u_router/g_idx[5][3]_i_1_n_0
    SLICE_X54Y82         FDCE                                         r  u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][2]/CE
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        8.000     8.000 r  
                                                      0.000     8.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     8.924    u_noc/u_net_p/g_router[2].u_router/clk
    SLICE_X54Y82         FDCE                                         r  u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][2]/C
                         clock pessimism              0.000     8.924    
                         clock uncertainty           -0.035     8.889    
    SLICE_X54Y82         FDCE (Setup_fdce_C_CE)      -0.169     8.720    u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][2]
  -------------------------------------------------------------------
                         required time                          8.720    
                         arrival time                          -8.623    
  -------------------------------------------------------------------
                         slack                                  0.097    

Slack (MET) :             0.097ns  (required time - arrival time)
  Source:                 u_noc/c_en_reg[2][2][6]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][3]/CE
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Setup (Max at Slow Process Corner)
  Requirement:            8.000ns  (clk rise@8.000ns - clk rise@0.000ns)
  Data Path Delay:        7.650ns  (logic 1.436ns (18.772%)  route 6.214ns (81.228%))
  Logic Levels:           6  (LUT5=1 LUT6=5)
  Clock Path Skew:        -0.049ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns = ( 8.924 - 8.000 ) 
    Source Clock Delay      (SCD):    0.973ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.035ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.071ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.973     0.973    u_noc/clk
    SLICE_X59Y74         FDCE                                         r  u_noc/c_en_reg[2][2][6]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X59Y74         FDCE (Prop_fdce_C_Q)         0.456     1.429 r  u_noc/c_en_reg[2][2][6]/Q
                         net (fo=23, routed)          1.217     2.646    u_noc/u_net_p/g_router[2].u_router/p_en[2]_15[6]
    SLICE_X60Y76         LUT5 (Prop_lut5_I0_O)        0.153     2.799 f  u_noc/u_net_p/g_router[2].u_router/pending[6][6]_i_2/O
                         net (fo=2, routed)           0.934     3.733    u_noc/u_net_p/g_router[2].u_router/pending[6][6]_i_2_n_0
    SLICE_X57Y82         LUT6 (Prop_lut6_I4_O)        0.331     4.064 r  u_noc/u_net_p/g_router[2].u_router/i___89_i_3/O
                         net (fo=1, routed)           0.690     4.754    u_noc/u_net_p/g_router[2].u_router/i___89_i_3_n_0
    SLICE_X61Y78         LUT6 (Prop_lut6_I5_O)        0.124     4.878 f  u_noc/u_net_p/g_router[2].u_router/i___89_i_1/O
                         net (fo=3, routed)           1.032     5.910    u_noc/u_net_p/g_router[2].u_router/i___89_i_1_n_0
    SLICE_X61Y78         LUT6 (Prop_lut6_I1_O)        0.124     6.034 r  u_noc/u_net_p/g_router[2].u_router/i___90_i_1/O
                         net (fo=18, routed)          0.911     6.945    u_noc/u_net_p/g_router[2].u_router/ir[2]_601[1]
    SLICE_X56Y81         LUT6 (Prop_lut6_I2_O)        0.124     7.069 r  u_noc/u_net_p/g_router[2].u_router/g_pos[5][3]_i_6/O
                         net (fo=2, routed)           0.861     7.930    u_noc/u_net_p/g_router[2].u_router/g_pos[5][3]_i_6_n_0
    SLICE_X55Y82         LUT6 (Prop_lut6_I1_O)        0.124     8.054 r  u_noc/u_net_p/g_router[2].u_router/g_idx[5][3]_i_1/O
                         net (fo=4, routed)           0.568     8.623    u_noc/u_net_p/g_router[2].u_router/g_idx[5][3]_i_1_n_0
    SLICE_X54Y82         FDCE                                         r  u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][3]/CE
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        8.000     8.000 r  
                                                      0.000     8.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     8.924    u_noc/u_net_p/g_router[2].u_router/clk
    SLICE_X54Y82         FDCE                                         r  u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][3]/C
                         clock pessimism              0.000     8.924    
                         clock uncertainty           -0.035     8.889    
    SLICE_X54Y82         FDCE (Setup_fdce_C_CE)      -0.169     8.720    u_noc/u_net_p/g_router[2].u_router/g_idx_reg[5][3]
  -------------------------------------------------------------------
                         required time                          8.720    
                         arrival time                          -8.623    
  -------------------------------------------------------------------
                         slack                                  0.097    





Min Delay Paths
--------------------------------------------------------------------------------------
Slack (MET) :             0.025ns  (arrival time - required time)
  Source:                 u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMA/WADR3
                            (rising edge-triggered cell RAMD64E clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Hold (Min at Fast Process Corner)
  Requirement:            0.000ns  (clk rise@0.000ns - clk rise@0.000ns)
  Data Path Delay:        0.286ns  (logic 0.141ns (49.277%)  route 0.145ns (50.723%))
  Logic Levels:           0  
  Clock Path Skew:        0.022ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.410ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.410     0.410    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/clk
    SLICE_X81Y34         FDCE                                         r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X81Y34         FDCE (Prop_fdce_C_Q)         0.141     0.551 r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/Q
                         net (fo=35, routed)          0.145     0.696    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/ADDRD3
    SLICE_X80Y34         RAMD64E                                      r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMA/WADR3
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/WCLK
    SLICE_X80Y34         RAMD64E                                      r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMA/CLK
                         clock pessimism              0.000     0.432    
    SLICE_X80Y34         RAMD64E (Hold_ramd64e_CLK_WADR3)
                                                      0.240     0.672    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMA
  -------------------------------------------------------------------
                         required time                         -0.672    
                         arrival time                           0.696    
  -------------------------------------------------------------------
                         slack                                  0.025    

Slack (MET) :             0.025ns  (arrival time - required time)
  Source:                 u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMB/WADR3
                            (rising edge-triggered cell RAMD64E clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Hold (Min at Fast Process Corner)
  Requirement:            0.000ns  (clk rise@0.000ns - clk rise@0.000ns)
  Data Path Delay:        0.286ns  (logic 0.141ns (49.277%)  route 0.145ns (50.723%))
  Logic Levels:           0  
  Clock Path Skew:        0.022ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.410ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.410     0.410    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/clk
    SLICE_X81Y34         FDCE                                         r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X81Y34         FDCE (Prop_fdce_C_Q)         0.141     0.551 r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/Q
                         net (fo=35, routed)          0.145     0.696    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/ADDRD3
    SLICE_X80Y34         RAMD64E                                      r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMB/WADR3
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/WCLK
    SLICE_X80Y34         RAMD64E                                      r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMB/CLK
                         clock pessimism              0.000     0.432    
    SLICE_X80Y34         RAMD64E (Hold_ramd64e_CLK_WADR3)
                                                      0.240     0.672    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMB
  -------------------------------------------------------------------
                         required time                         -0.672    
                         arrival time                           0.696    
  -------------------------------------------------------------------
                         slack                                  0.025    

Slack (MET) :             0.025ns  (arrival time - required time)
  Source:                 u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMC/WADR3
                            (rising edge-triggered cell RAMD64E clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Hold (Min at Fast Process Corner)
  Requirement:            0.000ns  (clk rise@0.000ns - clk rise@0.000ns)
  Data Path Delay:        0.286ns  (logic 0.141ns (49.277%)  route 0.145ns (50.723%))
  Logic Levels:           0  
  Clock Path Skew:        0.022ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.410ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.410     0.410    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/clk
    SLICE_X81Y34         FDCE                                         r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X81Y34         FDCE (Prop_fdce_C_Q)         0.141     0.551 r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/Q
                         net (fo=35, routed)          0.145     0.696    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/ADDRD3
    SLICE_X80Y34         RAMD64E                                      r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMC/WADR3
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/WCLK
    SLICE_X80Y34         RAMD64E                                      r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMC/CLK
                         clock pessimism              0.000     0.432    
    SLICE_X80Y34         RAMD64E (Hold_ramd64e_CLK_WADR3)
                                                      0.240     0.672    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMC
  -------------------------------------------------------------------
                         required time                         -0.672    
                         arrival time                           0.696    
  -------------------------------------------------------------------
                         slack                                  0.025    

Slack (MET) :             0.025ns  (arrival time - required time)
  Source:                 u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMD/WADR3
                            (rising edge-triggered cell RAMD64E clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Hold (Min at Fast Process Corner)
  Requirement:            0.000ns  (clk rise@0.000ns - clk rise@0.000ns)
  Data Path Delay:        0.286ns  (logic 0.141ns (49.277%)  route 0.145ns (50.723%))
  Logic Levels:           0  
  Clock Path Skew:        0.022ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.410ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.410     0.410    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/clk
    SLICE_X81Y34         FDCE                                         r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X81Y34         FDCE (Prop_fdce_C_Q)         0.141     0.551 r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ctrl/ifmap_cnt_reg[3]/Q
                         net (fo=35, routed)          0.145     0.696    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/ADDRD3
    SLICE_X80Y34         RAMD64E                                      r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMD/WADR3
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/WCLK
    SLICE_X80Y34         RAMD64E                                      r  u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMD/CLK
                         clock pessimism              0.000     0.432    
    SLICE_X80Y34         RAMD64E (Hold_ramd64e_CLK_WADR3)
                                                      0.240     0.672    u_noc/g_r[3].g_k[3].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMD
  -------------------------------------------------------------------
                         required time                         -0.672    
                         arrival time                           0.696    
  -------------------------------------------------------------------
                         slack                                  0.025    

Slack (MET) :             0.025ns  (arrival time - required time)
  Source:                 u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMA/WADR3
                            (rising edge-triggered cell RAMD64E clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Hold (Min at Fast Process Corner)
  Requirement:            0.000ns  (clk rise@0.000ns - clk rise@0.000ns)
  Data Path Delay:        0.286ns  (logic 0.141ns (49.266%)  route 0.145ns (50.734%))
  Logic Levels:           0  
  Clock Path Skew:        0.022ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.410ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.410     0.410    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/clk
    SLICE_X15Y38         FDCE                                         r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X15Y38         FDCE (Prop_fdce_C_Q)         0.141     0.551 r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/Q
                         net (fo=35, routed)          0.145     0.696    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/ADDRD3
    SLICE_X14Y38         RAMD64E                                      r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMA/WADR3
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/WCLK
    SLICE_X14Y38         RAMD64E                                      r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMA/CLK
                         clock pessimism              0.000     0.432    
    SLICE_X14Y38         RAMD64E (Hold_ramd64e_CLK_WADR3)
                                                      0.240     0.672    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMA
  -------------------------------------------------------------------
                         required time                         -0.672    
                         arrival time                           0.696    
  -------------------------------------------------------------------
                         slack                                  0.025    

Slack (MET) :             0.025ns  (arrival time - required time)
  Source:                 u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMB/WADR3
                            (rising edge-triggered cell RAMD64E clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Hold (Min at Fast Process Corner)
  Requirement:            0.000ns  (clk rise@0.000ns - clk rise@0.000ns)
  Data Path Delay:        0.286ns  (logic 0.141ns (49.266%)  route 0.145ns (50.734%))
  Logic Levels:           0  
  Clock Path Skew:        0.022ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.410ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.410     0.410    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/clk
    SLICE_X15Y38         FDCE                                         r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X15Y38         FDCE (Prop_fdce_C_Q)         0.141     0.551 r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/Q
                         net (fo=35, routed)          0.145     0.696    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/ADDRD3
    SLICE_X14Y38         RAMD64E                                      r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMB/WADR3
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/WCLK
    SLICE_X14Y38         RAMD64E                                      r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMB/CLK
                         clock pessimism              0.000     0.432    
    SLICE_X14Y38         RAMD64E (Hold_ramd64e_CLK_WADR3)
                                                      0.240     0.672    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMB
  -------------------------------------------------------------------
                         required time                         -0.672    
                         arrival time                           0.696    
  -------------------------------------------------------------------
                         slack                                  0.025    

Slack (MET) :             0.025ns  (arrival time - required time)
  Source:                 u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMC/WADR3
                            (rising edge-triggered cell RAMD64E clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Hold (Min at Fast Process Corner)
  Requirement:            0.000ns  (clk rise@0.000ns - clk rise@0.000ns)
  Data Path Delay:        0.286ns  (logic 0.141ns (49.266%)  route 0.145ns (50.734%))
  Logic Levels:           0  
  Clock Path Skew:        0.022ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.410ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.410     0.410    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/clk
    SLICE_X15Y38         FDCE                                         r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X15Y38         FDCE (Prop_fdce_C_Q)         0.141     0.551 r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/Q
                         net (fo=35, routed)          0.145     0.696    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/ADDRD3
    SLICE_X14Y38         RAMD64E                                      r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMC/WADR3
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/WCLK
    SLICE_X14Y38         RAMD64E                                      r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMC/CLK
                         clock pessimism              0.000     0.432    
    SLICE_X14Y38         RAMD64E (Hold_ramd64e_CLK_WADR3)
                                                      0.240     0.672    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMC
  -------------------------------------------------------------------
                         required time                         -0.672    
                         arrival time                           0.696    
  -------------------------------------------------------------------
                         slack                                  0.025    

Slack (MET) :             0.025ns  (arrival time - required time)
  Source:                 u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMD/WADR3
                            (rising edge-triggered cell RAMD64E clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Hold (Min at Fast Process Corner)
  Requirement:            0.000ns  (clk rise@0.000ns - clk rise@0.000ns)
  Data Path Delay:        0.286ns  (logic 0.141ns (49.266%)  route 0.145ns (50.734%))
  Logic Levels:           0  
  Clock Path Skew:        0.022ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.410ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.410     0.410    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/clk
    SLICE_X15Y38         FDCE                                         r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X15Y38         FDCE (Prop_fdce_C_Q)         0.141     0.551 r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ctrl/ifmap_cnt_reg[3]/Q
                         net (fo=35, routed)          0.145     0.696    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/ADDRD3
    SLICE_X14Y38         RAMD64E                                      r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMD/WADR3
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/WCLK
    SLICE_X14Y38         RAMD64E                                      r  u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMD/CLK
                         clock pessimism              0.000     0.432    
    SLICE_X14Y38         RAMD64E (Hold_ramd64e_CLK_WADR3)
                                                      0.240     0.672    u_noc/g_r[0].g_k[1].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_64_127_3_5/RAMD
  -------------------------------------------------------------------
                         required time                         -0.672    
                         arrival time                           0.696    
  -------------------------------------------------------------------
                         slack                                  0.025    

Slack (MET) :             0.037ns  (arrival time - required time)
  Source:                 u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/wr_ptr_reg[3]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/RAMA/WADR3
                            (rising edge-triggered cell RAMD32 clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Hold (Min at Fast Process Corner)
  Requirement:            0.000ns  (clk rise@0.000ns - clk rise@0.000ns)
  Data Path Delay:        0.299ns  (logic 0.141ns (47.220%)  route 0.158ns (52.780%))
  Logic Levels:           0  
  Clock Path Skew:        0.022ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.410ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.410     0.410    u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/clk
    SLICE_X15Y28         FDCE                                         r  u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/wr_ptr_reg[3]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X15Y28         FDCE (Prop_fdce_C_Q)         0.141     0.551 r  u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/wr_ptr_reg[3]/Q
                         net (fo=34, routed)          0.158     0.709    u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/ADDRD3
    SLICE_X14Y28         RAMD32                                       r  u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/RAMA/WADR3
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/WCLK
    SLICE_X14Y28         RAMD32                                       r  u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/RAMA/CLK
                         clock pessimism              0.000     0.432    
    SLICE_X14Y28         RAMD32 (Hold_ramd32_CLK_WADR3)
                                                      0.240     0.672    u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/RAMA
  -------------------------------------------------------------------
                         required time                         -0.672    
                         arrival time                           0.709    
  -------------------------------------------------------------------
                         slack                                  0.037    

Slack (MET) :             0.037ns  (arrival time - required time)
  Source:                 u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/wr_ptr_reg[3]/C
                            (rising edge-triggered cell FDCE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/RAMA_D1/WADR3
                            (rising edge-triggered cell RAMD32 clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             clk
  Path Type:              Hold (Min at Fast Process Corner)
  Requirement:            0.000ns  (clk rise@0.000ns - clk rise@0.000ns)
  Data Path Delay:        0.299ns  (logic 0.141ns (47.220%)  route 0.158ns (52.780%))
  Logic Levels:           0  
  Clock Path Skew:        0.022ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.410ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.410     0.410    u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/clk
    SLICE_X15Y28         FDCE                                         r  u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/wr_ptr_reg[3]/C
  -------------------------------------------------------------------    -------------------
    SLICE_X15Y28         FDCE (Prop_fdce_C_Q)         0.141     0.551 r  u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/wr_ptr_reg[3]/Q
                         net (fo=34, routed)          0.158     0.709    u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/ADDRD3
    SLICE_X14Y28         RAMD32                                       r  u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/RAMA_D1/WADR3
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/WCLK
    SLICE_X14Y28         RAMD32                                       r  u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/RAMA_D1/CLK
                         clock pessimism              0.000     0.432    
    SLICE_X14Y28         RAMD32 (Hold_ramd32_CLK_WADR3)
                                                      0.240     0.672    u_noc/g_r[0].g_k[2].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_psum_fifo/mem_reg_0_31_6_11/RAMA_D1
  -------------------------------------------------------------------
                         required time                         -0.672    
                         arrival time                           0.709    
  -------------------------------------------------------------------
                         slack                                  0.037    





Pulse Width Checks
--------------------------------------------------------------------------------------
Clock Name:         clk
Waveform(ns):       { 0.000 4.000 }
Period(ns):         8.000
Sources:            { clk }

Check Type        Corner  Lib Pin             Reference Pin  Required(ns)  Actual(ns)  Slack(ns)  Location     Pin
Min Period        n/a     RAMB18E1/CLKARDCLK  n/a            2.944         8.000       5.056      RAMB18_X1Y0  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_kernel_spad/kernel_sp_reg/CLKARDCLK
Min Period        n/a     RAMB18E1/CLKARDCLK  n/a            2.944         8.000       5.056      RAMB18_X1Y2  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_psum_spad/psum_sp_reg/CLKARDCLK
Min Period        n/a     RAMB18E1/CLKBWRCLK  n/a            2.944         8.000       5.056      RAMB18_X1Y2  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_psum_spad/psum_sp_reg/CLKBWRCLK
Min Period        n/a     RAMB18E1/CLKARDCLK  n/a            2.944         8.000       5.056      RAMB18_X0Y2  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_kernel_spad/kernel_sp_reg/CLKARDCLK
Min Period        n/a     RAMB18E1/CLKARDCLK  n/a            2.944         8.000       5.056      RAMB18_X0Y4  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_psum_spad/psum_sp_reg/CLKARDCLK
Min Period        n/a     RAMB18E1/CLKBWRCLK  n/a            2.944         8.000       5.056      RAMB18_X0Y4  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[1].u_pe/u_psum_spad/psum_sp_reg/CLKBWRCLK
Min Period        n/a     RAMB18E1/CLKARDCLK  n/a            2.944         8.000       5.056      RAMB18_X1Y1  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_kernel_spad/kernel_sp_reg/CLKARDCLK
Min Period        n/a     RAMB18E1/CLKARDCLK  n/a            2.944         8.000       5.056      RAMB18_X1Y3  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_psum_spad/psum_sp_reg/CLKARDCLK
Min Period        n/a     RAMB18E1/CLKBWRCLK  n/a            2.944         8.000       5.056      RAMB18_X1Y3  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[1].gen_pe_col[0].u_pe/u_psum_spad/psum_sp_reg/CLKBWRCLK
Min Period        n/a     RAMB18E1/CLKARDCLK  n/a            2.944         8.000       5.056      RAMB18_X0Y3  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[1].gen_pe_col[1].u_pe/u_kernel_spad/kernel_sp_reg/CLKARDCLK
Low Pulse Width   Slow    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMA/CLK
Low Pulse Width   Fast    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMA/CLK
Low Pulse Width   Slow    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMB/CLK
Low Pulse Width   Fast    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMB/CLK
Low Pulse Width   Slow    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMC/CLK
Low Pulse Width   Fast    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMC/CLK
Low Pulse Width   Slow    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMD/CLK
Low Pulse Width   Fast    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMD/CLK
Low Pulse Width   Slow    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y7  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_3_5/RAMA/CLK
Low Pulse Width   Fast    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y7  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_3_5/RAMA/CLK
High Pulse Width  Slow    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMA/CLK
High Pulse Width  Fast    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMA/CLK
High Pulse Width  Slow    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMB/CLK
High Pulse Width  Fast    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMB/CLK
High Pulse Width  Slow    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMC/CLK
High Pulse Width  Fast    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMC/CLK
High Pulse Width  Slow    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMD/CLK
High Pulse Width  Fast    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y5  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_0_2/RAMD/CLK
High Pulse Width  Slow    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y7  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_3_5/RAMA/CLK
High Pulse Width  Fast    RAMD64E/CLK         n/a            1.250         4.000       2.750      SLICE_X38Y7  u_noc/g_r[0].g_k[0].u_node/u_cluster/gen_pe_row[0].gen_pe_col[0].u_pe/u_ifmap_spad/ifmap_sp_reg_0_63_3_5/RAMA/CLK



--------------------------------------------------------------------------------------
Path Group:  (none)
From Clock:  clk
  To Clock:  

Max Delay             1 Endpoint
Min Delay             1 Endpoint
--------------------------------------------------------------------------------------


Max Delay Paths
--------------------------------------------------------------------------------------
Slack:                    inf
  Source:                 dout_reg/C
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            dout
                            (output port)
  Path Group:             (none)
  Path Type:              Max at Slow Process Corner
  Data Path Delay:        1.491ns  (logic 0.518ns (34.742%)  route 0.973ns (65.258%))
  Logic Levels:           0  
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.973     0.973    clk
    SLICE_X46Y64         FDRE                                         r  dout_reg/C
  -------------------------------------------------------------------    -------------------
    SLICE_X46Y64         FDRE (Prop_fdre_C_Q)         0.518     1.491 r  dout_reg/Q
                         net (fo=0)                   0.973     2.464    dout
                                                                      r  dout (OUT)
  -------------------------------------------------------------------    -------------------





Min Delay Paths
--------------------------------------------------------------------------------------
Slack:                    inf
  Source:                 dout_reg/C
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Destination:            dout
                            (output port)
  Path Group:             (none)
  Path Type:              Min at Fast Process Corner
  Data Path Delay:        0.574ns  (logic 0.164ns (28.565%)  route 0.410ns (71.435%))
  Logic Levels:           0  
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.410     0.410    clk
    SLICE_X46Y64         FDRE                                         r  dout_reg/C
  -------------------------------------------------------------------    -------------------
    SLICE_X46Y64         FDRE (Prop_fdre_C_Q)         0.164     0.574 r  dout_reg/Q
                         net (fo=0)                   0.410     0.984    dout
                                                                      r  dout (OUT)
  -------------------------------------------------------------------    -------------------





--------------------------------------------------------------------------------------
Path Group:  (none)
From Clock:  
  To Clock:  clk

Max Delay         19973 Endpoints
Min Delay         19973 Endpoints
--------------------------------------------------------------------------------------


Max Delay Paths
--------------------------------------------------------------------------------------
Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[0]/S
                            (rising edge-triggered cell FDSE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Setup (Max at Slow Process Corner)
  Data Path Delay:        0.973ns  (logic 0.000ns (0.000%)  route 0.973ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.924ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.973     0.973    rst
    SLICE_X32Y83         FDSE                                         r  lfsr_reg[0]/S
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     0.924    clk
    SLICE_X32Y83         FDSE                                         r  lfsr_reg[0]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[1000]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Setup (Max at Slow Process Corner)
  Data Path Delay:        0.973ns  (logic 0.000ns (0.000%)  route 0.973ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.924ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.973     0.973    rst
    SLICE_X32Y83         FDRE                                         r  lfsr_reg[1000]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     0.924    clk
    SLICE_X32Y83         FDRE                                         r  lfsr_reg[1000]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[100]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Setup (Max at Slow Process Corner)
  Data Path Delay:        0.973ns  (logic 0.000ns (0.000%)  route 0.973ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.924ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.973     0.973    rst
    SLICE_X67Y62         FDRE                                         r  lfsr_reg[100]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     0.924    clk
    SLICE_X67Y62         FDRE                                         r  lfsr_reg[100]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[101]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Setup (Max at Slow Process Corner)
  Data Path Delay:        0.973ns  (logic 0.000ns (0.000%)  route 0.973ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.924ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.973     0.973    rst
    SLICE_X72Y57         FDRE                                         r  lfsr_reg[101]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     0.924    clk
    SLICE_X72Y57         FDRE                                         r  lfsr_reg[101]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[1022]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Setup (Max at Slow Process Corner)
  Data Path Delay:        0.973ns  (logic 0.000ns (0.000%)  route 0.973ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.924ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.973     0.973    rst
    SLICE_X31Y84         FDRE                                         r  lfsr_reg[1022]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     0.924    clk
    SLICE_X31Y84         FDRE                                         r  lfsr_reg[1022]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[1023]/S
                            (rising edge-triggered cell FDSE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Setup (Max at Slow Process Corner)
  Data Path Delay:        0.973ns  (logic 0.000ns (0.000%)  route 0.973ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.924ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.973     0.973    rst
    SLICE_X32Y83         FDSE                                         r  lfsr_reg[1023]/S
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     0.924    clk
    SLICE_X32Y83         FDSE                                         r  lfsr_reg[1023]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[102]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Setup (Max at Slow Process Corner)
  Data Path Delay:        0.973ns  (logic 0.000ns (0.000%)  route 0.973ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.924ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.973     0.973    rst
    SLICE_X67Y66         FDRE                                         r  lfsr_reg[102]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     0.924    clk
    SLICE_X67Y66         FDRE                                         r  lfsr_reg[102]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[103]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Setup (Max at Slow Process Corner)
  Data Path Delay:        0.973ns  (logic 0.000ns (0.000%)  route 0.973ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.924ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.973     0.973    rst
    SLICE_X71Y51         FDRE                                         r  lfsr_reg[103]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     0.924    clk
    SLICE_X71Y51         FDRE                                         r  lfsr_reg[103]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[104]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Setup (Max at Slow Process Corner)
  Data Path Delay:        0.973ns  (logic 0.000ns (0.000%)  route 0.973ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.924ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.973     0.973    rst
    SLICE_X66Y65         FDRE                                         r  lfsr_reg[104]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     0.924    clk
    SLICE_X66Y65         FDRE                                         r  lfsr_reg[104]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[105]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Setup (Max at Slow Process Corner)
  Data Path Delay:        0.973ns  (logic 0.000ns (0.000%)  route 0.973ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.924ns (DCD - SCD + CPR)
    Destination Clock Delay (DCD):    0.924ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    0.000ns
  Clock Uncertainty:      0.025ns  ((TSJ^2 + TIJ^2)^1/2 + DJ) / 2 + PE
    Total System Jitter     (TSJ):    0.050ns
    Total Input Jitter      (TIJ):    0.000ns
    Discrete Jitter          (DJ):    0.000ns
    Phase Error              (PE):    0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.973     0.973    rst
    SLICE_X66Y65         FDRE                                         r  lfsr_reg[105]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.924     0.924    clk
    SLICE_X66Y65         FDRE                                         r  lfsr_reg[105]/C





Min Delay Paths
--------------------------------------------------------------------------------------
Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[0]/S
                            (rising edge-triggered cell FDSE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Hold (Min at Fast Process Corner)
  Data Path Delay:        0.410ns  (logic 0.000ns (0.000%)  route 0.410ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.432ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.410     0.410    rst
    SLICE_X32Y83         FDSE                                         r  lfsr_reg[0]/S
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    clk
    SLICE_X32Y83         FDSE                                         r  lfsr_reg[0]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[1000]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Hold (Min at Fast Process Corner)
  Data Path Delay:        0.410ns  (logic 0.000ns (0.000%)  route 0.410ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.432ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.410     0.410    rst
    SLICE_X32Y83         FDRE                                         r  lfsr_reg[1000]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    clk
    SLICE_X32Y83         FDRE                                         r  lfsr_reg[1000]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[100]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Hold (Min at Fast Process Corner)
  Data Path Delay:        0.410ns  (logic 0.000ns (0.000%)  route 0.410ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.432ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.410     0.410    rst
    SLICE_X67Y62         FDRE                                         r  lfsr_reg[100]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    clk
    SLICE_X67Y62         FDRE                                         r  lfsr_reg[100]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[101]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Hold (Min at Fast Process Corner)
  Data Path Delay:        0.410ns  (logic 0.000ns (0.000%)  route 0.410ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.432ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.410     0.410    rst
    SLICE_X72Y57         FDRE                                         r  lfsr_reg[101]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    clk
    SLICE_X72Y57         FDRE                                         r  lfsr_reg[101]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[1022]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Hold (Min at Fast Process Corner)
  Data Path Delay:        0.410ns  (logic 0.000ns (0.000%)  route 0.410ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.432ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.410     0.410    rst
    SLICE_X31Y84         FDRE                                         r  lfsr_reg[1022]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    clk
    SLICE_X31Y84         FDRE                                         r  lfsr_reg[1022]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[1023]/S
                            (rising edge-triggered cell FDSE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Hold (Min at Fast Process Corner)
  Data Path Delay:        0.410ns  (logic 0.000ns (0.000%)  route 0.410ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.432ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.410     0.410    rst
    SLICE_X32Y83         FDSE                                         r  lfsr_reg[1023]/S
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    clk
    SLICE_X32Y83         FDSE                                         r  lfsr_reg[1023]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[102]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Hold (Min at Fast Process Corner)
  Data Path Delay:        0.410ns  (logic 0.000ns (0.000%)  route 0.410ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.432ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.410     0.410    rst
    SLICE_X67Y66         FDRE                                         r  lfsr_reg[102]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    clk
    SLICE_X67Y66         FDRE                                         r  lfsr_reg[102]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[103]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Hold (Min at Fast Process Corner)
  Data Path Delay:        0.410ns  (logic 0.000ns (0.000%)  route 0.410ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.432ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.410     0.410    rst
    SLICE_X71Y51         FDRE                                         r  lfsr_reg[103]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    clk
    SLICE_X71Y51         FDRE                                         r  lfsr_reg[103]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[104]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Hold (Min at Fast Process Corner)
  Data Path Delay:        0.410ns  (logic 0.000ns (0.000%)  route 0.410ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.432ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.410     0.410    rst
    SLICE_X66Y65         FDRE                                         r  lfsr_reg[104]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    clk
    SLICE_X66Y65         FDRE                                         r  lfsr_reg[104]/C

Slack:                    inf
  Source:                 rst
                            (input port)
  Destination:            lfsr_reg[105]/R
                            (rising edge-triggered cell FDRE clocked by clk  {rise@0.000ns fall@4.000ns period=8.000ns})
  Path Group:             (none)
  Path Type:              Hold (Min at Fast Process Corner)
  Data Path Delay:        0.410ns  (logic 0.000ns (0.000%)  route 0.410ns (100.000%))
  Logic Levels:           0  
  Clock Path Skew:        0.432ns (DCD - SCD - CPR)
    Destination Clock Delay (DCD):    0.432ns
    Source Clock Delay      (SCD):    0.000ns
    Clock Pessimism Removal (CPR):    -0.000ns

    Location             Delay type                Incr(ns)  Path(ns)    Netlist Resource(s)
  -------------------------------------------------------------------    -------------------
                                                      0.000     0.000 r  rst (IN)
                         net (fo=19972, unset)        0.410     0.410    rst
    SLICE_X66Y65         FDRE                                         r  lfsr_reg[105]/R
  -------------------------------------------------------------------    -------------------

                         (clock clk rise edge)        0.000     0.000 r  
                                                      0.000     0.000 r  clk (IN)
                         net (fo=27235, unset)        0.432     0.432    clk
    SLICE_X66Y65         FDRE                                         r  lfsr_reg[105]/C





 
