-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--  cal_seq.vhd -
--
--  Copyright(c) Stanford Linear Accelerator Center 2000
--
--  Author: JEFF OLSEN
--  Created on: 8/4/2006 1:01:51 PM
--  Last change: JO 1/18/2007 5:22:07 PM
--

-- ModeSel
--  00 => Red
--  01 => Green
--  10 => BOTH
--  11 => Nothing


Library work;
use work.bpm.all;

Library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

Entity cal_seq is
Port (
	Clock 		: in std_logic;
	Reset 		: in std_logic;
    Sys_Trigger 	: in std_logic;

    ModeSel		: in std_logic_vector(1 downto 0);
    
    TRIG2AMP	: in std_logic_vector(7 downto 0);
    AMP2RF1		: in std_logic_vector(7 downto 0);
    RF12RF2		: in std_logic_vector(7 downto 0);
    RFWIDTH		: in std_logic_vector(7 downto 0);
    OFFTIME		: in std_logic_vector(7 downto 0);

    CAL_SW		: out std_logic_vector(4 downto 1);
    VAPC 		: out std_logic
    );
end cal_seq;

Architecture Behaviour of cal_seq is

Type state_t is
	(
    	Idle,
        Wait_AMP,
		Wait_RF1,
        RF_On1,
        Wait_Off1,
        Wait_RF2,
        RF_On2,
        Wait_Off2
        );

signal NextState 	: State_t;

signal RF_On 	: std_logic;
signal AMP_On 	: std_logic;
signal iC2 		: std_logic;
signal iC3 		: std_logic;
signal iC4 		: std_logic;

signal d_Trig 	: std_logic;
signal Start 	: std_logic;
signal Counter 	: std_logic_vector(7 downto 0);


Begin


VAPC		<= AMP_On;
Cal_Sw 		<= iC4 & iC3 & iC2 & RF_On;

trig_p: process(clock, reset)
begin
if (reset = '1') then
    Start 	<= '0';
elsif (clock'event and clock = '1') then
	if (ModeSel /= "11") then
	    Start <= Sys_Trigger;
	else
	    Start <= '0';
	end if;
end if;
end process; -- trig_p

CalSeq_p: Process(CLock, Reset)
Begin

If (Reset = '1') then
	AMP_On 	<= '0';
    RF_On  	<= '0';
    iC2		<= '0';
    iC3		<= '0';
    iC4		<= '0';
	Counter 	<= (Others => '0');
	NextState 	<= Idle;
elsif (Clock'event and Clock = '1') then
Case NextState is
When Idle =>
	If (Start = '1') then
		If (Trig2AMP = "00000000") then
			AMP_On 		<= '1';
            Case ModeSel is
			When GreenMode =>
            	iC2 <= '0';
               iC3 <= '0';
            	iC4 <= '1';
			When others =>
            	iC2 <= '1';
                iC3 <= '1';
            	iC4 <= '0';
			end case;
            Counter		<= AMP2RF1-1;
			NextState 	<= Wait_RF1;
		else
			Counter 		<= TRIG2AMP -1;
			NextState 		<= Wait_AMP;
		end if;
	else
		NextState 		<= Idle;
	end if;

When Wait_AMP =>
	If (Counter = "000000000") then
			AMP_On 		<= '1';
            Case ModeSel is
			When GreenMode =>
            	iC2 <= '0';
                iC3 <= '0';
            	iC4 <= '1';
			When others =>
            	iC2 <= '1';
                iC3 <= '1';
            	iC4 <= '0';
			end case;
            Counter <= AMP2RF1-1 ;
            NextState <= Wait_RF1;
	else
		Counter 	<= Counter -1;
        NextState 	<= Wait_AMP;
	end if;

When Wait_RF1 =>
	If (Counter = "000000000") then
    	RF_On	<= '1';
        Counter <= RFWIDTH -1;
        NextState <= RF_On1;
 	else
    	Counter <= Counter -1;
    	NextState <= Wait_RF1;
    end if;

When RF_On1 =>
	If (Counter = "000000000") then
    	RF_On	<= '0';
        Counter <= OFFTIME -1;
        NextState <= Wait_Off1;
 	else
    	Counter <= Counter -1;
    	NextState <= RF_On1;
    end if;

When Wait_Off1 =>
	If (Counter = "000000000") then
          Case ModeSel is
 			When BOTHMode =>
            	AMP_On <= '1';
            	iC2 <= '0';
                iC3 <= '0';
            	iC4 <= '1';
                if (RF12RF2 = "00000000") then
                	RF_On <= '1';
						Counter <= RFWIDTH -1;
                    NextState <= RF_On2;
                else
                	Counter <= RF12RF2-1;
                    NextState <= Wait_RF2;
                end if;
			When others =>
				RF_On 	<= '0';
            	AMP_On 	<= '0';
            	iC2 	<= '0';
                iC3 	<= '0';
            	iC4 	<= '0';
				NextState <= Idle;
			end case;

 	else
    	Counter <= Counter -1;
    	NextState <= Wait_Off1;
    end if;

When Wait_RF2 =>
	If (Counter = X"000000000") then
    	RF_On	<= '1';
        Counter <= RFWIDTH -1;
        NextState <= RF_On2;
 	else
    	Counter <= Counter -1;
    	NextState <= Wait_RF2;
    end if;

When RF_On2 =>
	If (Counter = X"000000000") then
    	RF_On	<= '0';
        Counter <= OFFTIME -1;
        NextState <= Wait_Off2;
 	else
    	Counter <= Counter -1;
    	NextState <= RF_On2;
    end if;

When Wait_Off2 =>
	If (Counter = X"000000000") then
    	RF_On 	<= '0';
        AMP_On 	<= '0';
        iC2		<= '0';
        iC3		<= '0';
        iC4		<= '0';
        NextState <= Idle;
 	else
    	Counter <= Counter -1;
    	NextState <= Wait_Off2;
    end if;




When others =>
    	RF_On 	<= '0';
        AMP_On 	<= '0';
        iC2		<= '0';
        iC3		<= '0';
        iC4		<= '0';
		NextState <= Idle;

end Case;
end if;
end process; --CalSeq_p


end behaviour;

