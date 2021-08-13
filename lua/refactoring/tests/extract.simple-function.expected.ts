
function foo_bar(a, test, test_other) {
    for (let idx = test - 1; idx < test_other; ++idx) {
        console.log(idx, a)
    }
    return fill_me
}

function simple_function(a: number) {
    let test = 1;
    let test_other = 11

    const fill_me = foo_bar(a, test, test_other);

}
