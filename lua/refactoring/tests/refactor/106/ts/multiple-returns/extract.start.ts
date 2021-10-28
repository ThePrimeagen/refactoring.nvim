function multiple_returns(a: number) {
    let test = 1;
    let test_other = 11
    for (let idx = test - 1; idx < test_other; ++idx) {
        console.log(idx, a)
    }

    return {test, test_other};
}
