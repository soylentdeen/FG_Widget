;+
; NAME:
;     mkct (make color table)
;
; PURPOSE:
;     Loads a color table and reserves the lower indices for plotting
;
; CATEGORY:
;     Plotting and Image Display
;
; CALLING SEQUENCE:
;     mkct,BOT=bot,RED=red,GREEN=green,BLUE=blue,CANCEL=cancel
;     mkct,cm,BOT=bot,RED=red,GREEN=green,BLUE=blue,CANCEL=cancel
;
; INPUTS:
;     None
;
; OPTIONAL INPUTS:
;     cm - The index of the requested color map 
;
;          0-        B-W LINEAR   14-             STEPS   28-         Hardcandy
;          1-        BLUE/WHITE   15-     STERN SPECIAL   29-            Nature
;          2-   GRN-RED-BLU-WHT   16-              Haze   30-             Ocean
;          3-   RED TEMPERATURE   17- Blue - Pastel - R   31-        Peppermint
;          4- BLUE/GREEN/RED/YE   18-           Pastels   32-            Plasma
;          5-      STD GAMMA-II   19- Hue Sat Lightness   33-          Blue-Red
;          6-             PRISM   20- Hue Sat Lightness   34-           Rainbow
;          7-        RED-PURPLE   21-   Hue Sat Value 1   35-        Blue Waves
;          8- GREEN/WHITE LINEA   22-   Hue Sat Value 2   36-           Volcano
;          9- GRN/WHT EXPONENTI   23- Purple-Red + Stri   37-             Waves
;         10-        GREEN-PINK   24-             Beach   38-         Rainbow18
;         11-          BLUE-RED   25-         Mac Style   39-   Rainbow + white
;         12-          16 LEVEL   26-             Eos A   40-   Rainbow + black
;         13-           RAINBOW   27-             Eos B
;
; KEYWORD PARAMETERS:
;     BOT    - The starting index of the color map.
;     RED    - The array of red indices
;     GREEN  - The array of green indices
;     BLUE   - The array of blue indices
;     CANCEL - Set on return if there is a problem
;
; OUTPUTS:
;     None
;
; OPTIONAL OUTPUTS:
;     None
;
; COMMON BLOCKS:
;     None
;
; SIDE EFFECTS:
;     Overwrites the existing color table
;
; RESTRICTIONS:
;     None
;
; PROCEDURE:
;     Loads a color table and a personal table for plotting colors.
;
;     0 : black           
;     1 : white           
;     2 : red             
;     3 : green           
;     4 : blue            
;     5 : yellow          
;     6 : magenta         
;     7 : cyan
;     8 : lightred
;     9 : lightgreen
;    10 : lightblue
;
; EXAMPLE:
;     
; MODIFICATION HISTORY:
;     2000-05-05 - Written by M. Cushing, Institute for Astronomy, UH
;                  (I believe I got it from someone else but cannot
;                  remember from who.)
;-
pro mkct,cm,BOT=bot,RED=red,GREEN=green,BLUE=blue,CANCEL=cancel

cancel = 0

if n_params() eq 1 then begin

    cancel = cpar('mkct',cm,1,'Cm',[2,3,4,5],0)
    if cancel then return

endif
if !d.name eq 'X' then device, DECOMPOSED=0,TRUE_COLOR=24

red  =[  0,255,255,  0,  0,255,255,  0,255,127,127,50 ]
green=[  0,255,  0,255,  0,255,  0,255,127,255,127,50 ]
blue =[  0,255,  0,  0,255,  0,255,255,127,127,255,50 ]

tvlct, red, green, blue

if n_params() eq 0 then cm = 0
loadct, cm, BOTTOM=n_elements(red), /SILENT

bot = n_elements(red)

tvlct,red,green,blue,bot,/GET

end




