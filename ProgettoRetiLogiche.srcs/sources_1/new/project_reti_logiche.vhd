library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
    port
    (
        i_clk   : in std_logic;
        i_rst   : in std_logic; 
        i_start : in std_logic;
        i_w     : in std_logic;
        
        o_z0   : out std_logic_vector(7 downto 0);
        o_z1   : out std_logic_vector(7 downto 0);
        o_z2   : out std_logic_vector(7 downto 0);
        o_z3   : out std_logic_vector(7 downto 0);
        o_done : out std_logic;
        
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0);
        o_mem_we   : out std_logic;
        o_mem_en   : out std_logic
    );
end project_reti_logiche;


architecture behavioural of project_reti_logiche is

    constant GND           : std_logic_vector(7 downto 0)  := (others => '0');
    constant GND_16        : std_logic_vector(15 downto 0) := (others => '0');
    
    signal s_mem_addr      : std_logic_vector(15 downto 0);
    signal z_id            : std_logic_vector(1 downto 0);

    signal state         : std_logic_vector(1 downto 0);
    signal preout_z0     : std_logic_vector(7 downto 0);
    signal preout_z1     : std_logic_vector(7 downto 0);
    signal preout_z2     : std_logic_vector(7 downto 0);
    signal preout_z3     : std_logic_vector(7 downto 0);
    
    
begin
    main_proc: process(i_clk, i_rst)
    begin
        if i_rst = '1' then --transizione di reset
        
            state <= "00";
            
            preout_z0 <= GND;   --registri per la memorizzazione delle uscite precedenti
            preout_z1 <= GND;
            preout_z2 <= GND;
            preout_z3 <= GND;
            
            o_z0 <= GND;
            o_z1 <= GND;
            o_z2 <= GND;
            o_z3 <= GND;
            
            o_mem_addr <= GND_16;
            o_done <= '0';
                      
        else
            if i_clk'event and i_clk = '1' then
                case state is 
                    when "00" =>
                    
                        --abstraction of the first, reset , state.
                        --grounds all outputs, reads the first bit of z_id if i_start is up.
                        
                        o_z0 <= GND;    --FUNZIONE DI STATO
                        o_z1 <= GND;
                        o_z2 <= GND;
                        o_z3 <= GND;
                        
                        o_mem_addr <= GND_16;
                        o_done <= '0';
                        o_mem_en <= '0';
                        
                        if i_start = '1' then  --FUNZIONE DI TRANSIZIONE
                            z_id(1) <= i_w;
                            state <= "01";
                        end if;
                        
                    when "01" =>
                    
                        --second state and last-z-reading state
                        --to reach a major efficiency, this state directly puts o_mem_en to '1'. it enables the memory to be ready at address '0000'
                        
                        if i_start = '1' then --FUNZIONE DI TRANSIZIONE
                            z_id(0) <= i_w;
                            state <= "10";
                            o_mem_en <= '1';
                        end if;
                        
                    when "10" =>
                    
                        --this is a cyclic state. it reads all bits from the serial i_w to build the memory address.
                        --terminates when start goes to '0' and steps to the final "111" state
                        
                        if i_start = '1' then       --FUNZIONE DI TRANSIZIONE RIFLESSIVA
                            o_mem_addr <= o_mem_addr(14 downto 0) & i_w;
                        else                        --FUNZIONE DI TRANSIZONE
                            state <= "11";
                        end if;
                        
                    when "11" =>
                    
                        --final state, the one that pushes out the o_z arrays.
                        --it sets o_done to '1' and steps to the reset state. it esures, doing so, to keep the signal o_done high for 
                        --exactly 1 clk cycle
                        state <= "00";          --FUNZIONE DI TRANSIZIONE OBBLIGATA
                        
                        o_done <= '1';          --FUNZIONE DI STATO...
                        
                        case z_id is 
                            when "00" =>
                            
                                preout_z0 <= i_mem_data;
                                o_z0 <= i_mem_data;
                                o_z1 <= preout_z1;
                                o_z2 <= preout_z2;
                                o_z3 <= preout_z3;
                                
                            when "01" =>
                            
                                preout_z1 <= i_mem_data;
                                o_z0 <= preout_z0;
                                o_z1 <= i_mem_data;
                                o_z2 <= preout_z2;
                                o_z3 <= preout_z3;
                                
                            when "10" =>
                            
                                preout_z2 <= i_mem_data;
                                o_z0 <= preout_z0;
                                o_z1 <= preout_z1;
                                o_z2 <= i_mem_data;
                                o_z3 <= preout_z3;
                                
                            when others => --11
                            
                                preout_z3 <= i_mem_data;
                                o_z0 <= preout_z0;
                                o_z1 <= preout_z1;
                                o_z2 <= preout_z2;
                                o_z3 <= i_mem_data;
                                
                        end case;
                        
                    when others =>  -- does nothing (case not expected)
                end case;
            end if;
        end if;
    end process;
    
    o_mem_we <= '0';
    
end behavioural;