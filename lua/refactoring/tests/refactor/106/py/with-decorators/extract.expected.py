def my_decorator():
    pass

def extracted_fun():
    for i in range(10):
        dont_do_much += i


@my_decorator
@my_decorator
@my_decorator
def fun():
    dummy_assignment = None

    extracted_fun()

    return dont_do_much
