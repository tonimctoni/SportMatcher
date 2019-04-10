#![allow(dead_code)]

pub const LOWER_ALPHA_CHARS: &str = "abcdefghijklmnopqrstuvwxyz";
pub const LOWER_ALPHA_SPACE_CHARS: &str = "abcdefghijklmnopqrstuvwxyz ";
pub const LOWER_ALPHANUMERIC_CHARS: &str = "abcdefghijklmnopqrstuvwxyz0123456789";
pub const LOWER_ALPHANUMERIC_SYMBOLS_CHARS: &str = "abcdefghijklmnopqrstuvwxyz0123456789!? ,;.:-_()[]{}&%$'";


pub fn contains_only(s: &str, chars: &str) -> bool{
    s.chars().all(|c| chars.chars().any(|ac| ac==c))
}