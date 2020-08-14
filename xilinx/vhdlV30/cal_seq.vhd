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
--  Last change: JO 12/13/2007 5:38:27 PM
--

-- ModeSel
--  00 => Red
--  01 => Green
--  10 => BOTH
--  11 => Nothing

-- 10/23/08 jjo
--  Bring out C2 and C4 to control Attenuators during
-- Calibration
--

library work;
use work.bpm.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity cal_seq is
  port (
    Clock       : in  std_logic;
    Reset       : in  std_logic;
    Sys_Trigger : in  std_logic;
--
    ModeSel     : in  std_logic_vector(1 downto 0);
    OscMode     : in  std_logic_vector(1 downto 0);
    TRIG2AMP    : in  std_logic_vector(7 downto 0);
    AMP2RF1     : in  std_logic_vector(7 downto 0);
    RF12RF2     : in  std_logic_vector(7 downto 0);
    RFWIDTH     : in  std_logic_vector(7 downto 0);
    OFFTIME     : in  std_logic_vector(7 downto 0);
--
    CAL_SW      : out std_logic_vector(6 downto 1);
    C2          : out std_logic;
    C4          : out std_logic;
    VAPC        : out std_logic;
    OscOn       : out std_logic
    );
end cal_seq;

architecture Behaviour of cal_seq is

  type state_t is
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

  signal NextState : State_t;
  signal RF_On     : std_logic;
  signal AMP_On    : std_logic;
  signal iC2       : std_logic;
  signal iC3       : std_logic;
  signal iC4       : std_logic;
  signal Start     : std_logic;
  signal Counter   : std_logic_vector(9 downto 0);
  signal usCounter : std_logic_vector(19 downto 0);
  signal AutoOscOn : std_logic;

begin

  C2                 <= iC2;
  C4                 <= iC4;
--
  VAPC               <= AMP_On;
  Cal_Sw(4 downto 1) <= iC4 & iC3 & iC2 & RF_On;
  Cal_Sw(5)          <= iC2 and RF_On;
  Cal_Sw(6)          <= iC4 and RF_On;

  OscOn_p : process(AutoOscOn, OscMode)
  begin
    case OscMode is
      when OscMode_Auto =>
        OscOn <= AutoOscOn;
      when OscMode_On =>
        OscOn <= '1';
      when OscMode_Off =>
        OscOn <= '0';
      when others =>
        OscOn <= '0';
    end case;
  end process;

  trig_p : process(clock, reset)
  begin
    if (reset = '1') then
      Start <= '0';
    elsif (clock'event and clock = '1') then
      if (ModeSel /= "11") then
        Start <= Sys_Trigger;
      else
        Start <= '0';
      end if;
    end if;
  end process;  -- trig_p

  CalSeq_p : process(CLock, Reset)
  begin

    if (Reset = '1') then
      AMP_On    <= '0';
      RF_On     <= '0';
      iC2       <= '0';
      iC3       <= '0';
      iC4       <= '0';
      Counter   <= (others => '0');
      AutoOscOn <= '0';
      NextState <= Idle;
      usCounter <= (others => '0');
    elsif (Clock'event and Clock = '1') then
      case NextState is
        when Idle =>
          if (Start = '1') then
            AutoOscOn <= '1';
            usCounter <= OscOn_Tick;
            if (Trig2AMP = "0000000000") then
              AMP_On <= '1';
              case ModeSel is
                when GreenMode =>
                  iC2 <= '0';
                  iC3 <= '0';
                  iC4 <= '1';
                when others =>
                  iC2 <= '1';
                  iC3 <= '1';
                  iC4 <= '0';
              end case;
              Counter   <= (AMP2RF1-1) & "00";
              NextState <= Wait_RF1;
            else
--                      Counter                 <= (TRIG2AMP -1)& "00";
              Counter   <= "00" & (TRIG2AMP)-1;
              NextState <= Wait_AMP;
            end if;
          else
            AutoOscOn <= '0';
            NextState <= Idle;
          end if;

-- usCounter is a 1us counter so that AMP2RF1 delay is in
-- 10us steps for 2.55ms

        when Wait_AMP =>
          if (usCounter = "00000") then
            usCounter <= OscOn_Tick;
            if (Counter = "00000000000") then
              case ModeSel is
                when GreenMode =>
                  iC2 <= '0';
                  iC3 <= '0';
                  iC4 <= '1';
                when others =>
                  iC2 <= '1';
                  iC3 <= '1';
                  iC4 <= '0';
              end case;
              AMP_On    <= '1';
              Counter   <= (AMP2RF1-1)& "00";
              NextState <= Wait_RF1;
            else
              Counter   <= Counter -1;
              NextState <= Wait_AMP;
            end if;
          else
            usCounter <= usCounter -1;
          end if;

        when Wait_RF1 =>
          if (Counter = "00000000000") then
            RF_On     <= '1';
            Counter   <= (RFWIDTH -1)& "00";
            NextState <= RF_On1;
          else
            Counter   <= Counter -1;
            NextState <= Wait_RF1;
          end if;

        when RF_On1 =>
          if (Counter = "00000000000") then
            RF_On     <= '0';
            Counter   <= (OFFTIME -1)& "00";
            NextState <= Wait_Off1;
          else
            Counter   <= Counter -1;
            NextState <= RF_On1;
          end if;

        when Wait_Off1 =>
          if (Counter = "00000000000") then
            case ModeSel is
              when BOTHMode =>
                AMP_On <= '1';
                iC2    <= '0';
                iC3    <= '0';
                iC4    <= '1';
                if (RF12RF2 = "0000000000") then
                  RF_On     <= '1';
                  Counter   <= (RFWIDTH -1)& "00";
                  NextState <= RF_On2;
                else
                  Counter   <= (RF12RF2-1)& "00";
                  NextState <= Wait_RF2;
                end if;

              when others =>
                RF_On     <= '0';
                AMP_On    <= '0';
                iC2       <= '0';
                iC3       <= '0';
                iC4       <= '0';
                NextState <= Idle;
            end case;

          else
            Counter   <= Counter -1;
            NextState <= Wait_Off1;
          end if;

        when Wait_RF2 =>
          if (Counter = X"000000000000") then
            RF_On     <= '1';
            Counter   <= (RFWIDTH -1)& "00";
            NextState <= RF_On2;
          else
            Counter   <= Counter -1;
            NextState <= Wait_RF2;
          end if;

        when RF_On2 =>
          if (Counter = X"000000000000") then
            RF_On     <= '0';
            Counter   <= (OFFTIME -1)& "00";
            NextState <= Wait_Off2;
          else
            Counter   <= Counter -1;
            NextState <= RF_On2;
          end if;

        when Wait_Off2 =>
          if (Counter = X"000000000000") then
            RF_On     <= '0';
            AMP_On    <= '0';
            iC2       <= '0';
            iC3       <= '0';
            iC4       <= '0';
            NextState <= Idle;
          else
            Counter   <= Counter -1;
            NextState <= Wait_Off2;
          end if;

        when others =>
          RF_On     <= '0';
          AMP_On    <= '0';
          iC2       <= '0';
          iC3       <= '0';
          iC4       <= '0';
          NextState <= Idle;

      end case;
    end if;
  end process;  --CalSeq_p


end behaviour;

