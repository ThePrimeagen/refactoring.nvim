
def foo_bar(a, b: int, c, d: int, test, test_other):
    for x in range(test_other + test):
        print(x, a, b, c, d)

def simple_function(a, b: int, c=1, d: int = 2):
    test = 1
    test_other = 11
    foo_bar(a, b, c, d, test, test_other)
