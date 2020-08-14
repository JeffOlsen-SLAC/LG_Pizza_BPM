-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--  rs232_tst.vhd - 
--
--  Copyright(c) SLAC 2000
--
--  Author: Jeff Olsen
--  Created on: 10/26/2006 4:13:07 PM
--  Last change: JO  10/26/2006 4:13:07 PM
--
-- 
-- Created by Jeff Olsen 10/11/06
--
--  Filename: rs232_tst
--
--  Function:
--  Test rs232 Transmit/receive
--  
--  Modifications:
--


Library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library work;
use work.bpm.all;

Entity rs232_tst is
Port (
	clk 		: in std_logic;
	reset 		: in std_logic;
	Tx_Dav 		: in std_logic;
	Tx_dataIn 	: in std_logic_vector(7 downto 0);
	Tx_Addr 	: in std_logic_vector(7 downto 0);
	RxValid 	: out std_logic;
	RxAddr 		: out std_logic_vector(7 downto 0);
	RxData 		: out std_logic_vector(7 downto 0)
	);

end rs232_tst;


Architecture Behaviour of rs232_tst is


signal Tx_DataOut  	: std_logic_vector(7 downto 0);
signal Tx_Done 		: std_logic;
signal Xmit 		: std_logic;
signal TxSDOut 		: std_logic;

signal RxDout 		: std_logic_vector(7 downto 0);
signal RxParity 	: std_logic;
signal RxDone 		: std_logic;

begin
    
u_transmit: transmit 
Port map (
	CLK		=> Clk,
	Reset 	=> Reset,
	NewData	=> Tx_Dav,
	DataIn	=> Tx_DataIn,
	Addr	=> Tx_Addr,
	DataOut	=> Tx_DataOut,
	TxDone	=> Tx_Done,
	Xmit	=> Xmit
	);

u_rs232_tx: rs232_tx
Port map (
	TxCLK	=> Clk,
	Reset 	=> Reset,
	Xmit	=> Xmit,
	Data	=> Tx_DataOut,
	TxDone	=> Tx_Done,
	TxOut	=> TxSDOut
	);



u_rs232_rx: rs232_rx
Port map (
	RxCLK		=> Clk,
	Reset 		=> Reset,
	RxDin 		=> TxSDOut,
	RxData 		=> RxDout,
	RxDone		=> RxDone,
	RxParity	=> RxParity
	);


u_receive: receive
Port map (
	CLK		=> Clk,
	Reset 	=> Reset,
	Parity 	=> RxParity,
	DAV		=> RxDone,
	DataIn 	=> RxDout,
	Valid	=> RxValid,
	Addr	=> RxAddr,
	Data	=> RxData
	);


end behaviour;