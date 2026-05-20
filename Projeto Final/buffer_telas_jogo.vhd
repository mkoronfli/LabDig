library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------
-- Gera os bytes de pixel que são enviados para o display_control

-- 8 páginas, cada linha tem 8 pixels de altura, 128 colunas por página
-- Cada byte é uma coluna de pixels 

-- Layout das 3 telas:

-- 1) Tela de início: "MENU" (cmd_telas = "00")
-- 
--        SNAKE GAME         -> (fonte maior)
-- BEST SCORE *max_score*
--
--          JOGAR
--
-- 
-- 2) Tela de jogo: "JOGADA" (cmd_telas = "01")

-- Borda em todos os pixels da borda
-- "XX" score -> pontuação no canto superior direito da tela
-- Cabeça da cobra: pixel aceso na posição da cabeça
-- Fruta: pixel aceso na posição da fruta

-- 3) Tela de fim: "GAME OVER" (cmd_telas = "10")
--
--  GAME OVER
-- SCORE *score*
-- BEST SCORE *max_score*
--
-------------------------------------------------------------------
entity buffer_telas_jogo is
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;

        cmd_telas     : in  std_logic_vector(1 downto 0);   -- "00"=menu, "01"=jogo, "10"=fim
        
        pos_x         : in  std_logic_vector(6 downto 0);   
        pos_y         : in  std_logic_vector(5 downto 0);   
        fruta_x       : in  std_logic_vector(6 downto 0);
        fruta_y       : in  std_logic_vector(5 downto 0);
        score         : in  integer range 0 to 99;        
        max_score     : in  integer range 0 to 99;  

        fb_page     : in  integer range 0 to 7;                -- página atual (0 a 7)
        fb_col      : in  integer range 0 to 127;              -- coluna atual (0 a 127)
        fb_byte     : out std_logic_vector(7 downto 0)  
    );
end entity buffer_telas_jogo;

architecture telas of buffer_telas_jogo is
----------------------------------------------------------------------------------
-- ROM utilizada:

-- 0 ... 9 : dígitos
-- 10      : 'S'
-- 11      : 'N'
-- 12      : 'A'
-- 13      : 'K'
-- 14      : 'E'
-- 15      : ' ' (espaço)
-- 16      : 'G'
-- 17      : 'M'
-- 18      : 'O'
-- 19      : 'V'
-- 20      : 'R'
-- 21      : 'J'
-- 22      : 'B'
-- 23      : 'T'
-- 24      : 'C'
-- 25      : ':'  (dois pontos)
----------------------------------------------------------------------------------

type font_col_type is array (0 to 4) of std_logic_vector(7 downto 0);
type font_type is array (0 to 25) of font_col_type;

constant FONT: font_type := (
        -- 0 
        (x"3E",x"51",x"49",x"45",x"3E"),
        -- 1 
        (x"00",x"42",x"7F",x"40",x"00"),
        -- 2 
        (x"42",x"61",x"51",x"49",x"46"),
        -- 3 
        (x"21",x"41",x"45",x"4B",x"31"),
        -- 4 
        (x"18",x"14",x"12",x"7F",x"10"),
        -- 5 
        (x"27",x"45",x"45",x"45",x"39"),
        -- 6 
        (x"3C",x"4A",x"49",x"49",x"30"),
        -- 7 
        (x"01",x"71",x"09",x"05",x"03"),
        -- 8 
        (x"36",x"49",x"49",x"49",x"36"),
        -- 9 
        (x"06",x"49",x"49",x"29",x"1E"),
        -- 10 'S'
        (x"26",x"45",x"45",x"45",x"39"),
        -- 11 'N'
        (x"7F",x"04",x"08",x"10",x"7F"),
        -- 12 'A'
        (x"7E",x"09",x"09",x"09",x"7E"),
        -- 13 'K'
        (x"7F",x"08",x"14",x"22",x"41"),
        -- 14 'E'
        (x"7F",x"49",x"49",x"49",x"41"),
        -- 15 ' '
        (x"00",x"00",x"00",x"00",x"00"),
        -- 16 'G'
        (x"3E",x"41",x"49",x"49",x"7A"),
        -- 17 'M'
        (x"7F",x"02",x"04",x"02",x"7F"),
        -- 18 'O'
        (x"3E",x"41",x"41",x"41",x"3E"),
        -- 19 'V'
        (x"1F",x"20",x"40",x"20",x"1F"),
        -- 20 'R'
        (x"7F",x"09",x"19",x"29",x"46"),
        -- 21 'J'
        (x"20",x"40",x"41",x"3F",x"01"),
        -- 22 'B'
        (x"7F",x"49",x"49",x"49",x"36"),
        -- 23 'T'
        (x"01",x"01",x"7F",x"01",x"01"),
        -- 24 'C'
        (x"3E",x"41",x"41",x"41",x"22"),
        -- 25 ':'
        (x"00",x"36",x"36",x"00",x"00")
    );


type str10_type is array (0 to 9) of integer range 0 to 25;
type str9_type  is array (0 to 8) of integer range 0 to 25;
type str5_type  is array (0 to 4) of integer range 0 to 25;


--  escrevendo "SNAKE GAME" 
constant SNAKE_GAME: str10_type := (10,11,12,13,14,15,16,12,17,14);

-- escrevendo "BEST SCORE"
constant BEST_SCORE: str10_type := (22,14,10,23,15,10,24,18,20,14);

-- escrevendo "JOGAR"
constant JOGAR: str5_type := (21,18,16,12,20);

-- escrevendo "GAME OVER"
constant GAME_OVER: str9_type := (16,12,17,14,15,18,19,14,20);

-- escrevendo "SCORE"
constant SCORE_STR: str5_type := (10,24,18,20,14);

--------------------------------------------------------------------------------------------------------

signal sig_x : integer range 0 to 127;
signal sig_y : integer range 0 to 63;
signal sig_fx : integer range 0 to 127;
signal sig_fy : integer range 0 to 63;
signal sig_max_score : integer range 0 to 99;

signal sig_unit : integer range 0 to 9;
signal sig_tens : integer range 0 to 9;

-- posicoes alvo de renderizacao de 1 pixel
signal sig_cobra_page : integer range 0 to 7;
signal sig_cobra_bit  : integer range 0 to 7;
signal sig_fruta_page : integer range 0 to 7;
signal sig_fruta_bit  : integer range 0 to 7;

begin 

sig_x  <= to_integer(unsigned(pos_x));
sig_y  <= to_integer(unsigned(pos_y));
sig_fx <= to_integer(unsigned(fruta_x));
sig_fy <= to_integer(unsigned(fruta_y));
sig_max_score <= max_score;

sig_unit  <= score mod 10;
sig_tens  <= score / 10;

sig_cobra_page <= sig_y  / 8;
sig_cobra_bit  <= sig_y  mod 8;
sig_fruta_page <= sig_fy / 8;
sig_fruta_bit  <= sig_fy mod 8;

process(cmd_telas, fb_page, fb_col, pos_x, pos_y, fruta_x, fruta_y, score, max_score,
        sig_cobra_page, sig_cobra_bit, sig_fruta_page, sig_fruta_bit,
        sig_x, sig_fx, sig_tens, sig_unit, sig_max_score)

    variable v_fb_byte     : std_logic_vector(7 downto 0);
    variable v_rel_col     : integer range 0 to 127;
    variable v_char_idx    : integer range 0 to 9;
    variable v_inner_col   : integer range 0 to 5;

    begin

        v_fb_byte := (others => '0');  -- valor padrão: todos os pixels apagados

        case cmd_telas is
            when "00" =>  -- MENU

            -- snake game
            if fb_page = 0 and fb_col >=34 and fb_col < 93 then
                v_rel_col := fb_col - 34;
                v_char_idx := v_rel_col / 6;
                v_inner_col := v_rel_col mod 6;
                if v_inner_col <= 4 then
                    v_fb_byte := FONT(SNAKE_GAME(v_char_idx))(v_inner_col);
                end if;
            end if;

            -- best score
            if fb_page = 2 and fb_col >= 14 and fb_col <= 73 then
                v_rel_col := fb_col - 14;
                v_char_idx := v_rel_col / 6;
                v_inner_col := v_rel_col mod 6;
                if v_inner_col <= 4 then
                    v_fb_byte := FONT(BEST_SCORE(v_char_idx))(v_inner_col);
                end if;
            end if;

            -- max score
            if fb_page = 2 and fb_col >= 74 and fb_col <= 85 then
                v_rel_col := fb_col - 74;
                v_char_idx := v_rel_col / 6;
                v_inner_col := v_rel_col mod 6;
                if v_inner_col <= 4 then
                    if v_rel_col < 6 then
                        v_fb_byte := FONT(sig_max_score / 10)(v_inner_col); 
                    else
                        v_fb_byte := FONT(sig_max_score mod 10)(v_inner_col);
                    end if;
                end if;
            end if;

            -- jogar
            if fb_page = 5 and fb_col >= 49 and fb_col <= 78 then
                v_rel_col := fb_col - 49;
                v_char_idx := v_rel_col / 6;
                v_inner_col := v_rel_col mod 6;
                if v_inner_col <=4 then
                    v_fb_byte := FONT(JOGAR(v_char_idx))(v_inner_col);
                end if;
            end if;

            when "01" =>  -- JOGADA
            -- borda esquerda 

            if fb_col = 0 then
                v_fb_byte := x"FF";  -- acende todos os bits da coluna
            end if;

            -- borda direita

            if fb_col = 127 then
                v_fb_byte := x"FF";  -- acende todos os bits da coluna
            end if;

            -- borda superior
            if fb_page = 0 then
                v_fb_byte := v_fb_byte or x"01";  -- acende todos os bits da linha
            end if;

            -- borda inferior
            if fb_page = 7 then
                v_fb_byte := v_fb_byte or x"80";  -- acende todos os bits da linha
            end if;
            
            -- renderizando score
            if fb_page = 0 and fb_col >= 104 and fb_col <115 then
                v_rel_col := fb_col - 104;  -- coluna relativa dentro do espaço de score
                v_char_idx := v_rel_col / 6;  
                v_inner_col := v_rel_col mod 6; 

                if v_inner_col <= 4 then
                    if v_rel_col < 6 then
                        v_fb_byte := v_fb_byte or FONT(sig_tens)(v_inner_col); 
                        else
                        v_fb_byte := v_fb_byte or FONT(sig_unit)(v_inner_col);
                    end if;
                end if;
            end if; 

            -- renderizando pixel da cobra

            if fb_page = sig_cobra_page and fb_col = sig_x then
                v_fb_byte := v_fb_byte or std_logic_vector(shift_left(to_unsigned(1, 8), sig_cobra_bit));  -- acende o bit no byte de saída
            end if;

            -- renderizando pixel da fruta

            if fb_page = sig_fruta_page and fb_col = sig_fx then
                v_fb_byte := v_fb_byte or std_logic_vector(shift_left(to_unsigned(1, 8), sig_fruta_bit));  -- acende o bit no byte de saída
            end if;

            when "10" =>  -- GAME OVER
            -- game over
            if fb_page = 0 and fb_col >=19 and fb_col < 72 then
                v_rel_col := fb_col - 19;
                v_char_idx := v_rel_col / 6;
                v_inner_col := v_rel_col mod 6;
                if v_inner_col <= 4 then
                    v_fb_byte := FONT(GAME_OVER(v_char_idx))(v_inner_col);
                end if;
            end if;

            -- score
             if fb_page = 3 and fb_col >=24 and fb_col < 53 then
                v_rel_col := fb_col - 24;
                v_char_idx := v_rel_col / 6;
                v_inner_col := v_rel_col mod 6;
                if v_inner_col <= 4 then
                    v_fb_byte := FONT(SCORE_STR(v_char_idx))(v_inner_col);
                end if;
            end if;

            -- renderizando score
            if fb_page = 3 and fb_col >= 104 and fb_col <115 then
                v_rel_col := fb_col - 104;  -- coluna relativa dentro do espaço de score
                v_char_idx := v_rel_col / 6;  
                v_inner_col := v_rel_col mod 6; 

                if v_inner_col <= 4 then
                    if v_rel_col < 6 then
                        v_fb_byte := v_fb_byte or FONT(sig_tens)(v_inner_col); 
                        else
                        v_fb_byte := v_fb_byte or FONT(sig_unit)(v_inner_col);
                    end if;
                end if;
            end if; 

             -- best score
            if fb_page = 5 and fb_col >= 14 and fb_col <= 73 then
                v_rel_col := fb_col - 14;
                v_char_idx := v_rel_col / 6;
                v_inner_col := v_rel_col mod 6;
                if v_inner_col <=4 then
                    v_fb_byte := FONT(BEST_SCORE(v_char_idx))(v_inner_col);
                end if;
            end if;

            -- max score
            if fb_page = 5 and fb_col >= 74 and fb_col <= 85 then
                v_rel_col := fb_col - 74;
                v_char_idx := v_rel_col / 6;
                v_inner_col := v_rel_col mod 6;
                if v_inner_col <=4 then
                    if v_rel_col < 6 then
                        v_fb_byte := FONT(sig_max_score / 10)(v_inner_col); 
                    else
                    v_fb_byte := FONT(sig_max_score mod 10)(v_inner_col);
                    end if;
                end if;
            end if;

            when others =>
                v_fb_byte := (others => '0');
        end case;

    fb_byte <= v_fb_byte;

end process;

end architecture telas;