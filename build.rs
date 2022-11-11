fn main() {
    println!("cargo:rerun-if-changed=./src/lib.udl");
    uniffi_build::generate_scaffolding("./src/lib.udl").unwrap();
}
