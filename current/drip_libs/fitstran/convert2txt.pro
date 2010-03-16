pro convert2txt,infile

; Converts from spfits to .txt (ASCII) format
; spectrum sort by increasing wavelength
;
; Nov. 2006 Created (S. Shah)

path='/home/keller/papers/pahaebe/paper2/sloan_redux/haebespec/fits/'
a=readfits(infile)
idx=sort(a[0,*])
b=a[*,idx]
openw,1,infile+'.txt'
printf,1,b[0:2,*]
close,/all
end

