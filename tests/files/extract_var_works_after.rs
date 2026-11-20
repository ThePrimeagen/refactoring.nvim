fn show(s: &str) {
    println!("{}", s);
}

fn main() {

    let foo = "foo";
    show(foo);

    while true {
        show(foo);
        break;
    }

    loop {
        show(foo);
        break;
    }

    if true {
        show(foo);
    } else {
        show(foo);
    }

    for _i in 0..5 {
        show(foo);
    }

    let a = 1;
    match a {
        1 => {
            show(foo);
        }
        _ => show(foo),
    }

    let f = || show(foo);
    f();
}
