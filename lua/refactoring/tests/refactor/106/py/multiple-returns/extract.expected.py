
def extracted_func():
    a = 1
    b = 1
    return a, b


def simple_function():
    a, b = extracted_func()


    print(a)
    print(b)
