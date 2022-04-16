namespace Test
{
    class Extract
    {
        public static void foo(int a)
        {
            int test_other = 1;

            for (int i = 0; i < test_other; i++) {
                Console.WriteLine("{0} {1}", a, test_other);
            }
        }


        public static int simpleFunction(int a)
        {
            int test = 1;
            foo(a);

            return test;
        }
    }
}

