export const Button: React.FC = () => {
    const answer = 42;
    const count = 42;
    const foo = () => 42;
    return (
        <button>
            <div>Cool button</div>
            <div>{answer + count}</div>
            <span>{answer}</span>
            <span>{foo()}</span>
            <span>Some content</span>
            <span>Some other content</span>
        </button>
    );
};
