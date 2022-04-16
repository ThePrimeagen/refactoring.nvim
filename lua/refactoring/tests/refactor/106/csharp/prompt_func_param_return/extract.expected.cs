namespace Test
{
    class Extract
    {
        public static int foo(int a) {
            Console.WriteLine("this is a test");
            int test = 1;
            Console.WriteLine(a);
            return test;
        }

        public static int simpleFunction(int a) {
            var test = foo(a);

            Console.WriteLine(test);

            return test;
        }
    }
}

