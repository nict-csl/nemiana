//-------------------------------------------------------------------
//-------------------------------------------------------------------

void set_csr(void*);
void machine_mode(void);
void test_main(void);

void notmain() {
  int *xxx = (int*)machine_mode;
  set_csr(xxx);
  test_main();
}
