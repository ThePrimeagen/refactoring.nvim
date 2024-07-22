class Extract
{

public static void foo(int a, int test, int test_other) {
        for (int x = 0; x < test_other + test; x++)
        {
            Console.WriteLine(x + " " + a);
        }
}


    public static void simpleFunction(int a)
    {
        int test = 1,
            test_other = 11;
            foo(a, test, test_other);
    }
}
