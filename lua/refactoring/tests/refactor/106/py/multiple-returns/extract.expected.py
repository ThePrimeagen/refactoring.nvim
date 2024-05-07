
def extracted_func() -> None:
    a = 1
    b = 1
    return a, b

def simple_function():
    a, b = extracted_func()


    print(a)
    print(b)
