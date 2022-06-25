namespace Test
{
    class Extract
    {
        public static int foo()
        {
            Console.WriteLine("this is a test");
            int test = 1;
            return test;
        }


        public static int simpleFunction(int a)
        {
            var test = foo();

            Console.WriteLine(test);

            return test;
        }
    }
}

