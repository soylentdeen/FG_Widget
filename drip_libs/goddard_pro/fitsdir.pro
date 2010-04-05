pro fitsdir ,directory, TEXTOUT = textout,NoTelescope = NoTelescope
;+
; NAME:
;     FITSDIR 
; PURPOSE:
;     Provide a brief description of the primary headers of FITS disk files.  
; EXPLANATION:
;     The values of the FITS keywords NAXISi, OBS-DATE (or TDATEOBS or DATE),
;     TELESCOPE (or INSTRUME), OBJECT (or TARGNAME), EXPTIME (and INTEG) are
;     displayed.    All of these are commonly used FITS keywords
;     and all except EXPTIME are officially reserved FITS keywords.
;     Keyword names in parentheses are searched if the primary keyword is not
;     found.
;
; CALLING SEQUENCE:
;     FITSDIR , [ directory, TEXTOUT =, /NoTelescope ] 
;
; OPTIONAL INPUT PARAMETERS:
;     DIRECTORY - Scalar string giving file name, disk or directory to be 
;             searched.   Wildcard file names are allowed.    Examples of 
;             valid VMS or Unix names include '*.fit' or 'tape*'.    An 
;             example of a valid VMS name is  'UIT$USER2:[JONES]*.FIT' while
;                a valid Unix string is 'iraf/*.fits'.
;
;             If not given, FITSDIR searches *.fits files in the default 
;             directory.
;
; OPTIONAL KEYWORD INPUT PARAMETER
;     /NOTELESCOPE - If this keyword is set and non-zero then the value of 
;               the (usually less important) TELESCOPE keyword is not 
;               displayed, and more space is available to display the other 
;               keyword values
;                                                                    
;      TEXTOUT - Controls output device as described in TEXTOPEN procedure
;               textout=1       TERMINAL using /more option
;               textout=2       TERMINAL without /more option
;               textout=3       <program>.prt
;               textout=4       laser.tmp
;               textout=5       user must open file
;               textout=7       Append to existing <program>.prt file
;               textout = filename (default extension of .prt)
;
; OUTPUT PARAMETERS:
;       None.
;
; RESTRICTIONS:
;       (1) Field values may be truncated if their length exceeds the default
;               format.
;
;       File name    NAXISi    OBS-DATE    TELESCOPE    OBJECT    EXPTIME
;               A18           A11       A10          A10        A20        F7.1
;               A20           A12       A10                     A29        F7.1
;
;       (2)   Only reads the primary FITS headers.    FITS files containing
;               only extensions (binary or ASCII tables) may have little
;               information in their primary header.    
;
;       (3)   Users may wish to modify the program to display other FITS 
;               keywords of particular interest to them
; EXAMPLES:  
;       IDL> fitsdir          ;Print info on all '*.fits' files in current 
;                               directory.     
;       IDL> fitsdir ,'*.fit'   ;Lists all '*.fit' files in current directory 
;       IDL> fitsdir ,'tape*'   ;Print info on all tape* files in current 
;                               ;directory.    Files meeting the wildcard name
;                               ;that are not FITS files are ignored
;
;       Write info on all *.fits files in the Unix directory /usr2/smith, to a 
;       file 'smith.txt' and don't display the value of the TELESCOPE keyword
;
;       IDL> fitsdir ,'/usr2/smith/*.fits',t='smith.txt', /NoTel 
;
; PROCEDURE:
;       FINDFILE is used to find the specified FITS files.   The header of
;       each file is read, and rejected if the file is not FITS.    Each header 
;       searched for the parameters NAXISi, TELESCOP, OBJECT, DATE-OBS and 
;       EXPTIME.  
;
; SYSTEM VARIABLES:
;       The non-standard system variables !TEXTOUT and !TEXTUNIT must be 
;       defined before calling FITS_INFO.   
;
;       DEFSYSV,'!TEXTOUT',1
;       DEFSYSV,'!TEXTUNIT',0
;
;       One way to define these is to call the procedure ASTROLIB.   
;       See TEXTOPEN.PRO for more info
; PROCEDURES USED:
;       FDECOMP, REMCHAR,  SPEC_DIR(), TEXTOPEN, TEXTCLOSE, ZPARCHECK
; MODIFICATION HISTORY:
;       Written, W. Landsman,  HSTX    February, 1993
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Search alternate keyword names    W.Landsman    October 1998
;-
 On_error,2

 if N_params() GT 0 then $
     zparcheck, 'FITSDIR ', directory, 1, 7, 0, 'Directory Name' $
 else directory = '*.fits'

 fdecomp, directory, disk, dir, filename, ext
 if filename EQ '' then begin 
      directory = disk + dir + '*.fits'
      filename = '*'
      ext = 'fits'
 endif else if !VERSION.OS_FAMILY EQ 'unix' then begin
        if (strpos(filename,'*') LT 0) and (ext EQ '') then begin  
        directory = disk + dir + filename + '/*.fits'
        filename = '*'
        ext = 'fits'
        endif
 endif

 if keyword_set(NoTelescope) then begin 
          namelen = 20
          objectlen = 29 
 endif else begin 
          namelen = 18
          objectlen = 20
 endelse

 direct = spec_dir(directory)
 files = findfile( direct, COUNT = n)
 if n EQ 0 then begin                                      ;Any files found?
       message,'No files found on '+ direct, /CON
       return
 endif 

  good = where( strlen(files) GT 0, Ngood)
  if Ngood EQ 0 then message,'No FITS files found on '+ direct $
                 else files = files[good]

; Set output device according to keyword TEXTOUT or system variable !TEXTOUT

 if not keyword_set( TEXTOUT ) then textout= !TEXTOUT

 dir = 'dummy'
 num = 0

 get_lun,unit

 fmt1 = '(a,t20,a,t31,a,t42,a,t52,a,t71,a)'
 fmt2 = '(a,t22,a,t34,a,t45,a,t73,a)

 for i = 0,n-1 do begin                           ;Loop over each .hhh file

   fdecomp, files[i], disk, dir2, fname, qual     ;Decompose into disk+filename
   openr,unit,files[i], /BLOCK                    ;Open the header

   hdr = assoc(unit, bytarr(80,36) )              ;Read 36 lines at a time

   r = 0                                          ;# of 36 line groups read
LOOP:

   fstat = fstat(unit)
   if fstat.size LT 2880*(r+1) then begin       ;FITS files at least 2880 bytes
      print,files[i],' is not a FITS file'
      goto, BADHD
   endif

   x = string( hdr[r] )
   if r EQ 0 then begin 
      h = x
      if strmid( h[0],0,8 ) NE 'SIMPLE  ' then begin
         print,files[i],' is not a FITS file'
         goto, BADHD
      endif
   endif else h = [ h, x ]

   name = strmid( x, 0, 8 )            ;Get first 8 char of each line
   pos = where( name EQ 'END     ',NEnd )
   if ( NEnd EQ 0) then begin
       r = r + 1
       goto, LOOP 
  endif 

 lastline = 36*r + pos[0] 
 h = h[0:lastline]

 keyword = strtrim( strmid(h,0,8),2 )          ;First 8 chars is FITS keyword
 value = strtrim( strmid(h,10,20),2 )          ;Chars 10-30 is FITS value

 l= where(keyword EQ 'NAXIS',Nfound)            ;Must have NAXIS keyword
    if Nfound GT 0 then naxis  = fix( value[ l[0] ] ) else goto, BADHD

 if naxis EQ 0 then naxisi = '0' else begin

 l = where( keyword EQ 'NAXIS1', Nfound)         ;Must have NAXIS1 keyword
    if Nfound gt 0 then naxis1  = fix( value[l[0] ] ) else goto, BADHD 
    naxisi = strtrim( naxis1,2 )
 endelse

 if NAXIS GE 2 then begin
 l = where(keyword EQ 'NAXIS2', Nfound)          ;Must have NAXIS2 keyword
    if Nfound gt 0 then naxis2  = fix(value[l[0]]) else goto, BADHD
    naxisi = naxisi + ' ' + strtrim( naxis2, 2 )
 endif

 if NAXIS GE 3 then begin
 l = where( keyword EQ 'NAXIS3', Nfound )          ;Must have NAXIS2 keyword
    if Nfound GT 0 then naxis3  = fix( value[l[0]] ) else goto, BADHD
    naxisi = naxisi + ' ' + strtrim( naxis3, 2 )
 endif

 if not keyword_set(NoTelescope) then begin
 l= where(keyword EQ 'TELESCOP',Nfound)         ;Search for TELESCOP keyword
 if Nfound EQ 0 then l = where(keyword EQ 'INSTRUME',Nfound)
    if Nfound GT 0 then begin 
          telescop = value[l[0]] 
          remchar,telescop,"'"
    endif else  telescop = '   ?      ' 
 endif

 l = where(keyword eq 'EXPTIME', Nfound)           ;Search for EXPTIME keyword
 if Nfound EQ 0 then l = where(keyword EQ 'INTEG',Nfound)
    if Nfound GT 0 then begin 
       exptim = float(value[l[0]]) 
       if  exptim EQ 0. then exptim = '    ? ' else $ 
                      exptim = string(exptim, f = '(f7.1)')
    endif else exptim ='    ? '

 l = where(keyword EQ 'OBJECT',Nfound)            ;Search for OBJECT keyword
 if Nfound EQ 0 then l = where(keyword EQ 'TARGNAME',Nfound)
    if Nfound GT 0 then begin 
       object = strtrim(strmid(h[l],10,30),2)
       remchar,object,"'"
   endif else object = '  ?     '

 l = where(keyword EQ 'DATE-OBS', Nfound)         ;Search for DATE-OBS keyword
 if Nfound EQ 0 then l = where(keyword EQ 'TDATEOBS', Nfound)
 if Nfound EQ 0 then l = where(keyword EQ 'DATE', Nfound) 
   if Nfound GT 0 then begin 
       obs = value[l[0]] 
       remchar, obs, "'"
       obs = strtrim(obs,2)
   endif else obs = '  ?     '


 num = num + 1
 if num EQ 1 then begin                 ;Print output header

    textopen, 'fitsdir', TEXTOUT=textout  
    printf,!TEXTUNIT, f = '(a,/)', 'FITS File Directory ' + systime()
    if keyword_set(NoTelescope) then printf, !TEXTUNIT, $              
' NAME                 SIZE      DATE-OBS            OBJECT            EXPTIM' $
    else printf,!TEXTUNIT, $
 ' NAME                SIZE     DATE-OBS   TELESCOP  OBJECT             EXPTIM' 
endif

 if dir2 NE dir then begin                  ;Has directory changed?   
       if disk+dir2 EQ '' then cd,current=dir else dir = dir2
       printf, !TEXTUNIT,format='(/a/)', disk + dir + filename+'.'+ext  
       dir = dir2                                  ;Save new directory
 endif                   

 fname = strmid( fname, 0, namelen ) 
 object = strmid( object, 0, objectlen )


  if keyword_set( NOTELESCOPE) then $ 
  printf,!textunit,f=fmt2, $
      fname, naxisi, obs, object, exptim  else  $
  printf,!textunit,f=fmt1, $
      fname, naxisi, obs, telescop, object, exptim 

 if textout EQ 1 then if !ERR EQ 1 then goto, DONE
 BADHD:  

 close,unit
 endfor
 DONE: 
 if num GT 0 then textclose, TEXTOUT=textout else begin 
           message,'No valid FITS files found on '+ spec_dir(direct),/CON
           return
 endelse 

 return      ;Normal return   
 end
