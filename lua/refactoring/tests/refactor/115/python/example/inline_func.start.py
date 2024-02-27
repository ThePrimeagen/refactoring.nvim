def foo_bar(a, test):
    test_other = 11
    for idx in range(test - 1, test_other):
        print(idx, a)
    return test_other


def simple_function(a):
    test = 1
    test_other = foo_bar(a, test)

    return test, test_other
