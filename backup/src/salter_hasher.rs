#![allow(dead_code)]


use sha2::{Sha512, Digest};
use rand;
use rand::Rng;
// use rand::distributions::Alphanumeric;

pub struct SalterHasher {
    rng: rand::ThreadRng
}

impl SalterHasher {
    pub fn new() -> SalterHasher{
        SalterHasher{rng: rand::thread_rng()}
    }

    pub fn just_hash(password: &str, salt: &str) -> String{
        // Guide says "don't do it this way", but it is not the boss of me.
        let mut hasher=Sha512::new();
        hasher.input(password.as_bytes());
        hasher.input("<$>".as_bytes());
        hasher.input(salt.as_bytes());
        hasher.result().as_slice().iter().fold(String::with_capacity(2*512/8), |mut acc, byte| {acc.push_str(&format!("{:X}", byte));acc})
    }

    pub fn salt_and_hash(&mut self, password: &str) -> (String, String){
        // let salt=(0..10).map(|_| self.rng.sample(Alphanumeric)).collect();
        let salt=self.rng.gen_ascii_chars().take(10).collect::<String>();
        let h=Self::just_hash(&password, salt.as_str());

        (salt, h)
    }
}