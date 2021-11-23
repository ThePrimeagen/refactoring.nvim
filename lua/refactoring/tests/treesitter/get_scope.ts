class Test {
    private test: number = 0;

    constructor() {
        "This is a method Definition"
    }
}

const stupidWayToSpecifyAFunction = () => {
    function outerFunction() {
        class Test {
            private test: number = 0;

            constructor() {
                "This is a method Definition"
            }
        }
    }
}

function top_level_function(): number {
    const test = 5;
    return test;
}

() => {
    "This is an arrow function";
    return 5;
}

function local_var_test() {
    let foo = 5;
    const bar = 5;

    function inner() {
        let baz = 5;
        return 5;
        if (true) {
            let fazz = 7;
        }

        if (true) {
            let buzzzbaszz = 69;
        }
    }

    return inner() * foo * bar;
}

