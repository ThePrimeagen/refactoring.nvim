namespace Test
{
    class Extract
    {
        public static int simpleFunction(int a)
        {
            int test = 1;
            int test_other = 1;

            for (int i = 0; i < test_other; i++) {
              Console.WriteLine("{0} {1}", a, test_other);
            }

            return test;
        }
    }
}

