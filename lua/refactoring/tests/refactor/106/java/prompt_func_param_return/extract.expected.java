class Extract {

public static int foo(int a) {
        System.out.println("this is a test");
        int test = 1;
        System.out.println(a);
        return test;
}


    public static int simpleFunction(int a) {
        var test = foo(a);

        System.out.println(test);

        return test;
    }
}
