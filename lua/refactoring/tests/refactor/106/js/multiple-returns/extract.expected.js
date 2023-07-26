
function return_me(a) {
    let test = 1;
    let test_other = 11
    for (let idx = test - 1; idx < test_other; ++idx) {
        console.log(idx, a)
    }

    return {test, test_other};
}

function multiple_returns(a) {
    const {test, test_other} = return_me(a);


    return {test, test_other};
}
