EESchema Schematic File Version 4
LIBS:dmgplus-cache
EELAYER 26 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 3 6
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L gb_lcdflat:GB_LCD_FLAT U6
U 1 1 5B752FDC
P 8000 2900
F 0 "U6" H 8831 1953 60  0000 L CNN
F 1 "GB_LCD_FLAT" H 8831 1847 60  0000 L CNN
F 2 "dmg_footprints:fpc_conn_21pin" H 8000 2900 50  0001 C CNN
F 3 "" H 8000 2900 50  0001 C CNN
	1    8000 2900
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR036
U 1 1 5B753081
P 7900 5050
F 0 "#PWR036" H 7900 4800 50  0001 C CNN
F 1 "GND" H 7905 4877 50  0000 C CNN
F 2 "" H 7900 5050 50  0001 C CNN
F 3 "" H 7900 5050 50  0001 C CNN
	1    7900 5050
	1    0    0    -1  
$EndComp
Wire Wire Line
	8000 2900 7900 2900
Wire Wire Line
	7900 2900 7900 3800
Wire Wire Line
	8000 4900 7900 4900
Connection ~ 7900 4900
Wire Wire Line
	7900 4900 7900 5050
Wire Wire Line
	8000 3800 7900 3800
Connection ~ 7900 3800
Wire Wire Line
	7900 3800 7900 4900
Wire Wire Line
	7700 3000 8000 3000
Wire Wire Line
	8000 3100 7700 3100
Text GLabel 7700 3000 0    50   Input ~ 0
VBAT
Text GLabel 7700 3100 0    50   Input ~ 0
VLCDNEG
$Comp
L 74lvc4245:74LVC4245 U7
U 1 1 5B753314
P 5700 4450
F 0 "U7" H 5700 4450 50  0000 C CNN
F 1 "74LVC4245" H 5700 4350 50  0000 C CNN
F 2 "Package_SO:TSSOP-24_4.4x7.8mm_P0.65mm" H 5100 4650 50  0001 C CNN
F 3 "" H 5100 4650 50  0001 C CNN
	1    5700 4450
	-1   0    0    -1  
$EndComp
Text GLabel 5850 3400 1    50   Input ~ 0
5VREG
Wire Wire Line
	5850 3650 5850 3450
$Comp
L Device:C C18
U 1 1 5B753510
P 6200 3600
F 0 "C18" H 6150 3950 50  0000 L CNN
F 1 "100nF" H 6100 3850 50  0000 L CNN
F 2 "Capacitor_SMD:C_0603_1608Metric" H 6238 3450 50  0001 C CNN
F 3 "~" H 6200 3600 50  0001 C CNN
	1    6200 3600
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR033
U 1 1 5B75358A
P 6200 3750
F 0 "#PWR033" H 6200 3500 50  0001 C CNN
F 1 "GND" H 6350 3700 50  0000 C CNN
F 2 "" H 6200 3750 50  0001 C CNN
F 3 "" H 6200 3750 50  0001 C CNN
	1    6200 3750
	1    0    0    -1  
$EndComp
Wire Wire Line
	5850 3450 6200 3450
Connection ~ 5850 3450
Wire Wire Line
	5850 3450 5850 3400
$Comp
L power:VCC #PWR031
U 1 1 5B75375F
P 5550 3450
F 0 "#PWR031" H 5550 3300 50  0001 C CNN
F 1 "VCC" H 5400 3550 50  0000 C CNN
F 2 "" H 5550 3450 50  0001 C CNN
F 3 "" H 5550 3450 50  0001 C CNN
	1    5550 3450
	1    0    0    -1  
$EndComp
$Comp
L Device:C C17
U 1 1 5B75379F
P 5150 3600
F 0 "C17" H 5265 3646 50  0000 L CNN
F 1 "100nF" H 5265 3555 50  0000 L CNN
F 2 "Capacitor_SMD:C_0603_1608Metric" H 5188 3450 50  0001 C CNN
F 3 "~" H 5150 3600 50  0001 C CNN
	1    5150 3600
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR032
U 1 1 5B75382A
P 5150 3750
F 0 "#PWR032" H 5150 3500 50  0001 C CNN
F 1 "GND" H 5000 3700 50  0000 C CNN
F 2 "" H 5150 3750 50  0001 C CNN
F 3 "" H 5150 3750 50  0001 C CNN
	1    5150 3750
	1    0    0    -1  
$EndComp
Wire Wire Line
	5150 3450 5550 3450
Wire Wire Line
	5550 3650 5550 3450
$Comp
L power:GND #PWR037
U 1 1 5B753B7E
P 5700 5250
F 0 "#PWR037" H 5700 5000 50  0001 C CNN
F 1 "GND" H 5705 5077 50  0000 C CNN
F 2 "" H 5700 5250 50  0001 C CNN
F 3 "" H 5700 5250 50  0001 C CNN
	1    5700 5250
	1    0    0    -1  
$EndComp
Text GLabel 7700 3900 0    50   Input ~ 0
5VREG
Wire Wire Line
	8000 4000 7050 4000
Wire Wire Line
	7050 4000 7050 4150
Wire Wire Line
	7050 4150 6300 4150
Wire Wire Line
	8000 4100 7150 4100
Wire Wire Line
	7150 4100 7150 4250
Wire Wire Line
	7150 4250 6300 4250
Wire Wire Line
	8000 4200 7250 4200
Wire Wire Line
	7250 4200 7250 4350
Wire Wire Line
	8000 4300 7350 4300
Wire Wire Line
	7350 4300 7350 4450
Wire Wire Line
	8000 4400 7450 4400
Wire Wire Line
	7450 4400 7450 4550
Wire Wire Line
	8000 4500 7550 4500
Wire Wire Line
	7550 4500 7550 4650
Wire Wire Line
	7550 4650 6300 4650
Wire Wire Line
	8000 4600 7650 4600
Wire Wire Line
	7650 4600 7650 4750
Wire Wire Line
	7650 4750 6300 4750
Wire Wire Line
	8000 4700 7750 4700
Wire Wire Line
	7750 4700 7750 4850
Wire Wire Line
	7750 4850 6300 4850
Wire Wire Line
	8000 4800 7800 4800
Wire Wire Line
	7800 4800 7800 5000
Wire Wire Line
	7800 5000 7500 5000
Text GLabel 7500 5000 0    50   Input ~ 0
SPK
Wire Wire Line
	6300 4350 7250 4350
Wire Wire Line
	6300 4450 7350 4450
Wire Wire Line
	6300 4550 7450 4550
Wire Wire Line
	5600 5250 5700 5250
Connection ~ 5700 5250
Wire Wire Line
	5700 5250 5800 5250
Wire Wire Line
	5550 3650 5650 3650
Connection ~ 5550 3650
Connection ~ 5550 3450
$Comp
L power:GND #PWR035
U 1 1 5B75D095
P 6300 4000
F 0 "#PWR035" H 6300 3750 50  0001 C CNN
F 1 "GND" H 6450 3950 50  0000 C CNN
F 2 "" H 6300 4000 50  0001 C CNN
F 3 "" H 6300 4000 50  0001 C CNN
	1    6300 4000
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR034
U 1 1 5B75D102
P 5100 4000
F 0 "#PWR034" H 5100 3750 50  0001 C CNN
F 1 "GND" H 4950 3950 50  0000 C CNN
F 2 "" H 5100 4000 50  0001 C CNN
F 3 "" H 5100 4000 50  0001 C CNN
	1    5100 4000
	1    0    0    -1  
$EndComp
Text GLabel 5100 4150 0    50   Input ~ 0
LCDVSYNC
Text GLabel 5100 4250 0    50   Input ~ 0
LCDALTSIG
Text GLabel 5100 4350 0    50   Input ~ 0
LCDCLK
Text GLabel 5100 4450 0    50   Input ~ 0
LCDD1
Text GLabel 5100 4550 0    50   Input ~ 0
LCDD0
Text GLabel 5100 4650 0    50   Input ~ 0
LCDHSYNC
Text GLabel 5100 4750 0    50   Input ~ 0
LCDDATAL
Text GLabel 5100 4850 0    50   Input ~ 0
LCDCONTROL
$Comp
L Device:R R15
U 1 1 5B75D21C
P 7100 2250
F 0 "R15" H 7170 2296 50  0000 L CNN
F 1 "10K" H 7150 2100 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" V 7030 2250 50  0001 C CNN
F 3 "~" H 7100 2250 50  0001 C CNN
	1    7100 2250
	1    0    0    -1  
$EndComp
$Comp
L Device:R R14
U 1 1 5B75D2DC
P 6850 2250
F 0 "R14" H 6920 2296 50  0000 L CNN
F 1 "10K" H 6900 2100 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" V 6780 2250 50  0001 C CNN
F 3 "~" H 6850 2250 50  0001 C CNN
	1    6850 2250
	1    0    0    -1  
$EndComp
$Comp
L Device:R R13
U 1 1 5B75D345
P 6600 2250
F 0 "R13" H 6670 2296 50  0000 L CNN
F 1 "10K" H 6650 2100 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" V 6530 2250 50  0001 C CNN
F 3 "~" H 6600 2250 50  0001 C CNN
	1    6600 2250
	1    0    0    -1  
$EndComp
$Comp
L Device:R R12
U 1 1 5B75D3A1
P 6350 2250
F 0 "R12" H 6420 2296 50  0000 L CNN
F 1 "10K" H 6400 2100 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" V 6280 2250 50  0001 C CNN
F 3 "~" H 6350 2250 50  0001 C CNN
	1    6350 2250
	1    0    0    -1  
$EndComp
Text GLabel 5350 2300 1    50   Input ~ 0
BUT_ROW1
Text GLabel 5500 2300 1    50   Input ~ 0
BUT_ROW2
Text GLabel 5650 2300 1    50   Input ~ 0
BUT_ROW3
Text GLabel 5800 2300 1    50   Input ~ 0
BUT_ROW4
Wire Wire Line
	8000 3200 7100 3200
Wire Wire Line
	7100 3200 7100 2500
Connection ~ 7100 2500
Wire Wire Line
	7100 2500 7100 2400
Wire Wire Line
	6850 2400 6850 2650
Wire Wire Line
	6850 3400 8000 3400
Wire Wire Line
	8000 3500 6600 3500
Wire Wire Line
	6600 3500 6600 2800
Wire Wire Line
	6350 2400 6350 2950
Wire Wire Line
	6350 3600 8000 3600
Wire Wire Line
	6350 2100 6350 2050
Wire Wire Line
	6350 2050 6600 2050
Wire Wire Line
	7100 2050 7100 2100
Wire Wire Line
	6850 2100 6850 2050
Connection ~ 6850 2050
Wire Wire Line
	6850 2050 7100 2050
Wire Wire Line
	6600 2050 6600 2100
Connection ~ 6600 2050
Wire Wire Line
	6600 2050 6700 2050
Wire Wire Line
	6700 2050 6700 1950
Connection ~ 6700 2050
Wire Wire Line
	6700 2050 6850 2050
$Comp
L power:VCC #PWR029
U 1 1 5B765977
P 6700 1950
F 0 "#PWR029" H 6700 1800 50  0001 C CNN
F 1 "VCC" H 6717 2123 50  0000 C CNN
F 2 "" H 6700 1950 50  0001 C CNN
F 3 "" H 6700 1950 50  0001 C CNN
	1    6700 1950
	1    0    0    -1  
$EndComp
Connection ~ 6850 2650
Wire Wire Line
	6850 2650 6850 3400
Connection ~ 6600 2800
Wire Wire Line
	6600 2800 6600 2400
Connection ~ 6350 2950
Wire Wire Line
	6350 2950 6350 3600
Text GLabel 7700 3300 0    50   Input ~ 0
BUT_COL1
Text GLabel 7700 3700 0    50   Input ~ 0
BUT_COL2
Wire Wire Line
	7700 3300 8000 3300
Wire Wire Line
	7700 3700 8000 3700
$Comp
L alps_sllb120x00:SLLB120x00 SW2
U 1 1 5B83E205
P 4850 2700
F 0 "SW2" H 4900 3215 50  0000 C CNN
F 1 "SLLB120x00" H 4900 3124 50  0000 C CNN
F 2 "alps_lever_and_push:Alps_SLLB120x00" H 4850 2700 50  0001 C CNN
F 3 "" H 4850 2700 50  0001 C CNN
	1    4850 2700
	-1   0    0    -1  
$EndComp
Wire Wire Line
	5350 2500 5350 2450
Wire Wire Line
	5350 2450 5050 2450
Wire Wire Line
	5350 2500 7100 2500
Wire Wire Line
	5050 2550 5300 2550
Wire Wire Line
	5300 2550 5300 2650
Wire Wire Line
	5300 2650 5500 2650
Wire Wire Line
	5050 2650 5250 2650
Wire Wire Line
	5250 2650 5250 2800
Wire Wire Line
	5250 2800 5650 2800
Wire Wire Line
	5050 2750 5200 2750
Wire Wire Line
	5200 2750 5200 2950
Wire Wire Line
	5200 2950 5800 2950
$Comp
L power:GND #PWR030
U 1 1 5B845CC8
P 4450 3050
F 0 "#PWR030" H 4450 2800 50  0001 C CNN
F 1 "GND" H 4455 2877 50  0000 C CNN
F 2 "" H 4450 3050 50  0001 C CNN
F 3 "" H 4450 3050 50  0001 C CNN
	1    4450 3050
	1    0    0    -1  
$EndComp
Wire Wire Line
	4550 2500 4450 2500
Wire Wire Line
	4450 2500 4450 2650
Wire Wire Line
	4550 2650 4450 2650
Connection ~ 4450 2650
Wire Wire Line
	4550 2800 4450 2800
Wire Wire Line
	4450 2650 4450 2800
Connection ~ 4450 2800
Wire Wire Line
	4450 2800 4450 2950
Wire Wire Line
	4550 2950 4450 2950
Connection ~ 4450 2950
Wire Wire Line
	4450 2950 4450 3050
Text GLabel 5250 3200 2    50   Input ~ 0
BUT_COL3
Text GLabel 5950 2300 1    50   Input ~ 0
BUT_ROW5
$Comp
L Device:R R11
U 1 1 5B84EF4E
P 6100 2250
F 0 "R11" H 6170 2296 50  0000 L CNN
F 1 "10K" H 6150 2100 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" V 6030 2250 50  0001 C CNN
F 3 "~" H 6100 2250 50  0001 C CNN
	1    6100 2250
	1    0    0    -1  
$EndComp
Wire Wire Line
	6350 2050 6100 2050
Wire Wire Line
	6100 2050 6100 2100
Connection ~ 6350 2050
Wire Wire Line
	6100 2400 6100 3050
Wire Wire Line
	6100 3050 5150 3050
Wire Wire Line
	5150 3050 5150 2850
Wire Wire Line
	5150 2850 5050 2850
Wire Wire Line
	6100 2400 5950 2400
Wire Wire Line
	5950 2400 5950 2300
Connection ~ 6100 2400
Wire Wire Line
	5350 2300 5350 2450
Connection ~ 5350 2450
Wire Wire Line
	5500 2300 5500 2650
Connection ~ 5500 2650
Wire Wire Line
	5500 2650 6850 2650
Wire Wire Line
	5650 2300 5650 2800
Connection ~ 5650 2800
Wire Wire Line
	5650 2800 6600 2800
Wire Wire Line
	5800 2300 5800 2950
Connection ~ 5800 2950
Wire Wire Line
	5800 2950 6350 2950
Wire Wire Line
	5050 3000 5050 3200
Wire Wire Line
	5050 3200 5250 3200
Wire Wire Line
	7700 3900 8000 3900
$Comp
L Mechanical:MountingHole_Pad MH1
U 1 1 5B892905
P 1350 2750
F 0 "MH1" H 1450 2801 50  0000 L CNN
F 1 "MountingHole_Pad" H 1450 2710 50  0000 L CNN
F 2 "dmg_footprints:dmg_grounding_square" H 1350 2750 50  0001 C CNN
F 3 "~" H 1350 2750 50  0001 C CNN
	1    1350 2750
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole_Pad MH2
U 1 1 5B8929EB
P 1350 3250
F 0 "MH2" H 1450 3301 50  0000 L CNN
F 1 "MountingHole_Pad" H 1450 3210 50  0000 L CNN
F 2 "dmg_footprints:dmg_grounding_square" H 1350 3250 50  0001 C CNN
F 3 "~" H 1350 3250 50  0001 C CNN
	1    1350 3250
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole_Pad MH3
U 1 1 5B892A80
P 1300 3750
F 0 "MH3" H 1400 3801 50  0000 L CNN
F 1 "MountingHole_Pad" H 1400 3710 50  0000 L CNN
F 2 "dmg_footprints:dmg_groundhole_square" H 1300 3750 50  0001 C CNN
F 3 "~" H 1300 3750 50  0001 C CNN
	1    1300 3750
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole_Pad MH4
U 1 1 5B892B10
P 1350 4300
F 0 "MH4" H 1450 4351 50  0000 L CNN
F 1 "MountingHole_Pad" H 1450 4260 50  0000 L CNN
F 2 "dmg_footprints:dmg_groundhole_square" H 1350 4300 50  0001 C CNN
F 3 "~" H 1350 4300 50  0001 C CNN
	1    1350 4300
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR090
U 1 1 5B892C1F
P 1350 4400
F 0 "#PWR090" H 1350 4150 50  0001 C CNN
F 1 "GND" H 1355 4227 50  0000 C CNN
F 2 "" H 1350 4400 50  0001 C CNN
F 3 "" H 1350 4400 50  0001 C CNN
	1    1350 4400
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR089
U 1 1 5B892C6E
P 1300 3850
F 0 "#PWR089" H 1300 3600 50  0001 C CNN
F 1 "GND" H 1305 3677 50  0000 C CNN
F 2 "" H 1300 3850 50  0001 C CNN
F 3 "" H 1300 3850 50  0001 C CNN
	1    1300 3850
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR088
U 1 1 5B892CBD
P 1350 3350
F 0 "#PWR088" H 1350 3100 50  0001 C CNN
F 1 "GND" H 1355 3177 50  0000 C CNN
F 2 "" H 1350 3350 50  0001 C CNN
F 3 "" H 1350 3350 50  0001 C CNN
	1    1350 3350
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR087
U 1 1 5B892D1B
P 1350 2850
F 0 "#PWR087" H 1350 2600 50  0001 C CNN
F 1 "GND" H 1355 2677 50  0000 C CNN
F 2 "" H 1350 2850 50  0001 C CNN
F 3 "" H 1350 2850 50  0001 C CNN
	1    1350 2850
	1    0    0    -1  
$EndComp
$EndSCHEMATC
