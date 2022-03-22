
function foo_bar(a: number, test, test_other) {
    for (let idx = test - 1; idx < test_other; ++idx) {
        console.log(idx, a)
    }
}


/*
    * This is a comment
    * wow!
*/
function simple_function(a: number) {
    let test = 1;
    let test_other = 11
    foo_bar(a, test, test_other);
}
