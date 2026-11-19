struct Calculator {
    tax_rate: f64,
}

impl Calculator {
    fn total(&self, prices: &[f64], discount: f64) -> f64 {
        let subtotal: f64 = prices.iter().sum();
        let mut count = 0;

        let tax = subtotal * self.tax_rate - discount;
        count += 1;
        println!("Subtotal: {}", subtotal);

        let result = subtotal + tax;
        println!("{}", count);
        result
    }
}

fn main() {
    let calculator = Calculator { tax_rate: 0.2 };
    println!("{}", calculator.total(&[1.0, 2.0], 0.5));
}
