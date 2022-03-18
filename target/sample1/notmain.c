void debug_me(){
  int i;
  int j=0;
  int k=0;

  for(i=0;i<500;i++){
    j = j+i;
    k = k+j+i;
  }
  return ;
}

void notmain() {
  debug_me();
  while(1) {
    debug_me();
  }
}
