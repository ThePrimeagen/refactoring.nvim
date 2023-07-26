class RefuctorPlease {
    return_me(a: number, test: number) {
        let test_other = 11
        for (let idx = test - 1; idx < test_other; ++idx) {
            console.log(idx, a)
        }

        return test_other;
    }

    multiple_returns(a: number) {
        let test: number = 1;
        const test_other = this.return_me(a, test);


        return {test, test_other};
    }
}
