namespace Test
{
    class Extract
    {
    	public static void simpleFunction(int a)
      	{
        	int test = 1;
			int test_other = 11;
        	for (int x = 0; x < test_other + test; x++) {
          		Console.WriteLine(x + " " + a);
	        }
      	}
    }
}
