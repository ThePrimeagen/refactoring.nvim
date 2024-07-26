
function foo_bar({answer, count, foo}) {
return (
<>
    <div>Cool button</div>
    <div>{answer + count}</div>
    <span>{answer}</span>
    <span>{foo()}</span>
    <span>Some content</span>
    <span>Some other content</span>
</>
)
}

export const Button: React.FC = () => {
    const answer = 42;
    const count = 42;
    const foo = () => 42;
    return (
        <button>
            < foo_bar answer={answer} count={count} foo={foo}/>
        </button>
    );
};
