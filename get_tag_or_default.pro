FUNCTION GET_TAG_OR_DEFAULT, struct, name, default
  tag_names = TAG_NAMES(struct)
  
  index = WHERE(STRCMP(tag_names, STRUPCASE(name)) EQ 1, count)
  IF count EQ 1 THEN BEGIN
    return, struct.(index)
  ENDIF ELSE BEGIN
    return, default
  ENDELSE
  
END