//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.10.03 Education
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Tue Feb 11 12:55:59 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	UART_MASTER_Top your_instance_name(
		.I_CLK(I_CLK), //input I_CLK
		.I_RESETN(I_RESETN), //input I_RESETN
		.I_TX_EN(I_TX_EN), //input I_TX_EN
		.I_WADDR(I_WADDR), //input [2:0] I_WADDR
		.I_WDATA(I_WDATA), //input [7:0] I_WDATA
		.I_RX_EN(I_RX_EN), //input I_RX_EN
		.I_RADDR(I_RADDR), //input [2:0] I_RADDR
		.O_RDATA(O_RDATA), //output [7:0] O_RDATA
		.SIN(SIN), //input SIN
		.RxRDYn(RxRDYn), //output RxRDYn
		.SOUT(SOUT), //output SOUT
		.TxRDYn(TxRDYn), //output TxRDYn
		.DDIS(DDIS), //output DDIS
		.INTR(INTR), //output INTR
		.DCDn(DCDn), //input DCDn
		.CTSn(CTSn), //input CTSn
		.DSRn(DSRn), //input DSRn
		.RIn(RIn), //input RIn
		.DTRn(DTRn), //output DTRn
		.RTSn(RTSn) //output RTSn
	);

//--------Copy end-------------------
