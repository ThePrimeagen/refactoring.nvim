namespace Test
{
    class Extract
    {
        public static void simpleFunction(int a)
        {
            var test = 1;
            var test_other = 11;

            for (var x = 0; x < test_other + test; x++) {
                Console.WriteLine(x + " " + a);
            }
        }
    }
}

