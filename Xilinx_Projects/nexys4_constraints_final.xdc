## ============================================================
## Nexys 4 Constraints — Verified from Reference Manual Fig 16
## ============================================================

## Clock 100 MHz — Section 5, pin E3
set_property PACKAGE_PIN E3  [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

## Reset — BTNC, pin E16 (Fig 16)
set_property PACKAGE_PIN E16 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## Player 1 — BTNL, pin T16 (Fig 16)
set_property PACKAGE_PIN T16 [get_ports btn_p1_raw]
set_property IOSTANDARD LVCMOS33 [get_ports btn_p1_raw]

## Player 2 — BTNR, pin R10 (Fig 16)
set_property PACKAGE_PIN R10 [get_ports btn_p2_raw]
set_property IOSTANDARD LVCMOS33 [get_ports btn_p2_raw]

## 7-Segment Cathodes — Fig 16, Section 9.1
## {CA, CB, CC, CD, CE, CF, CG} = seg[6:0]
set_property PACKAGE_PIN L3  [get_ports {seg[0]}]
set_property PACKAGE_PIN N1  [get_ports {seg[1]}]
set_property PACKAGE_PIN L5  [get_ports {seg[2]}]
set_property PACKAGE_PIN L4  [get_ports {seg[3]}]
set_property PACKAGE_PIN K3  [get_ports {seg[4]}]
set_property PACKAGE_PIN M2  [get_ports {seg[5]}]
set_property PACKAGE_PIN L6  [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

## 7-Segment Anodes AN7–AN0 — Fig 16, Section 9.1
## AN7=M1, AN6=L1, AN5=N4, AN4=N2, AN3=N5, AN2=M3, AN1=M6, AN0=N6
set_property PACKAGE_PIN N6  [get_ports {an[0]}]
set_property PACKAGE_PIN M6  [get_ports {an[1]}]
set_property PACKAGE_PIN M3  [get_ports {an[2]}]
set_property PACKAGE_PIN N5  [get_ports {an[3]}]
set_property PACKAGE_PIN N2  [get_ports {an[4]}]
set_property PACKAGE_PIN N4  [get_ports {an[5]}]
set_property PACKAGE_PIN L1  [get_ports {an[6]}]
set_property PACKAGE_PIN M1  [get_ports {an[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[7]}]

## LEDs — LD0, LD1, LD2 from Fig 16
set_property PACKAGE_PIN T8  [get_ports led_p1]
set_property PACKAGE_PIN V9  [get_ports led_p2]
set_property PACKAGE_PIN R8  [get_ports led_win]
set_property IOSTANDARD LVCMOS33 [get_ports led_p1]
set_property IOSTANDARD LVCMOS33 [get_ports led_p2]
set_property IOSTANDARD LVCMOS33 [get_ports led_win]
