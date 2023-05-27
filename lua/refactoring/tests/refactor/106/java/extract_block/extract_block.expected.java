class Extract {

public static void foo_bar(int a) {
    int test = 1, test_other = 11;
    for (int x = 0; x < test_other + test; x++) {
      System.out.println(x + " " + a);
    }
}


  public static void simpleFunction(int a) {
    foo_bar(a);
  }
}
