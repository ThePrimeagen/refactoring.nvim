def my_decorator():
    pass

@my_decorator
@my_decorator
@my_decorator
def fun():
    dummy_assignment = None

    for i in range(10):
        dont_do_much += i

    return dont_do_much
