class Extract
{
    public static void simpleFunction(int a)
    {
        int test = 1,
            test_other = 11;
        for (int x = 0; x < test_other + test; x++)
        {
            Console.WriteLine(x + " " + a);
            // __AUTO_GENERATED_PRINTF_START__
            Console.WriteLine(@"Extract#simpleFunction#for 1"); // __AUTO_GENERATED_PRINTF_END__
        }
    }
}
