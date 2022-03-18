
//-------------------------------------------------------------------
//-------------------------------------------------------------------

void ddd();
void aaa(){
  int i;
  int j=0;
  int k=0;

  for(i=0;i<500;i++){
    j = j+i;
    k = k+j+i;
    asm volatile ("nop");
  }
  asm volatile ("nop");
  return ;
}

void notmain() {
  ddd();
  aaa();
  while(1) {
    aaa();
  }
}
