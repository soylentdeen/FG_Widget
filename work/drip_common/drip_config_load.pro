; NAME:
;     DRIP_CONFIG_LOAD - Version 1.1
;
; PURPOSE:
;     Load drip configuration and put it into common block
;     WARNING: this command overwrites previously stored configuration
;
; CALLING SEQUENCE:
;     DRIP_CONFIG_LOAD,/PROMPT
;
; INPUTS:
;     CONFFILENAME - variable to specify a particular configuration
;                    file (dripconf.txt in current folder is standart)
;     PROMPT - asks user for filename if dripconf.txt not found in
;              current directory
;
; OUTPUTS:
;
; CALLED ROUTINES AND OBJECTS:
;
; SIDE EFFECTS:
;     None
;
; MODIFICATION HISTORY:
;     Written by:  Marc Berthoud, Cornell University, 2007-9
;     Modifed: Marc Berthoud, Cornell University, 2010-3
;              Added conffilename parameter
;               ==>> Now Version 1.1
;

;****************************************************************************
;     DRIP_CONFIG_LOAD - load it
;****************************************************************************
pro drip_config_load, conffilename=conffilename, prompt=prompt
; search for drip configuration file -> conffilename
cd,'.',current=currdir
if keyword_set(conffilename) then begin
    cfnsize=size(conffilename)
    if total(size(conffilename) eq [0,7,1]) lt 3 then begin
        conffilename=''
    endif else if (size(findfile(conffilename)))[0] eq 1 then begin
        ; conffilename is valid
    endif else if (size(findfile(currdir+path_sep()+conffilename)))[0] eq 1 $
      then begin
        ; conffilename requires current path
        conffilename=currdir+path_sep()+conffilename
    endif else begin
        ; did not find valid conffilename -> setting to ''
        conffilename=''
    endelse
endif else begin
    if (size(findfile(currdir+path_sep()+'dripconf.txt')))[0] eq 1 then begin
        ; valie dripconf.txt was found in current folder
        conffilename=currdir+path_sep()+'dripconf.txt'
    endif else conffilename=''
endelse
; if no valid file was found, prompt if set
if strlen(conffilename) eq 0 then begin
    if keyword_set(prompt) then conffilename= $
      dialog_pickfile(/must_exist,/read,title='Load DRIP Conf File:')
endif
print,'ConfFileName=',conffilename
; initialize config_info (save filename in config[0])
common drip_config_info, dripconf, drip_errproc
dripconf=[conffilename]
; read configuration file -> config (array of strings)
if strlen(conffilename) gt 0 then begin
    ; read the file
    openr,fileunit,conffilename,/get_lun
    s=''
    while not eof(fileunit) do begin
        readf,fileunit,s
        dripconf=[dripconf,s]
    endwhile
    close,fileunit
    free_lun,fileunit
;** if not found: print warning, load standart configuration file
endif else begin
    ; print warning
    print,'WARNING: MISSING DRIP CONFIGURATION FILE!!!'
    print,'         drip_config_load could not find DRIP configuration file'
    print,'         Program is now loading default configuration'
    print,'         Some parts of the DRIP may not work.'
    print,'    To fix this do either of the following:'
    print,'      **  before using the DRIP run the command'
    print,'            drip_config_load,/prompt'
    print,'          and select a valid drip configuration file'
    print,'      **  download your valid "dripconf.txt" file to the'
    print,'          current directory which is'
    print,'          ',currdir
    ; load standart configuration
    ; admin keywords
    dripconf=[dripconf, 'instmode=instmode', 'obs_id=obs_id']
    ; aux files
    dripconf=[dripconf,'badfile=badfile', 'flatfile=flatfile', $
              'darkfile=darkfile']
    ; sky geometry
    dripconf=[dripconf,'sky_angl=sky_anlg','telra=telra','teldec=teldec']
    ; operations table keywords
    dripconf=[dripconf,'otmode=otmode','otstacks=otstacks','otnbufs=otnbufs']
    ; choping keywords
    dripconf=[dripconf,'chpamp=chpamp','chpangle=chpangle', $
              'chpnpos=chpnpos']
    dripconf=[dripconf,'chpang0=chpang0','chpamp0=chpamp0', $
              'chpang1=chpang1','chpamp1=chpamp1', $
              'chpang2=chpang2','chpamp2=chpamp2', $
              'chpang3=chpang3','chpamp3=chpamp3', $
              'chpang4=chpang4','chpamp4=chpamp4', $
              'chpang5=chpang5','chpamp5=chpamp5', $
              'chpang6=chpang6','chpamp6=chpamp6', $
              'chpang7=chpang7','chpamp7=chpamp7', $
              'chpang8=chpang8','chpamp8=chpamp8', $
              'chpang9=chpang9','chpamp9=chpamp9' ]
    ; noding keywords
    dripconf=[dripconf,'nodbeam=nodbeam','nodraas=nodraas', $
              'noddecas=noddecas']
    ; maping
    dripconf=[dripconf,'mapnxpos=mapnxpos','mapnypos=mapnypos', $
              'mapposx=mapposx','mapposy=mapposy', $
              'mapintx=mapintx','mapinty=mapinty']
    ; testmode keywords
    dripconf=[dripconf,'testmrge=testmrge','testcadd=testcadd']
endelse
end
