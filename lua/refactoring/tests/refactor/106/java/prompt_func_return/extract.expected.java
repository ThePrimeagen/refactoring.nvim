class Extract {

public static int foo() {
        System.out.println("this is a test");
        int test = 1;
        return test;
}


    public static int simpleFunction(int a) {
        var test = foo();

        System.out.println(test);

        return test;
    }
}
