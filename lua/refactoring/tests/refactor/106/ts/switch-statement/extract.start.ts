function test() {
    const foo = {
        foo: 5,
        bar: 3,
        bazz: 9,
    };

    let total = 0;
    for (let key of foo) {
        let localAmount = 0;
        switch (key) {
        case "foo":
            localAmount += 500;
            break;
        case "bar":
            localAmount += 700 * foo[key];
            break;
        case "bazz":
            localAmount += Math.max(900 - foo[key] * 69, 420);
            break;
        }

        total += localAmount;
    }

    return total
}
