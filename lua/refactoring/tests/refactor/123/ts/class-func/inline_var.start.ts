class TestClass {
    private items: number[] = [];

    function1(item: number): void {
        this.items.push(item);
    }

    function2(): number {
        const item = 42;
        const thing2 = item - this.items[0];
        return thing2;
    }
}
