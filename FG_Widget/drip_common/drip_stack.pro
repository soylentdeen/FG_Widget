; NAME:
;     DRIP_STACK - Version .7.0
;
; PURPOSE:
;     Add raw frames
;
; CALLING SEQUENCE:
;     STACKED=DRIP_STACK(DATA, HEADER, POSDATA=POSDATA,
;             CHOPSUB=CHOPSUB, NODSUB=NODSUB)
;
; INPUTS:
;     DATA - Data to be stacked i.e. stacks in drip
;     HEADER - The fits header of the new input data file
;     POSDATA - Frames for each sky position
;     CHOPSUB - Chop subtracted frames
;     NODSUB
;
; OUTPUTS:
;     STACKED - The stacked image
;               i.e. stacks added to chop positions and nod positions added
;               to 1 stacked frame, first frame will always be positive
;
; SIDE EFFECTS:
;     None.
;
; RESTRICTIONS:
;     None.
;
; PROCEDURE:
;     add each frame of the data to a 2-d summation frame,
;     in a manner appropriate to the current reduction scheme,
;     then average by the number of frames
;
; MODIFICATION HISTORY:
;   Written by:  Marc Berthoud, Cornell University October 2007
;                Most code taken from drip_merge 6.1
;                (see drip_merge.pro header for earlier changes)

;******************************************************************************
;     DRIP_STACK - Stacks data frames
;******************************************************************************

function drip_stack, data, header, posdata=pdata, chopsub=chsub, nodsub=ndsub

; error check
s=size(data)
if s[0] ne 3 then begin
    drip_message, 'drip_stack - Must provide valid new data array',/fatal
    return, data
endif
hs=size(header)
if (hs[0] ne 1) or (hs[2] ne 7) then drip_message, $
  'drip_stack - invalid header'
;**** add frames
; init variables (OTMODE number of stacks, number of frames)
;      assume #positions = #frames / #stacks
otmode=drip_getpar(header,'OTMODE')
Nstacks=fix(drip_getpar(header,'OTSTACKS'))
Nbufs=fix(drip_getpar(header,'OTNBUFS'))
Nframes=s[3]
; add frames according to Ops Table MODE
switch otmode of
    ; 1: begin
    'AD': begin ; AD=All Destructive
        ; get number of positions
        Npos=fix(floor(float(Nframes)/float(Nstacks)+0.01))
        ;print,'Npos=',Npos
        if (Nframes mod Nstacks) gt 0 then drip_message, $
          ['drip_merge - adding stacks - AD -', $
           '  number of frames is not multiple of number of stacks',$
           '  ignoring last frames']
        if Nstacks gt 1 then begin
            ; make data for positions
            posdata=fltarr(s[1],s[2],Npos)
            ; average all positions
            for pos=0,Npos-1 do begin
                posdata[*,*,pos]= $
                  total(data[*,*,(pos*Nstacks):((pos+1)*Nstacks-1)],3)
            endfor        
        endif else begin
          posdata=data
          ;print,size(posdata)
        endelse
        break
    end
endswitch
; return posdata if it's requested
if keyword_set(pdata) then pdata=posdata
;**** stack
; initialize variables
s=size(posdata)
stacked=fltarr(s[1],s[2])
mode=drip_getpar(header,'INSTMODE')
mode=strtrim(mode,2)
; run appropriate method
switch mode of
    'C2':
    'NAS': ;Grism Nod along slit
    'NOS': ;Grism Nod along slit
    'C2NC2': begin ; 2 position chop
        ; get differences
        chopsub=fltarr(s[1],s[2],s[3]/2)
        for i=0,s[3]-1,2 do begin
            chopsub[*,*,i/2]=posdata[*,*,i]-posdata[*,*,i+1]
        endfor
        ; stack
        if size(chopsub,/n_dimensions) gt 2 then stacked=total(chopsub,3) $
          else stacked=chopsub
        if keyword_set(chsub) then chsub=chopsub
        break
    end
    'C2N': ; 2 position chop with nod
    'C2ND': ; 2 position chop with nod and dither
    'MAP': begin ; MAPping Mode
       ;check data
       if s[3] mod 4 ne 0 then drip_message, $
         ['drip_stack - adding images - nodchop -', $
          '  invalid number of data frames - ignoring last images']
       ;** add frames
       ; add two nod cyles independently
       chopsub=fltarr(s[1],s[2],s[3]/2)
       nodsub=fltarr(s[1],s[2],s[3]/4)
       for i=0,s(3)-1,4 do begin
           chopsub[*,*,i/2]=posdata[*,*,i]-posdata[*,*,i+1]
           chopsub[*,*,i/2+1]=posdata[*,*,i+2]-posdata[*,*,i+3]
           nodsub[*,*,i/4]=chopsub[*,*,i/2]-chopsub[*,*,i/2+1]
       endfor
       if keyword_set(chsub) then chsub=chopsub
       ; add nod cycles
       if size(nodsub,/n_dimensions) gt 2 then stacked=total(nodsub,3) $
         else stacked=nodsub
       if keyword_set(ndsub) then ndsub=nodsub
       break
   end
   'C3D': begin ; 3 position chop with dither
       ; add frames
       stacked=posdata[*,*,0]-posdata[*,*,1]-posdata[*,*,2]
       if keyword_set(chsub) then chsub=stacked
       break
   end
   'CM':begin ; multi positon chop
      chopnum=fix(drip_getpar(header,'CHPNPOS'))
      if s[3] ne chopnum then drip_message, $
         ['drip_stack - adding images - chop multi -', $
          '  number of images doesn''t mach number of chop positions', $
          '  ignoring last frames']
      ; perform shifts and additions
      stacked=posdata[*,*,0]
      for i=1,chopnum-1 do begin
          stacked-=posdata[*,*,i]
      endfor
      if keyword_set(chsub) then chsub=stacked
      break
  end
  'STARE':begin ; STARE
      if s[0] eq 3 then stacked=median(posdata,dimension=3) $
         else stacked=posdata
      break
  end
  'TEST':begin ; TEST
      ;xoff=drip_getpar(header,'TESTXOFF')
      ;yoff=drip_getpar(header,'TESTYOFF')
      submode=strtrim(drip_getpar(header,'TESTMRGE'),2)
      switch submode of
          'MED': begin
              if s[0] eq 3 then $
                stacked=median(posdata,dimension=3) $
                else stacked=posdata
              break
          end
          'ADD': begin
              if s[0] eq 3 then $
                stacked=total(posdata,3) $
                else stacked=posdata
              break
          end
          'SUB': begin
              stacked=fltarr(s[1],s[2])
              sign=1.0
              for i=0,s[3]-1 do begin
                  stacked=stacked+sign*posdata[*,*,i]
                  sign=sign*(-1.0)
              endfor
              break
          end
          'CHOP': begin
              ; get differences
              chopsub=fltarr(s[1],s[2],s[3]/2)
              for i=0,s[3]-1,2 do begin
                  chopsub[*,*,i/2]=posdata[*,*,i]-posdata[*,*,i+1]
              endfor
              ; stack
              if size(chopsub,/n_dimensions) gt 2 then $
                stacked=total(chopsub,3) $
                else stacked=chopsub
              if keyword_set(chsub) then chsub=chopsub
              break
          end
          'CHOP-': begin
              ; get differences
              chopsub=fltarr(s[1],s[2],s[3]/2)
              sign=1.0
              for i=0,s[3]-1,2 do begin
                  chopsub[*,*,i/2]=posdata[*,*,i]-posdata[*,*,i+1]
                  chopsub[*,*,i/2]*=sign
              endfor
              ; stack
              if size(chopsub,/n_dimensions) gt 2 then $
                stacked=total(chopsub,3) $
                else stacked=chopsub
              if keyword_set(chsub) then chsub=chopsub
              break
          end
          else: if (size(posdata))[0] eq 3 then $
            stacked=median(posdata,dimension=3) $
            else stacked=posdata
      endswitch
      break
  end
  else:begin
      drip_message, 'drip_merge - invalid instrument mode - returning images'
      stacked=posdata
  endelse
endswitch

; Now clean up "jailbar" array pattern noise
stacked = drip_jbclean(stacked,header)

;atv22,stacked

; Convert pixel data to mega-electrons per second

frmrate = drip_getpar(header,'FRMRATE')  ; get frame rate (Hz) from header
eperadu = drip_getpar(header,'EPERADU')  ; get electrons/adu from header

stacked = stacked*frmrate*eperadu/1e6    ; convert to millions of e/s

;Remove third dimension from header

return, stacked

end
