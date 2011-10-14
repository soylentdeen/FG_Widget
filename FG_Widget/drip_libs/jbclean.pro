function jbclean,in

jailbar=in
index=indgen(256/16)*16  ;index every 16th pixel in a row
for k=0,255 do begin
        for j=0,15 do begin
            jailbar(index+j,k)=median(jailbar(index+j,k))
        endfor
endfor
jbcleaned = in-jailbar
out = jbcleaned
return, out
end