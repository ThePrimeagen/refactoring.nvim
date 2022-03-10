class TestClass {
    private items: number[] = [];

    function1(item: number): void {
        this.items.push(item);
    }

    function2(): number {
        
        const thing2 = 42 - this.items[0];
        return thing2;
    }
}
