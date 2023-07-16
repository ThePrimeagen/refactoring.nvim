
function return_me(a: number, test) {
    let test_other = 11
    for (let idx = test - 1; idx < test_other; ++idx) {
        console.log(idx, a)
    }

    return test_other;
}

function single_return(a: number) {
    let test = 1;
    const test_other = return_me(a, test);


    return {test, test_other};
}
