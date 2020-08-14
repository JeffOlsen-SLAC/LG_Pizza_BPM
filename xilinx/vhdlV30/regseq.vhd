-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      regseq.vhd - 
--
--      Copyright(c) SLAC 2000
--
--      Author: Jeff Olsen
--      Created on: 10/24/2006 12:19:13 PM
--      Last change: JO 10/26/2006 4:14:37 PM
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;


library work;
use work.bpm.all;

entity regseq is

  port (
    CLK        : in  std_logic;
    Reset      : in  std_logic;
--
    rs232Wr    : in  std_logic;
    rs232DIn   : in  std_logic_vector(7 downto 0);
    rs232AIn   : in  std_logic_vector(7 downto 0);
    rs232En    : in  std_logic;
--
    qspiWr     : in  std_logic;
    qspiDIn    : in  std_logic_vector(7 downto 0);
    qspiAIn    : in  std_logic_vector(7 downto 0);
    qspiEn     : in  std_logic;
--
    Write_Strb : out std_logic;
    DataOut    : out std_logic_vector(7 downto 0);
    AddrOut    : out std_logic_vector(7 downto 0)

    );
end regseq;

architecture BEHAVIOUR of regseq is


  signal iqspiWr      : std_logic;
  signal iqspiDIn     : std_logic_vector(7 downto 0);
  signal iqspiAIn     : std_logic_vector(7 downto 0);
  signal iqspiEn      : std_logic;
  signal iqspiWrLatch : std_logic;
  signal iqspiWrSr    : std_logic_vector(2 downto 0);

begin


  latch_p : process(qspiWr, iqspiWrSr, Reset)
  begin
    if ((iqspiWrSr(2 downto 0) = "111") or (Reset = '1')) then
      iqspiWrLatch <= '0';
    elsif (qspiWr'event and qspiWr = '1') then
      iqspiWrLatch <= '1';
    end if;
  end process;  -- latch_p

  syncWr_p : process(clk)
  begin
    if (Clk'event and Clk = '1') then
      iqspiWrSr <= iqspiWrSr(1 downto 0) & iqspiWrLatch;
      if (iqspiWrSr(2 downto 1) = "01") then
        iqspiWr <= '1';
      else
        iqspiWr <= '0';
      end if;
    end if;
  end process;  -- syncWr_p

  sync_p : process(clk)
  begin
    if (Clk'event and Clk = '1') then
      iqspiDIn <= qspiDIn;
      iqspiAIn <= qspiAIn;
      iqspiEn  <= qspiEn;
    end if;
  end process;  -- sync_p

  dmux_p : process(qspiEn, qspiDIn, rs232DIn, qspiWr, rs232Wr, rs232En,
                   qspiAIn, rs232AIn, iqspiAIn, iqspiDin, iqspiWr)
  begin
    if (Rs232En = '0') then
      AddrOut    <= iqspiAIn;
      DataOut    <= iqspiDIn;
      Write_Strb <= iqspiWr;
    else
      AddrOut    <= rs232AIn;
      DataOut    <= rs232DIn;
      Write_Strb <= rs232Wr;
    end if;
  end process;  --dmux_p

end behaviour;



