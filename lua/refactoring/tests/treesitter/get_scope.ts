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

