
function foo_bar(a) {
    let test = 1;
    let test_other = 11
    for (let idx = test - 1; idx < test_other; ++idx) {
        console.log(idx, a)
    }
}

function simple_function(a) {
    foo_bar(a);
}
