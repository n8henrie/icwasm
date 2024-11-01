use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern "C" {
    fn alert(s: &str);
}

#[wasm_bindgen]
pub fn greet() {
    alert("Hello, icwasm!");
}

#[allow(dead_code)]
fn random_number() -> i32 {
    42
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn a_test() {
        assert_eq!(random_number(), 42);
    }
}
